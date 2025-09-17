<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Get environment variables
$alb = getenv("APP_ALB_DNS") ?: "localhost";
$project = getenv("PROJECT_NAME") ?: "three-tier-app";
$env = getenv("ENVIRONMENT") ?: "development";

echo json_encode([
    'status' => 'healthy',
    'service' => 'web-frontend',
    'timestamp' => date('c'),
    'server' => gethostname(),
    'php_version' => phpversion(),
    'load_balancer' => $_SERVER['HTTP_HOST'] ?? 'unknown',
    'environment' => $env,
    'project' => $project,
    'backend_alb' => $alb
]);
?>