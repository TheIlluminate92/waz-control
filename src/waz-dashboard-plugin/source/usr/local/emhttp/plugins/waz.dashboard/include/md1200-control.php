<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

require_once __DIR__ . '/md1200.php';

try {
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
        // Unraid's PHP auto-prepend validates csrf_token and removes it from $_POST.
        $mode = strtolower(trim((string) ($_POST['mode'] ?? '')));
        if (!in_array($mode, ['auto', 'manual'], true)) {
            throw new InvalidArgumentException('Mode must be auto or manual');
        }
        $updates = ['MD1200_MODE' => $mode];
        if ($mode === 'manual') {
            $speed = (int) ($_POST['speed'] ?? 0);
            if (!in_array($speed, [20, 30, 40, 50], true)) {
                throw new InvalidArgumentException('Manual speed must be 20, 30, 40, or 50 percent');
            }
            $updates['MD1200_MANUAL_SPEED'] = (string) $speed;
        }
        waz_md1200_update_config($updates);
    }

    echo json_encode(waz_md1200_public_status(), JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
} catch (InvalidArgumentException $error) {
    http_response_code(422);
    echo json_encode(['error' => $error->getMessage()], JSON_UNESCAPED_SLASHES);
} catch (Throwable $error) {
    if (http_response_code() < 400) http_response_code(500);
    echo json_encode(['error' => $error->getMessage()], JSON_UNESCAPED_SLASHES);
}
