<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Get backend URL from environment variables or use intelligent detection
$backendUrl = getenv('BACKEND_API_URL');

if (!$backendUrl) {
    // Auto-detect backend URL based on environment
    $hostname = gethostname();
    
    if (strpos($hostname, 'web-') !== false) {
        // Replace 'web-' with 'app-' in hostname
        $backendUrl = 'http://' . str_replace('web-', 'app-', $hostname);
    } elseif (getenv('ENVIRONMENT') === 'development') {
        $backendUrl = 'http://localhost:80';
    } else {
        // Default to common AWS ALB pattern
        $backendUrl = 'http://app-alb';
    }
}

echo json_encode([
    'backendUrl' => $backendUrl,
    'environment' => getenv('ENVIRONMENT') ?: 'development',
    'timestamp' => date('c')
]);
?>