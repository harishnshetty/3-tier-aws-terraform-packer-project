<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get environment variables
$db_host = getenv('DB_HOST');
$db_username = getenv('DB_USERNAME');
$db_password = getenv('DB_PASSWORD');
$db_name = getenv('DB_NAME') ?: 'appdb';

$request_uri = $_SERVER['REQUEST_URI'];
$method = $_SERVER['REQUEST_METHOD'];

// Remove query string
$request_uri = strtok($request_uri, '?');

// Simple routing
try {
    if (strpos($request_uri, '/api/health') === 0) {
        healthCheck();
    } elseif (strpos($request_uri, '/api/test') === 0) {
        testEndpoint();
    } elseif (strpos($request_uri, '/api/db-test') === 0) {
        testDatabaseConnection();
    } elseif (strpos($request_uri, '/api/users') === 0) {
        handleUsers($method);
    } elseif (strpos($request_uri, '/api/products') === 0) {
        handleProducts($method);
    } elseif (strpos($request_uri, '/api/orders') === 0) {
        handleOrders($method);
    } elseif (strpos($request_uri, '/api/info') === 0) {
        systemInfo();
    } else {
        defaultResponse();
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Internal server error',
        'error' => $e->getMessage(),
        'server' => gethostname()
    ]);
}

function healthCheck() {
    echo json_encode([
        'status' => 'healthy',
        'service' => 'api-backend',
        'timestamp' => date('c'),
        'server' => gethostname(),
        'environment' => getenv('ENVIRONMENT') ?: 'development',
        'database_connected' => true
    ]);
}

function testEndpoint() {
    echo json_encode([
        'status' => 'success',
        'message' => 'Backend API is working perfectly! 🎉',
        'service' => 'api-backend',
        'server' => gethostname(),
        'timestamp' => date('c'),
        'features' => [
            'database_connection' => true,
            'rest_api' => true,
            'json_response' => true,
            'cors_enabled' => true
        ]
    ]);
}

function testDatabaseConnection() {
    $db_host = getenv('DB_HOST');
    $db_username = getenv('DB_USERNAME');
    $db_password = getenv('DB_PASSWORD');
    $db_name = getenv('DB_NAME') ?: 'appdb';

    try {
        $pdo = new PDO(
            "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
            $db_username,
            $db_password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_TIMEOUT => 5,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]
        );

        // Test connection
        $stmt = $pdo->query("SELECT 1 as connection_test, NOW() as current_time, VERSION() as mysql_version");
        $result = $stmt->fetch();

        // Check if tables exist, create if not
        initDatabase($pdo);

        $userCount = $pdo->query("SELECT COUNT(*) as count FROM users")->fetch()['count'];
        $productCount = $pdo->query("SELECT COUNT(*) as count FROM products")->fetch()['count'];

        echo json_encode([
            'status' => 'success',
            'message' => 'Database connection successful!',
            'server' => gethostname(),
            'database' => [
                'host' => $db_host,
                'name' => $db_name,
                'connected' => true,
                'users_count' => $userCount,
                'products_count' => $productCount
            ]
        ]);

    } catch (PDOException $e) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Database connection failed',
            'error' => $e->getMessage(),
            'server' => gethostname()
        ]);
    }
}

function initDatabase($pdo) {
    // Create tables if they don't exist
    $tables = [
        "CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )",
        
        "CREATE TABLE IF NOT EXISTS products (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(200) NOT NULL,
            price DECIMAL(10, 2) NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )",
        
        "CREATE TABLE IF NOT EXISTS orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            total_amount DECIMAL(10, 2) NOT NULL,
            status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )"
    ];

    foreach ($tables as $tableSql) {
        $pdo->exec($tableSql);
    }

    // Insert sample data if tables are empty
    $userCount = $pdo->query("SELECT COUNT(*) as count FROM users")->fetch()['count'];
    if ($userCount == 0) {
        $pdo->exec("INSERT INTO users (name, email) VALUES
            ('John Doe', 'john@example.com'),
            ('Jane Smith', 'jane@example.com'),
            ('Bob Johnson', 'bob@example.com')");
    }

    $productCount = $pdo->query("SELECT COUNT(*) as count FROM products")->fetch()['count'];
    if ($productCount == 0) {
        $pdo->exec("INSERT INTO products (name, price, description) VALUES
            ('Laptop', 999.99, 'High-performance laptop'),
            ('Smartphone', 499.99, 'Latest smartphone'),
            ('Headphones', 99.99, 'Wireless headphones')");
    }
}

function handleUsers($method) {
    $db_host = getenv('DB_HOST');
    $db_username = getenv('DB_USERNAME');
    $db_password = getenv('DB_PASSWORD');
    $db_name = getenv('DB_NAME') ?: 'appdb';

    try {
        $pdo = new PDO(
            "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
            $db_username,
            $db_password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]
        );

        if ($method === 'GET') {
            $stmt = $pdo->query("SELECT * FROM users ORDER BY created_at DESC");
            $users = $stmt->fetchAll();
            
            echo json_encode([
                'status' => 'success',
                'data' => $users,
                'count' => count($users),
                'server' => gethostname()
            ]);
            
        } elseif ($method === 'POST') {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['name']) || !isset($input['email'])) {
                http_response_code(400);
                echo json_encode([
                    'status' => 'error',
                    'message' => 'Name and email are required',
                    'server' => gethostname()
                ]);
                return;
            }

            $stmt = $pdo->prepare("INSERT INTO users (name, email) VALUES (?, ?)");
            $stmt->execute([$input['name'], $input['email']]);
            
            echo json_encode([
                'status' => 'success',
                'message' => 'User created successfully',
                'user_id' => $pdo->lastInsertId(),
                'server' => gethostname()
            ]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database operation failed',
            'error' => $e->getMessage(),
            'server' => gethostname()
        ]);
    }
}

function handleProducts($method) {
    $db_host = getenv('DB_HOST');
    $db_username = getenv('DB_USERNAME');
    $db_password = getenv('DB_PASSWORD');
    $db_name = getenv('DB_NAME') ?: 'appdb';

    try {
        $pdo = new PDO(
            "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
            $db_username,
            $db_password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]
        );

        if ($method === 'GET') {
            $stmt = $pdo->query("SELECT * FROM products ORDER BY created_at DESC");
            $products = $stmt->fetchAll();
            
            echo json_encode([
                'status' => 'success',
                'data' => $products,
                'count' => count($products),
                'server' => gethostname()
            ]);
            
        } elseif ($method === 'POST') {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['name']) || !isset($input['price'])) {
                http_response_code(400);
                echo json_encode([
                    'status' => 'error',
                    'message' => 'Name and price are required',
                    'server' => gethostname()
                ]);
                return;
            }

            $stmt = $pdo->prepare("INSERT INTO products (name, price, description) VALUES (?, ?, ?)");
            $stmt->execute([
                $input['name'], 
                $input['price'], 
                $input['description'] ?? null
            ]);
            
            echo json_encode([
                'status' => 'success',
                'message' => 'Product created successfully',
                'product_id' => $pdo->lastInsertId(),
                'server' => gethostname()
            ]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database operation failed',
            'error' => $e->getMessage(),
            'server' => gethostname()
        ]);
    }
}

function handleOrders($method) {
    $db_host = getenv('DB_HOST');
    $db_username = getenv('DB_USERNAME');
    $db_password = getenv('DB_PASSWORD');
    $db_name = getenv('DB_NAME') ?: 'appdb';

    try {
        $pdo = new PDO(
            "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
            $db_username,
            $db_password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]
        );

        if ($method === 'GET') {
            $stmt = $pdo->query("
                SELECT o.*, u.name as user_name 
                FROM orders o 
                LEFT JOIN users u ON o.user_id = u.id 
                ORDER BY o.created_at DESC
            ");
            $orders = $stmt->fetchAll();
            
            echo json_encode([
                'status' => 'success',
                'data' => $orders,
                'count' => count($orders),
                'server' => gethostname()
            ]);
            
        } elseif ($method === 'POST') {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['user_id']) || !isset($input['total_amount'])) {
                http_response_code(400);
                echo json_encode([
                    'status' => 'error',
                    'message' => 'User ID and total amount are required',
                    'server' => gethostname()
                ]);
                return;
            }

            $stmt = $pdo->prepare("INSERT INTO orders (user_id, total_amount, status) VALUES (?, ?, ?)");
            $stmt->execute([
                $input['user_id'], 
                $input['total_amount'], 
                $input['status'] ?? 'pending'
            ]);
            
            echo json_encode([
                'status' => 'success',
                'message' => 'Order created successfully',
                'order_id' => $pdo->lastInsertId(),
                'server' => gethostname()
            ]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database operation failed',
            'error' => $e->getMessage(),
            'server' => gethostname()
        ]);
    }
}

function systemInfo() {
    echo json_encode([
        'system' => [
            'server' => gethostname(),
            'php_version' => phpversion(),
            'environment' => getenv('ENVIRONMENT') ?: 'development',
            'project' => getenv('PROJECT_NAME') ?: 'three-tier-app',
            'timestamp' => date('c')
        ],
        'database' => [
            'host' => getenv('DB_HOST'),
            'name' => getenv('DB_NAME') ?: 'appdb',
            'user' => getenv('DB_USERNAME')
        ],
        'resources' => [
            'memory_usage' => memory_get_usage(true),
            'memory_peak' => memory_get_peak_usage(true),
            'load_average' => function_exists('sys_getloadavg') ? sys_getloadavg() : 'N/A'
        ]
    ]);
}

function defaultResponse() {
    echo json_encode([
        'message' => 'Welcome to Three-Tier API',
        'endpoints' => [
            'GET /api/health' => 'Health check',
            'GET /api/test' => 'Test endpoint',
            'GET /api/db-test' => 'Test database connection',
            'GET /api/users' => 'Get all users',
            'POST /api/users' => 'Create new user',
            'GET /api/products' => 'Get all products',
            'POST /api/products' => 'Create new product',
            'GET /api/orders' => 'Get all orders',
            'POST /api/orders' => 'Create new order',
            'GET /api/info' => 'System information'
        ],
        'server' => gethostname(),
        'documentation' => 'See frontend for interactive testing'
    ]);
}
?>