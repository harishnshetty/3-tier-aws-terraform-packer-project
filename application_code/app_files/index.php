<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ===== Helper: Create PDO connection =====
function getPDO() {
    $db_host = getenv('DB_HOST');
    $db_username = getenv('DB_USERNAME');
    $db_password = getenv('DB_PASSWORD');
    $db_name = getenv('DB_NAME') ?: 'appdb';

    try {
        return new PDO(
            "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
            $db_username,
            $db_password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_TIMEOUT => 5
            ]
        );
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Database connection failed',
            'server'  => gethostname()
        ]);
        exit();
    }
}

// ===== Routing =====
$request_uri = strtok($_SERVER['REQUEST_URI'], '?');
$method = $_SERVER['REQUEST_METHOD'];

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
        'server' => gethostname()
    ]);
}

// ===== Handlers =====
function healthCheck() {
    $connected = false;
    try {
        $pdo = getPDO();
        $pdo->query("SELECT 1");
        $connected = true;
    } catch (Exception $e) {
        $connected = false;
    }

    echo json_encode([
        'status'      => $connected ? 'healthy' : 'degraded',
        'service'     => 'api-backend',
        'timestamp'   => date('c'),
        'server'      => gethostname(),
        'environment' => getenv('ENVIRONMENT') ?: 'development',
        'db_connected'=> $connected
    ]);
}

function testEndpoint() {
    echo json_encode([
        'status'   => 'success',
        'message'  => 'Backend API is working 🎉',
        'service'  => 'api-backend',
        'server'   => gethostname(),
        'timestamp'=> date('c')
    ]);
}

function testDatabaseConnection() {
    try {
        $pdo = getPDO();
        initDatabase($pdo);

        $userCount    = $pdo->query("SELECT COUNT(*) as c FROM users")->fetch()['c'];
        $productCount = $pdo->query("SELECT COUNT(*) as c FROM products")->fetch()['c'];

        echo json_encode([
            'status' => 'success',
            'message'=> 'Database connection OK',
            'server' => gethostname(),
            'database'=> [
                'name'          => getenv('DB_NAME') ?: 'appdb',
                'users_count'   => $userCount,
                'products_count'=> $productCount
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message'=> 'Database connection failed',
            'server' => gethostname()
        ]);
    }
}

function initDatabase($pdo) {
    // Create tables if not exist
    $tables = [
        "CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )",
        "CREATE TABLE IF NOT EXISTS products (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(200) NOT NULL,
            price DECIMAL(10,2) NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )",
        "CREATE TABLE IF NOT EXISTS orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            total_amount DECIMAL(10,2) NOT NULL,
            status ENUM('pending','completed','cancelled') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )"
    ];
    foreach ($tables as $sql) { $pdo->exec($sql); }

    // Seed demo data
    if ($pdo->query("SELECT COUNT(*) as c FROM users")->fetch()['c'] == 0) {
        $pdo->exec("INSERT INTO users (name,email) VALUES
            ('John Doe','john@example.com'),
            ('Jane Smith','jane@example.com')");
    }
    if ($pdo->query("SELECT COUNT(*) as c FROM products")->fetch()['c'] == 0) {
        $pdo->exec("INSERT INTO products (name,price,description) VALUES
            ('Laptop',999.99,'High-performance laptop'),
            ('Phone',499.99,'Latest smartphone')");
    }
}

function handleUsers($method) {
    $pdo = getPDO();
    if ($method === 'GET') {
        $rows = $pdo->query("SELECT * FROM users ORDER BY created_at DESC")->fetchAll();
        echo json_encode(['status'=>'success','data'=>$rows,'count'=>count($rows)]);
    } elseif ($method === 'POST') {
        $data = json_decode(file_get_contents('php://input'), true);
        if (!isset($data['name'],$data['email'])) {
            http_response_code(400);
            echo json_encode(['status'=>'error','message'=>'Name & email required']); return;
        }
        $stmt=$pdo->prepare("INSERT INTO users (name,email) VALUES (?,?)");
        $stmt->execute([$data['name'],$data['email']]);
        echo json_encode(['status'=>'success','id'=>$pdo->lastInsertId()]);
    }
}

function handleProducts($method) {
    $pdo = getPDO();
    if ($method === 'GET') {
        $rows=$pdo->query("SELECT * FROM products ORDER BY created_at DESC")->fetchAll();
        echo json_encode(['status'=>'success','data'=>$rows]);
    } elseif ($method==='POST') {
        $data=json_decode(file_get_contents('php://input'),true);
        if (!isset($data['name'],$data['price'])) {
            http_response_code(400);
            echo json_encode(['status'=>'error','message'=>'Name & price required']); return;
        }
        $stmt=$pdo->prepare("INSERT INTO products (name,price,description) VALUES (?,?,?)");
        $stmt->execute([$data['name'],$data['price'],$data['description']??null]);
        echo json_encode(['status'=>'success','id'=>$pdo->lastInsertId()]);
    }
}

function handleOrders($method) {
    $pdo = getPDO();
    if ($method === 'GET') {
        $rows=$pdo->query("
            SELECT o.*, u.name as user_name
            FROM orders o LEFT JOIN users u ON o.user_id=u.id
            ORDER BY o.created_at DESC")->fetchAll();
        echo json_encode(['status'=>'success','data'=>$rows]);
    } elseif ($method==='POST') {
        $data=json_decode(file_get_contents('php://input'),true);
        if (!isset($data['user_id'],$data['total_amount'])) {
            http_response_code(400);
            echo json_encode(['status'=>'error','message'=>'User & total required']); return;
        }
        $stmt=$pdo->prepare("INSERT INTO orders (user_id,total_amount,status) VALUES (?,?,?)");
        $stmt->execute([$data['user_id'],$data['total_amount'],$data['status']??'pending']);
        echo json_encode(['status'=>'success','id'=>$pdo->lastInsertId()]);
    }
}

function systemInfo() {
    echo json_encode([
        'system'=>[
            'server'=>gethostname(),
            'php_version'=>phpversion(),
            'environment'=>getenv('ENVIRONMENT') ?: 'development',
            'project'=>getenv('PROJECT_NAME') ?: 'three-tier-app'
        ]
    ]);
}

function defaultResponse() {
    echo json_encode([
        'message'=>'Welcome to Three-Tier API',
        'endpoints'=>[
            'GET /api/health','GET /api/test','GET /api/db-test',
            'GET/POST /api/users','GET/POST /api/products','GET/POST /api/orders',
            'GET /api/info'
        ],
        'server'=>gethostname()
    ]);
}
?>
