<?php
header("Content-Type: application/javascript");
$alb = getenv("APP_ALB_DNS") ?: "localhost";
$project = getenv("PROJECT_NAME") ?: "three-tier-app";
$env = getenv("ENVIRONMENT") ?: "development";

echo <<<JS
window.APP_ALB_DNS = "http://$alb";
window.PROJECT_NAME = "$project";
window.ENVIRONMENT = "$env";
JS;
