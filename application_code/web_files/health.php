<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

echo json_encode([
    'status' => 'healthy',
    'service' => 'web-frontend',
    'timestamp' => date('c'),
    'server' => gethostname(),
    'php_version' => phpversion(),
    'load_balancer' => $_SERVER['HTTP_HOST'] ?? 'unknown',
    'environment' => getenv('ENVIRONMENT') ?: 'development'
]);
?>