$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$manifest = Join-Path $projectRoot 'dist/waz.dashboard.plg'

& (Join-Path $projectRoot 'scripts/build.ps1') -OutputPath $manifest

$xmlSettings = [System.Xml.XmlReaderSettings]::new()
$xmlSettings.DtdProcessing = [System.Xml.DtdProcessing]::Parse
$reader = [System.Xml.XmlReader]::Create($manifest, $xmlSettings)
try {
    while ($reader.Read()) { }
} finally {
    $reader.Dispose()
}

$required = @(
    '/usr/local/emhttp/plugins/waz.dashboard/WazDashboard.page',
    '/usr/local/emhttp/plugins/waz.dashboard/WazWorkloads.page',
    '/usr/local/emhttp/plugins/waz.dashboard/WazStorage.page',
    '/usr/local/emhttp/plugins/waz.dashboard/WazHealthBanner.page',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/css/system.css',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/css/workloads.css',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/css/storage.css',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/css/banner.css',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/js/system.js',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/js/workloads.js',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/js/storage.js',
    '/usr/local/emhttp/plugins/waz.dashboard/assets/js/banner.js',
    '/usr/local/emhttp/plugins/waz.dashboard/include/metrics.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/workloads.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/storage.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/gpu-sampler.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/health.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/status.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/md1200.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/md1200-control.php',
    '/usr/local/emhttp/plugins/waz.dashboard/include/md1200-controller.php',
    '/usr/local/emhttp/plugins/waz.dashboard/scripts/start.sh',
    '/usr/local/emhttp/plugins/waz.dashboard/scripts/stop.sh',
    '/usr/local/emhttp/plugins/waz.dashboard/scripts/backup-md1200.sh',
    '/usr/local/emhttp/plugins/waz.dashboard/scripts/diagnose-md1200.sh',
    '/usr/local/emhttp/plugins/waz.dashboard/scripts/test-md1200-controls.sh'
)

$manifestText = [System.IO.File]::ReadAllText($manifest)
foreach ($path in $required) {
    if (-not $manifestText.Contains("Name=`"$path`"")) {
        throw "Missing packaged file: $path"
    }
}

if ($manifestText.Contains('@@')) {
    throw 'An unexpanded build placeholder remains in the manifest.'
}
if ($manifestText -notmatch 'Method="remove"') {
    throw 'Manifest is missing an uninstall handler.'
}
if ($manifestText -match 'rm -rf\s+"/boot/config/plugins/waz\.dashboard"') {
    throw 'The uninstall handler removes persistent settings, which breaks forced rolling updates.'
}
if ($manifestText -notmatch 'pluginURL="file:///boot/config/plugins/waz.dashboard.plg"') {
    throw 'Manifest is missing its rolling-test pluginURL.'
}
if ($manifestText -match 'setTimeout\(systemLoop,\s*100\)' -or $manifestText -match 'setInterval\([^\)]*,\s*100\)') {
    throw 'Legacy 100 ms browser polling remains.'
}
if ($manifestText -notmatch "\['column1'\]") {
    throw 'The System tile is not assigned to one native dashboard column.'
}
if ($manifestText -notmatch "\['column2'\]") {
    throw 'The Workloads tile is not assigned to the center dashboard column.'
}
if ($manifestText -notmatch "\['column3'\]") {
    throw 'The Storage tile is not assigned to the right dashboard column.'
}

foreach ($marker in @(
    'MemAvailable',
    'intel_gpu_top',
    'PRIMARY_INTERFACE',
    '#111417',
    'GPU_RECENT_SECONDS',
    'waz-summary-cpu-detail',
    '/plugins/hbaviewer/export.php',
    'waz-hba-0-temp',
    'waz-summary-flow',
    'waz-summary-power-detail',
    'waz-log-bar',
    "waz_filesystem_usage('/var/log')",
    'NOMPOWER',
    'grid-template-columns: repeat(3',
    'font-size: 15px',
    'height: 70px',
    'height: 54px',
    'waz-storage-tile',
    'waz-storage-alert',
    'waz_storage_attention',
    'waz-parity-progress',
    'waz-pool-tabs',
    'waz-location-groups',
    'waz-array-disks',
    'waz.dashboard.storage.selectedPool',
    'ResizeObserver',
    'groups.json',
    'locations.json',
    'devices.json',
    'WAZ_STORAGE_WARN_PERCENT',
    'waz_storage_group_layout',
    'waz_storage_next_parity',
    'nextScheduledAt',
    'LAST PARITY',
    'Parity 1',
    'border: 1px solid #34566b',
    'color: var(--disk-color, var(--waz-cyan))',
    "'sourceTray'",
    'grid-auto-rows: minmax(28px, 1fr)',
    'waz-summary-network-rx',
    'waz-summary-network-tx',
    'waz-workloads-tile',
    'waz-workloads-alert',
    'attentionMessages',
    "preg_match('/Exited \((1|137)\)/i'",
    "container['autostart'] === true",
    'autostart failed · killed / possible OOM',
    'autostart failed · application error',
    'waz-folder-tabs',
    'waz-container-grid',
    'grid-auto-rows: minmax(74px, auto)',
    'overflow-wrap: anywhere',
    'waz-top-processes',
    'waz-workloads-docker',
    'dockerVdisk',
    "waz_workloads_filesystem_usage('/var/lib/docker')",
    'docker-labels',
    'net.unraid.docker.folder',
    'TOP PROCESSES',
    'LIVE CPU · HOST + DOCKER',
    'waz.dashboard.workloads.selectedFolder',
    'waz.dashboard.workloads.selectedContainer',
    'addDockerContainerContext',
    "document.getElementById('docker_view')",
    "document.querySelector('#db_box1 > tbody.system')",
    'FolderView3',
    '/boot/config/plugins/folderview.plus/docker.json',
    '/boot/config/plugins/dynamix.my.servers/configs/docker.organizer.json',
    'waz_workloads_native_configuration',
    '/boot/config/plugins/folder.view3/docker.json',
    '/boot/config/plugins/folder.view2/docker.json',
    '/boot/config/plugins/folder.view/docker.json',
    'folderSource',
    'SERVER STATUS',
    'waz-system-header',
    '/containers/',
    'stats?stream=false',
    'process-samples.json',
    "var units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']"
    'waz-health-banner',
    'subsystemOrder = ["array", "storage", "cooling", "ups"]',
    '/plugins/waz.dashboard/include/status.php',
    '/boot/config/plugins/waz.dashboard/waz.dashboard.cfg',
    '/var/run/waz.dashboard/health-throttle-state.json',
    '--waz-health-background: #111417',
    '--waz-health-border: #303840',
    '--waz-health-cyan: #22b8f0',
    'waz-health__modules',
    'typeof window.contentMgmt === "function"',
    'Manage dashboard modules',
    'LEGACY_HEALTH_CONFIG',
    '${LEGACY_HEALTH_PLUGIN}.disabled'
    'MD1200_ENABLED="no"'
    'MD1200_MODE="auto"'
    'MD1200_MANUAL_SPEED="20"'
    'MD1200_SENSOR_FAILURE_SPEED="50"'
    'MD1200_THRESHOLD_VERY_HOT_C="50"'
    'MD1200_SPEED_VERY_HOT="50"'
    'MD1200_TOP_SES_DEVICE="/dev/sg18"'
    'MD1200_TOP_SES_ADDRESS="0:0:18:0"'
    'MD1200_BOTTOM_SES_DEVICE="/dev/sg11"'
    'MD1200_BOTTOM_SES_ADDRESS="0:0:11:0"'
    '/mnt/user/Back-Up/MD1200-Fan-Controller'
    'MD1200-Fan-Controller'
    'set_speed '
    'Actual\s+speed'
    'averageRpm'
    'MANUAL 40%'
    'fanEndpoint'
    'csrfToken'
    'dockerConflict'
    'Controller disabled until migration is approved'
    'sg_ses -p es'
    '/diagnostics/'
    'control-tests'
    'Returning both shelves to their normal 20% resting state'
    'delta>=250 && percent>=10'
)) {
    if (-not $manifestText.Contains($marker)) {
        throw "Missing implementation marker: $marker"
    }
}

$controllerSource = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'source/usr/local/emhttp/plugins/waz.dashboard/include/md1200-controller.php'))
$controlTestSource = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'source/usr/local/emhttp/plugins/waz.dashboard/scripts/test-md1200-controls.sh'))
$controlEndpointSource = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'source/usr/local/emhttp/plugins/waz.dashboard/include/md1200-control.php'))
$bannerSource = [System.IO.File]::ReadAllText((Join-Path (Split-Path -Parent $projectRoot) 'waz-health-plugin/source/usr/local/emhttp/plugins/waz.health/assets/js/banner.js'))
if (-not $controllerSource.Contains('$payload = ''set_speed '' . $speed . "\r";')) {
    throw 'MD1200 controller is not using carriage-return-only command framing.'
}
if (-not $controlTestSource.Contains("printf 'set_speed %s\r'")) {
    throw 'MD1200 commissioning test is not using carriage-return-only command framing.'
}
if ($controllerSource.Contains('$payload = ''set_speed '' . $speed . "\r\n";') -or $controlTestSource.Contains("printf 'set_speed %s\r\n'")) {
    throw 'MD1200 CRLF command framing was reintroduced.'
}
if (-not $controllerSource.Contains('@fopen($port, ''r+'')') -or -not $controllerSource.Contains('stream_set_blocking($handle, false)') -or -not $controllerSource.Contains('@fread($handle')) {
    throw 'MD1200 controller is not opening BlueDress read/write and draining its console response.'
}
if (-not $controlTestSource.Contains('exec 8<>"$PORT"') -or -not $controlTestSource.Contains('timeout 1 cat <&8')) {
    throw 'MD1200 commissioning test is not draining the BlueDress console response.'
}
if ($controllerSource.Contains('@fopen($port, ''w'')') -or $controlTestSource.Contains('exec 8>"$PORT"')) {
    throw 'MD1200 write-only BlueDress access was reintroduced.'
}
if (-not $bannerSource.Contains('window.csrf_token || config.csrfToken')) {
    throw 'MD1200 header control is not using Unraid''s current page session token.'
}
if ($controlEndpointSource.Contains('waz_md1200_expected_csrf') -or $controlEndpointSource.Contains("`$_POST['csrf_token']")) {
    throw 'MD1200 endpoint is redundantly validating the token that Unraid removes after validation.'
}

if ($manifestText.Contains('/boot/config/plugins/waz.dashboard/waz.health.cfg')) {
    throw 'Integrated Health is still pointed at the legacy configuration filename.'
}

$php = Get-Command php -ErrorAction SilentlyContinue
if ($php) {
    $phpFiles = @(
        'include/metrics.php', 'include/workloads.php', 'include/storage.php', 'include/gpu-sampler.php',
        'include/md1200.php', 'include/md1200-control.php', 'include/md1200-controller.php'
    )
    foreach ($relative in $phpFiles) {
        $file = Join-Path $projectRoot ('source/usr/local/emhttp/plugins/waz.dashboard/' + $relative)
        & $php.Source -l $file | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "PHP syntax check failed: $relative" }
    }
    foreach ($relative in @('include/health.php', 'include/status.php')) {
        $file = Join-Path (Split-Path -Parent $projectRoot) ('waz-health-plugin/source/usr/local/emhttp/plugins/waz.health/' + $relative)
        & $php.Source -l $file | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "PHP syntax check failed: $relative" }
    }

    $controller = Join-Path $projectRoot 'source/usr/local/emhttp/plugins/waz.dashboard/include/md1200-controller.php'
    $fixtures = Join-Path $PSScriptRoot 'fixtures'
    $autoState = Join-Path ([System.IO.Path]::GetTempPath()) ('waz-md1200-auto-' + [guid]::NewGuid() + '.json')
    $manualState = Join-Path ([System.IO.Path]::GetTempPath()) ('waz-md1200-manual-' + [guid]::NewGuid() + '.json')
    try {
        & $php.Source $controller --once --dry-run --config (Join-Path $fixtures 'md1200-auto.cfg') --disks (Join-Path $fixtures 'disks.ini') --state $autoState --fixture-dir (Join-Path $fixtures 'ses')
        if ($LASTEXITCODE -ne 0) { throw 'MD1200 Auto dry-run failed.' }
        $auto = Get-Content -Raw $autoState | ConvertFrom-Json
        if ($auto.shelves[0].targetPercent -ne 25 -or $auto.shelves[1].targetPercent -ne 50) { throw 'MD1200 Auto curve produced unexpected targets.' }
        if ($auto.shelves[0].averageRpm -ne 3965 -or $auto.shelves[1].averageRpm -ne 3535) { throw 'MD1200 average RPM parsing failed.' }
        if ($auto.shelves[0].fanCount -ne 4 -or $auto.shelves[1].fanCount -ne 4) { throw 'MD1200 fan parsing included the zero-RPM overall descriptor.' }

        & $php.Source $controller --once --dry-run --config (Join-Path $fixtures 'md1200-manual.cfg') --disks (Join-Path $fixtures 'disks.ini') --state $manualState --fixture-dir (Join-Path $fixtures 'ses')
        if ($LASTEXITCODE -ne 0) { throw 'MD1200 Manual dry-run failed.' }
        $manual = Get-Content -Raw $manualState | ConvertFrom-Json
        if ($manual.shelves[0].targetPercent -ne 40 -or $manual.shelves[1].targetPercent -ne 40) { throw 'MD1200 Manual mode did not apply to both shelves.' }
    } finally {
        Remove-Item -LiteralPath $autoState, $manualState -Force -ErrorAction SilentlyContinue
    }
}

$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
    foreach ($relative in @('start.sh', 'stop.sh', 'backup-md1200.sh', 'diagnose-md1200.sh', 'test-md1200-controls.sh')) {
        $file = Join-Path $projectRoot ('source/usr/local/emhttp/plugins/waz.dashboard/scripts/' + $relative)
        & $bash.Source -n $file
        if ($LASTEXITCODE -ne 0) { throw "Shell syntax check failed: $relative" }
    }
}

foreach ($removedMarker in @('WAZ // SYSTEM', 'waz-allocation', 'section=allocation', 'waz_allocation', 'waz-gpu-block', 'SERVER POWER', 'serverInputWatts', 'CONTAINER PROCESSES', 'waz-selected-process-list', 'waz-workloads-running-detail', 'waz-workloads-health-detail', 'waz-workloads-gpu-detail', 'waz-workloads-healthy', 'waz-workloads-issues', 'waz-docker-bar', 'waz-docker-percent', 'waz-docker-used', 'waz-docker-total', 'waz-array-location')) {
    if ($manifestText.Contains($removedMarker)) {
        throw "Removed UI or collector remains: $removedMarker"
    }
}

$boardOrder = @(
    'waz-summary-cpu', 'waz-summary-gpu', 'waz-summary-power',
    'waz-summary-memory', 'waz-summary-cooling', 'waz-hba-0-temp',
    'waz-summary-network', 'waz-summary-flow', 'waz-hba-1-temp'
)
$lastPosition = -1
foreach ($marker in $boardOrder) {
    $position = $manifestText.IndexOf('id="' + $marker + '"', [System.StringComparison]::Ordinal)
    if ($position -le $lastPosition) {
        throw "Status board marker is missing or out of order: $marker"
    }
    $lastPosition = $position
}

Write-Output 'WAZ System plugin manifest verification passed.'
