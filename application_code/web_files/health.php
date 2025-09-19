<?php
// Simple health check endpoint
header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'server' => gethostname(),
    'timestamp' => date('c'),
    'service' => 'frontend-web',
    'php_version' => phpversion()
];

echo json_encode($health, JSON_PRETTY_PRINT);
?>