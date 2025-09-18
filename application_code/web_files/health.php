<?php
header('Content-Type: application/json');

// CORS headers - be more restrictive in production
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Get and sanitize environment variables
$alb = filter_var(getenv("APP_ALB_DNS"), FILTER_SANITIZE_URL) ?: "localhost";
$project = htmlspecialchars(getenv("PROJECT_NAME") ?: "three-tier-app", ENT_QUOTES, 'UTF-8');
$env = htmlspecialchars(getenv("ENVIRONMENT") ?: "development", ENT_QUOTES, 'UTF-8');

// Prepare response data
$response = [
    'status' => 'healthy',
    'service' => 'web-frontend',
    'timestamp' => date('c'),
    'server' => gethostname(),
    'php_version' => phpversion(),
    'load_balancer' => $_SERVER['HTTP_HOST'] ?? 'unknown',
    'environment' => $env,
    'project' => $project,
    'backend_alb' => $alb
];

// Encode and output with error handling
$json = json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
if ($json === false) {
    http_response_code(500);
    $errorResponse = [
        'status' => 'error',
        'message' => 'Failed to encode JSON response',
        'json_error' => json_last_error_msg()
    ];
    echo json_encode($errorResponse);
    exit;
}

echo $json;
?>