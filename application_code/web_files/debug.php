<?php
header('Content-Type: text/plain');
echo "=== Frontend Debug Information ===\n\n";

// Environment variables
echo "APP_ALB_DNS: " . (getenv("APP_ALB_DNS") ?: "NOT_SET") . "\n";
echo "PROJECT_NAME: " . (getenv("PROJECT_NAME") ?: "NOT_SET") . "\n";
echo "ENVIRONMENT: " . (getenv("ENVIRONMENT") ?: "NOT_SET") . "\n\n";

// Test backend connection
$backend_url = getenv("APP_ALB_DNS") . "/api/health";
echo "Testing backend: " . $backend_url . "\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $backend_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_FAILONERROR, true);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: " . $http_code . "\n";
echo "Error: " . ($error ?: "None") . "\n";
echo "Response: " . ($response ? substr($response, 0, 500) : "No response") . "\n\n";

// Test local API proxy
echo "Testing local proxy: http://localhost/api/health\n";
$local_response = file_get_contents("http://localhost/api/health");
echo "Local proxy response: " . ($local_response ? substr($local_response, 0, 500) : "No response");
?>