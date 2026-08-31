<?php

declare(strict_types=1);

require_once __DIR__ . '/md1200.php';

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

$options = getopt('', ['once', 'dry-run', 'config:', 'disks:', 'state:', 'fixture-dir:']);
$runOnce = array_key_exists('once', $options);
$dryRun = array_key_exists('dry-run', $options);
$configPath = isset($options['config']) ? (string) $options['config'] : WAZ_MD1200_CONFIG;
$disksPath = isset($options['disks']) ? (string) $options['disks'] : '/var/local/emhttp/disks.ini';
$statePath = isset($options['state']) ? (string) $options['state'] : WAZ_MD1200_STATE;
$fixtureDirectory = isset($options['fixture-dir']) ? (string) $options['fixture-dir'] : '';
$running = true;

if (function_exists('pcntl_async_signals') && function_exists('pcntl_signal')) {
    pcntl_async_signals(true);
    pcntl_signal(SIGTERM, static function () use (&$running): void { $running = false; });
    pcntl_signal(SIGINT, static function () use (&$running): void { $running = false; });
}

function waz_md1200_controller_number(array $config, string $key, float $fallback): float
{
    $value = $config[$key] ?? null;
    return is_numeric($value) ? (float) $value : $fallback;
}

function waz_md1200_controller_list(string $value): array
{
    return array_values(array_unique(array_filter(array_map('trim', explode(',', $value)), static fn(string $item): bool => $item !== '')));
}

function waz_md1200_controller_shelves(array $config): array
{
    $result = [];
    foreach (['top' => 'TOP', 'bottom' => 'BOTTOM'] as $id => $prefix) {
        $result[] = [
            'id' => $id,
            'name' => trim((string) ($config['MD1200_' . $prefix . '_NAME'] ?? 'MD1200 ' . ucfirst($id))),
            'port' => trim((string) ($config['MD1200_' . $prefix . '_PORT'] ?? '')),
            'sesDevice' => trim((string) ($config['MD1200_' . $prefix . '_SES_DEVICE'] ?? '')),
            'disks' => waz_md1200_controller_list((string) ($config['MD1200_' . $prefix . '_DISKS'] ?? '')),
        ];
    }
    return $result;
}

function waz_md1200_controller_disks(string $path): array
{
    $values = is_file($path) ? @parse_ini_file($path, true, INI_SCANNER_RAW) : [];
    if (!is_array($values)) return [];
    $result = [];
    foreach ($values as $section => $disk) {
        if (!is_array($disk)) continue;
        $name = trim((string) ($disk['name'] ?? $section));
        $result[strtolower($name)] = $disk;
    }
    return $result;
}

function waz_md1200_controller_spun_down(array $disk): bool
{
    $explicit = strtolower(trim((string) ($disk['spundown'] ?? '')));
    if (in_array($explicit, ['1', 'yes', 'true', 'on'], true)) return true;
    return str_contains(strtolower((string) ($disk['color'] ?? '')), 'blink');
}

function waz_md1200_controller_temperature(array $assigned, array $disks): array
{
    $temperatures = [];
    $active = 0;
    $seen = 0;
    foreach ($assigned as $name) {
        $disk = $disks[strtolower($name)] ?? null;
        if (!is_array($disk)) continue;
        $seen++;
        if (!waz_md1200_controller_spun_down($disk)) $active++;
        $raw = trim((string) ($disk['temp'] ?? ''));
        if (is_numeric($raw) && (float) $raw > 0.0) $temperatures[$name] = (float) $raw;
    }
    arsort($temperatures, SORT_NUMERIC);
    $hottestName = $temperatures ? (string) array_key_first($temperatures) : null;
    return [
        'temperatureC' => $hottestName === null ? null : round((float) $temperatures[$hottestName], 1),
        'temperatureSource' => $hottestName,
        'allSpunDown' => $seen > 0 && $active === 0,
        'assignedSeen' => $seen,
        'activeDisks' => $active,
    ];
}

function waz_md1200_controller_auto_target(array $config, array $thermal, ?int $previous): array
{
    $cool = (int) waz_md1200_controller_number($config, 'MD1200_SPEED_COOL', 20);
    $warm = (int) waz_md1200_controller_number($config, 'MD1200_SPEED_WARM', 25);
    $hot = (int) waz_md1200_controller_number($config, 'MD1200_SPEED_HOT', 30);
    $veryHot = (int) waz_md1200_controller_number($config, 'MD1200_SPEED_VERY_HOT', 50);
    $sensorFailure = (int) waz_md1200_controller_number($config, 'MD1200_SENSOR_FAILURE_SPEED', 50);
    if ($thermal['allSpunDown']) return ['speed' => $cool, 'reason' => 'assigned disks spun down'];
    if ($thermal['temperatureC'] === null) return ['speed' => $sensorFailure, 'reason' => 'temperature unavailable; fail-safe'];

    $temperature = (float) $thermal['temperatureC'];
    $warmAt = waz_md1200_controller_number($config, 'MD1200_THRESHOLD_WARM_C', 35.0);
    $hotAt = waz_md1200_controller_number($config, 'MD1200_THRESHOLD_HOT_C', 45.0);
    $veryHotAt = waz_md1200_controller_number($config, 'MD1200_THRESHOLD_VERY_HOT_C', 50.0);
    $candidate = $temperature >= $veryHotAt ? $veryHot : ($temperature >= $hotAt ? $hot : ($temperature >= $warmAt ? $warm : $cool));

    if ($previous !== null && $candidate < $previous) {
        $hysteresis = max(0.0, waz_md1200_controller_number($config, 'MD1200_HYSTERESIS_C', 1.0));
        $lowerAt = $previous >= $veryHot ? $veryHotAt : ($previous >= $hot ? $hotAt : $warmAt);
        if ($temperature >= ($lowerAt - $hysteresis)) $candidate = $previous;
    }
    return ['speed' => $candidate, 'reason' => ($thermal['temperatureSource'] ?? 'disk') . ' ' . $temperature . '°C'];
}

function waz_md1200_controller_docker_running(): bool
{
    $lines = [];
    $exitCode = 1;
    @exec("docker ps --format '{{.Names}}' 2>/dev/null", $lines, $exitCode);
    if ($exitCode !== 0) return false;
    foreach ($lines as $name) {
        if (strcasecmp(trim((string) $name), 'MD1200-Fan-Controller') === 0) return true;
    }
    return false;
}

function waz_md1200_controller_send(string $port, int $speed, bool $dryRun): array
{
    if ($dryRun) return ['state' => 'dry-run', 'message' => 'Dry run; no serial write'];
    if ($port === '' || !file_exists($port)) return ['state' => 'fault', 'message' => 'Serial adapter is missing'];

    $lockPath = '/var/run/waz.dashboard/md1200-' . substr(sha1($port), 0, 12) . '.lock';
    $lock = @fopen($lockPath, 'c+');
    if ($lock === false || !@flock($lock, LOCK_EX | LOCK_NB)) {
        if (is_resource($lock)) fclose($lock);
        return ['state' => 'fault', 'message' => 'Serial adapter is already in use'];
    }
    try {
        $lines = [];
        $exitCode = 1;
        $command = 'stty -F ' . escapeshellarg($port) . ' 38400 raw -echo -crtscts -hupcl cs8 -cstopb -parenb';
        @exec($command . ' 2>/dev/null', $lines, $exitCode);
        if ($exitCode !== 0) return ['state' => 'fault', 'message' => 'Unable to configure serial adapter'];

        $handle = @fopen($port, 'w');
        if ($handle === false) return ['state' => 'fault', 'message' => 'Unable to open serial adapter'];
        $payload = 'set_speed ' . $speed . "\r\n";
        for ($attempt = 0; $attempt < 5; $attempt++) {
            $written = @fwrite($handle, $payload);
            @fflush($handle);
            if ($written === false || $written !== strlen($payload)) {
                fclose($handle);
                return ['state' => 'fault', 'message' => 'Serial command write failed'];
            }
            usleep(100000);
        }
        fclose($handle);
        return ['state' => 'sent', 'message' => 'Command sent; awaiting independent fan telemetry'];
    } finally {
        flock($lock, LOCK_UN);
        fclose($lock);
    }
}

function waz_md1200_controller_rpm(string $id, string $device, string $fixtureDirectory): array
{
    if ($fixtureDirectory !== '') {
        $fixture = rtrim($fixtureDirectory, '/\\') . DIRECTORY_SEPARATOR . $id . '.txt';
        $output = is_file($fixture) ? (string) @file_get_contents($fixture) : '';
    } elseif ($device === '') {
        return ['state' => 'unconfigured', 'averageRpm' => null, 'fanCount' => 0, 'message' => 'SES device is not mapped'];
    } elseif (!file_exists($device)) {
        return ['state' => 'fault', 'averageRpm' => null, 'fanCount' => 0, 'message' => 'SES device is missing'];
    } else {
        $binary = trim((string) @shell_exec('command -v sg_ses 2>/dev/null'));
        if ($binary === '') return ['state' => 'unavailable', 'averageRpm' => null, 'fanCount' => 0, 'message' => 'sg_ses is unavailable'];
        $lines = [];
        $exitCode = 1;
        @exec(escapeshellarg($binary) . ' -p es ' . escapeshellarg($device) . ' 2>/dev/null', $lines, $exitCode);
        if ($exitCode !== 0) return ['state' => 'fault', 'averageRpm' => null, 'fanCount' => 0, 'message' => 'SES telemetry read failed'];
        $output = implode("\n", $lines);
    }

    preg_match_all('/Actual\s+speed\s*=\s*([0-9]+)\s*rpm/i', $output, $matches);
    $values = array_values(array_filter(array_map('intval', $matches[1] ?? []), static fn(int $rpm): bool => $rpm > 0));
    if (!$values) return ['state' => 'unavailable', 'averageRpm' => null, 'fanCount' => 0, 'message' => 'No fan RPM values were reported'];
    return [
        'state' => 'normal',
        'averageRpm' => (int) round(array_sum($values) / count($values)),
        'fanCount' => count($values),
        'message' => '',
    ];
}

function waz_md1200_controller_write_state(string $path, array $state): void
{
    $directory = dirname($path);
    if (!is_dir($directory)) @mkdir($directory, 0755, true);
    $encoded = json_encode($state, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    if ($encoded === false) return;
    $temporary = $path . '.tmp.' . getmypid();
    if (@file_put_contents($temporary, $encoded . "\n", LOCK_EX) !== false) {
        @chmod($temporary, 0644);
        @rename($temporary, $path);
    }
}

$previousTargets = [];
$lastCommands = [];
$previousMode = null;
$nextPollAt = 0;
$lastConfigSignature = '';

while ($running) {
    clearstatcache(true, $configPath);
    $signature = is_file($configPath) ? (string) @sha1_file($configPath) : '';
    $config = waz_md1200_read_config($configPath);
    $pollSeconds = max(5, (int) waz_md1200_controller_number($config, 'MD1200_POLL_SECONDS', 30));
    $configChanged = $signature !== $lastConfigSignature;
    if (!$runOnce && !$configChanged && time() < $nextPollAt) {
        sleep(1);
        continue;
    }
    $lastConfigSignature = $signature;
    $nextPollAt = time() + $pollSeconds;

    $enabled = waz_md1200_enabled($config);
    $mode = waz_md1200_mode($config);
    $manualSpeed = waz_md1200_manual_speed($config);
    $dockerConflict = $enabled && waz_md1200_controller_docker_running();
    $disks = waz_md1200_controller_disks($disksPath);
    $shelfStates = [];
    $controllerState = 'normal';
    $messages = [];

    if (!$enabled) $messages[] = 'Controller disabled until migration is approved';
    if ($dockerConflict) {
        $controllerState = 'fault';
        $messages[] = 'Docker controller is still running; serial writes blocked';
    }

    foreach (waz_md1200_controller_shelves($config) as $shelf) {
        $id = $shelf['id'];
        $thermal = waz_md1200_controller_temperature($shelf['disks'], $disks);
        $auto = waz_md1200_controller_auto_target($config, $thermal, $previousMode === 'auto' ? ($previousTargets[$id] ?? null) : null);
        $target = $mode === 'manual' ? $manualSpeed : (int) $auto['speed'];
        $reason = $mode === 'manual' ? 'manual selection' : (string) $auto['reason'];
        $lastCommand = $lastCommands[$id] ?? null;
        $reassert = max(30, (int) waz_md1200_controller_number($config, 'MD1200_REASSERT_SECONDS', 900));
        $commandDue = $enabled && !$dockerConflict && (
            $configChanged || $lastCommand === null || ($previousTargets[$id] ?? null) !== $target || (time() - (int) $lastCommand) >= $reassert
        );
        $write = ['state' => $enabled ? 'idle' : 'disabled', 'message' => $enabled ? 'No command due' : 'Controller disabled'];
        if ($commandDue) {
            $write = waz_md1200_controller_send((string) $shelf['port'], $target, $dryRun);
            if (in_array($write['state'], ['sent', 'dry-run'], true)) $lastCommands[$id] = time();
        }
        $telemetry = waz_md1200_controller_rpm($id, (string) $shelf['sesDevice'], $fixtureDirectory);

        if ($enabled && $write['state'] === 'fault') {
            $controllerState = 'fault';
            $messages[] = $shelf['name'] . ': ' . $write['message'];
        } elseif ($enabled && $telemetry['state'] !== 'normal' && $controllerState !== 'fault') {
            $controllerState = 'attention';
            $messages[] = $shelf['name'] . ': ' . $telemetry['message'];
        }

        $shelfStates[] = [
            'id' => $id,
            'name' => $shelf['name'],
            'assignedDisks' => $shelf['disks'],
            'assignedSeen' => $thermal['assignedSeen'],
            'activeDisks' => $thermal['activeDisks'],
            'temperatureC' => $thermal['temperatureC'],
            'temperatureSource' => $thermal['temperatureSource'],
            'targetPercent' => $target,
            'targetReason' => $reason,
            'writeState' => $write['state'],
            'writeMessage' => $write['message'],
            'lastCommandAt' => $lastCommands[$id] ?? null,
            'telemetryState' => $telemetry['state'],
            'averageRpm' => $telemetry['averageRpm'],
            'fanCount' => $telemetry['fanCount'],
            'telemetryMessage' => $telemetry['message'],
        ];
        $previousTargets[$id] = $target;
    }
    $previousMode = $mode;

    waz_md1200_controller_write_state($statePath, [
        'schemaVersion' => 1,
        'generatedAt' => time(),
        'controller' => [
            'enabled' => $enabled,
            'mode' => $mode,
            'manualSpeed' => $manualSpeed,
            'state' => $controllerState,
            'message' => implode(' · ', array_values(array_unique($messages))),
            'dockerConflict' => $dockerConflict,
            'dryRun' => $dryRun,
        ],
        'shelves' => $shelfStates,
    ]);

    if ($runOnce) break;
}
