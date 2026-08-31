<?php

declare(strict_types=1);

const WAZ_MD1200_CONFIG = '/boot/config/plugins/waz.dashboard/waz.dashboard.cfg';
const WAZ_MD1200_STATE = '/var/run/waz.dashboard/md1200.json';
const WAZ_MD1200_PID = '/var/run/waz.dashboard/md1200-controller.pid';

function waz_md1200_defaults(): array
{
    return [
        'MD1200_ENABLED' => 'no',
        'MD1200_MODE' => 'auto',
        'MD1200_MANUAL_SPEED' => '20',
        'MD1200_POLL_SECONDS' => '30',
        'MD1200_REASSERT_SECONDS' => '900',
        'MD1200_SENSOR_FAILURE_SPEED' => '50',
        'MD1200_HYSTERESIS_C' => '1',
        'MD1200_THRESHOLD_WARM_C' => '35',
        'MD1200_THRESHOLD_HOT_C' => '45',
        'MD1200_THRESHOLD_VERY_HOT_C' => '50',
        'MD1200_SPEED_COOL' => '20',
        'MD1200_SPEED_WARM' => '25',
        'MD1200_SPEED_HOT' => '30',
        'MD1200_SPEED_VERY_HOT' => '50',
        'MD1200_TOP_NAME' => 'MD1200 Top',
        'MD1200_TOP_PORT' => '/dev/serial/by-id/usb-FTDI_USB_Serial_Converter_FTE33O9T-if00-port0',
        'MD1200_TOP_SES_DEVICE' => '/dev/sg18',
        'MD1200_TOP_SES_ADDRESS' => '0:0:18:0',
        'MD1200_TOP_DISKS' => 'disk1,disk2,disk3,disk4,parity,parity2',
        'MD1200_BOTTOM_NAME' => 'MD1200 Bottom',
        'MD1200_BOTTOM_PORT' => '/dev/serial/by-id/usb-FTDI_USB_Serial_Converter_FTE32AB2-if00-port0',
        'MD1200_BOTTOM_SES_DEVICE' => '/dev/sg11',
        'MD1200_BOTTOM_SES_ADDRESS' => '0:0:11:0',
        'MD1200_BOTTOM_DISKS' => 'disk5,disk6,disk7,disk8,disk9,disk10,disk11,disk12,disk13,disk14,disk15',
        'MD1200_BACKUP_DIR' => '/mnt/user/Back-Up/MD1200-Fan-Controller',
    ];
}

function waz_md1200_read_config(?string $path = null): array
{
    $path = $path ?: WAZ_MD1200_CONFIG;
    $configured = is_file($path) ? @parse_ini_file($path, false, INI_SCANNER_RAW) : [];
    return array_merge(waz_md1200_defaults(), is_array($configured) ? $configured : []);
}

function waz_md1200_enabled(array $config): bool
{
    return in_array(strtolower(trim((string) ($config['MD1200_ENABLED'] ?? 'no'))), ['1', 'yes', 'true', 'on'], true);
}

function waz_md1200_mode(array $config): string
{
    return strtolower(trim((string) ($config['MD1200_MODE'] ?? 'auto'))) === 'manual' ? 'manual' : 'auto';
}

function waz_md1200_manual_speed(array $config): int
{
    $speed = (int) ($config['MD1200_MANUAL_SPEED'] ?? 20);
    return in_array($speed, [20, 30, 40, 50], true) ? $speed : 20;
}

function waz_md1200_read_state(?string $path = null): array
{
    $path = $path ?: WAZ_MD1200_STATE;
    $raw = @file_get_contents($path);
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function waz_md1200_public_status(): array
{
    $config = waz_md1200_read_config();
    $state = waz_md1200_read_state();
    $generatedAt = isset($state['generatedAt']) && is_numeric($state['generatedAt']) ? (int) $state['generatedAt'] : null;
    $poll = max(5, (int) ($config['MD1200_POLL_SECONDS'] ?? 30));
    $stale = $generatedAt === null || (time() - $generatedAt) > max(75, ($poll * 2) + 15);
    $enabled = waz_md1200_enabled($config);
    $controller = is_array($state['controller'] ?? null) ? $state['controller'] : [];
    $shelves = is_array($state['shelves'] ?? null) ? array_values($state['shelves']) : [];

    $healthState = 'normal';
    $message = '';
    if ($enabled && $stale) {
        $healthState = 'fault';
        $message = 'MD1200 controller status is stale';
    } elseif ($enabled) {
        $candidate = strtolower((string) ($controller['state'] ?? 'unknown'));
        $healthState = in_array($candidate, ['normal', 'attention', 'fault'], true) ? $candidate : 'attention';
        $message = trim((string) ($controller['message'] ?? ''));
    }

    return [
        'enabled' => $enabled,
        'mode' => waz_md1200_mode($config),
        'manualSpeed' => waz_md1200_manual_speed($config),
        'allowedManualSpeeds' => [20, 30, 40, 50],
        'healthState' => $healthState,
        'message' => $message,
        'stale' => $stale,
        'generatedAt' => $generatedAt,
        'shelves' => $shelves,
    ];
}

function waz_md1200_quote_ini(string $value): string
{
    return '"' . str_replace(['\\', '"', "\r", "\n"], ['\\\\', '\\"', '', ''], $value) . '"';
}

function waz_md1200_update_config(array $updates, ?string $path = null): void
{
    $path = $path ?: WAZ_MD1200_CONFIG;
    $directory = dirname($path);
    if (!is_dir($directory) && !@mkdir($directory, 0755, true) && !is_dir($directory)) {
        throw new RuntimeException('Unable to create controller configuration directory');
    }

    $lock = @fopen($path . '.lock', 'c+');
    if ($lock === false || !@flock($lock, LOCK_EX)) {
        if (is_resource($lock)) fclose($lock);
        throw new RuntimeException('Unable to lock controller configuration');
    }
    try {
        $text = is_file($path) ? (string) @file_get_contents($path) : '';
        foreach ($updates as $key => $value) {
            if (!preg_match('/^MD1200_[A-Z0-9_]+$/', (string) $key)) {
                throw new InvalidArgumentException('Unsupported controller setting');
            }
            $line = $key . '=' . waz_md1200_quote_ini((string) $value);
            $pattern = '/^' . preg_quote((string) $key, '/') . '=.*$/m';
            if (preg_match($pattern, $text)) {
                $text = (string) preg_replace($pattern, $line, $text, 1);
            } else {
                $text = rtrim($text) . ($text === '' ? '' : "\n") . $line . "\n";
            }
        }
        $temporary = $path . '.tmp.' . getmypid();
        if (@file_put_contents($temporary, $text, LOCK_EX) === false || !@rename($temporary, $path)) {
            @unlink($temporary);
            throw new RuntimeException('Unable to save controller configuration');
        }
        @chmod($path, 0644);
    } finally {
        flock($lock, LOCK_UN);
        fclose($lock);
    }
}
