<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

require_once __DIR__ . '/health.php';

try {
    echo json_encode(waz_health_snapshot(), JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode([
        'schemaVersion' => 1,
        'error' => 'Unable to read WAZ Health status',
    ], JSON_UNESCAPED_SLASHES);
}
