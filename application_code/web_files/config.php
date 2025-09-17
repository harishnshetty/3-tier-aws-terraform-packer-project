<?php
header("Content-Type: application/javascript");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

// Get environment variables with proper fallbacks
$alb = getenv("APP_ALB_DNS") ?: "localhost";
$project = getenv("PROJECT_NAME") ?: "three-tier-app";
$env = getenv("ENVIRONMENT") ?: "development";

// Ensure proper URL format
if (!empty($alb) && strpos($alb, 'http') !== 0) {
    $alb = "http://" . $alb;
}

// Output JavaScript with proper escaping
echo "window.APP_ALB_DNS = \"" . addslashes($alb) . "\";\n";
echo "window.PROJECT_NAME = \"" . addslashes($project) . "\";\n";
echo "window.ENVIRONMENT = \"" . addslashes($env) . "\";\n";
?>