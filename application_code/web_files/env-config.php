<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get backend URL from environment variables or use intelligent detection
$backendUrl = getenv('BACKEND_API_URL');

if (!$backendUrl) {
    // Get from Terraform variables (passed during instance creation)
    $backendUrl = 'http://' . getenv('APP_ALB_DNS') . '/api';
}

if (!$backendUrl) {
    // Auto-detect backend URL based on environment
    $hostname = gethostname();
    
    if (strpos($hostname, 'web-') !== false) {
        // Replace 'web-' with 'app-' in hostname
        $backendUrl = 'http://' . str_replace('web-', 'app-', $hostname) . '/api';
    } elseif (getenv('ENVIRONMENT') === 'development') {
        $backendUrl = 'http://localhost/api';
    } else {
        // Default to common AWS ALB pattern
        $backendUrl = 'http://app-alb/api';
    }
}

echo json_encode([
    'backendUrl' => $backendUrl,
    'environment' => getenv('ENVIRONMENT') ?: 'development',
    'project' => getenv('PROJECT_NAME') ?: 'three-tier-app',
    'timestamp' => date('c'),
    'server' => gethostname()
]);
?>