<?php
header('Content-Type: text/plain');
echo "PHP is working!\n";
echo "Server: " . gethostname() . "\n";
echo "PHP Version: " . phpversion() . "\n";

// Test environment variables
$alb = getenv("APP_ALB_DNS") ?: "not-set";
echo "APP_ALB_DNS: " . $alb . "\n";

// Test config.php output
include('config.php');
?>