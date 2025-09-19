// Global configuration - will be auto-detected
let BACKEND_API_URL = '';

// DOM Ready
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

async function initializeApp() {
    console.log('Initializing Three-Tier Web Application');
    
    // Auto-detect backend API URL
    await autoDetectBackendUrl();
    
    // Set up event listeners
    document.getElementById('user-form').addEventListener('submit', handleUserSubmit);
    document.getElementById('product-form').addEventListener('submit', handleProductSubmit);
    document.getElementById('order-form').addEventListener('submit', handleOrderSubmit);
    
    // Load initial data
    checkHealth();
    loadUsersForOrderForm();
}

// Auto-detect backend API URL
async function autoDetectBackendUrl() {
    const statusElement = document.getElementById('api-config-status');
    
    // Try multiple strategies to find the backend
    const potentialUrls = [
        // Strategy 1: Same origin different port (common for dev)
        `${window.location.origin.replace(/:\d+/, ':80')}/api`,
        
        // Strategy 2: Relative path (if served from same server)
        '/api',
        
        // Strategy 3: Common backend hostnames
        'http://backend/api',
        'http://app-alb/api',
        'http://internal-app-alb/api',
    ];
    
    statusElement.innerHTML = 'Auto-detecting backend API...';
    statusElement.className = 'text-info';
    
    for (const url of potentialUrls) {
        try {
            console.log(`Testing backend URL: ${url}`);
            const response = await fetch(`${url}/health`, {
                method: 'GET',
                headers: { 'Content-Type': 'application/json' },
                signal: AbortSignal.timeout(3000) // 3 second timeout
            });
            
            if (response.ok) {
                BACKEND_API_URL = url;
                statusElement.innerHTML = `✅ Backend detected: ${url}`;
                statusElement.className = 'text-success';
                console.log(`Using backend API: ${url}`);
                return;
            }
        } catch (error) {
            console.log(`URL ${url} not available: ${error.message}`);
            // Continue to next URL
        }
    }
    
    // If no backend found, show error but continue
    statusElement.innerHTML = '⚠️ Could not auto-detect backend API. Using fallback.';
    statusElement.className = 'text-warning';
    BACKEND_API_URL = `${window.location.origin.replace(/:\d+/, ':80')}/api`;
}

// API Helper Functions
async function apiCall(endpoint, options = {}) {
    if (!BACKEND_API_URL) {
        await autoDetectBackendUrl();
    }
    
    const url = `${BACKEND_API_URL}${endpoint}`;
    
    try {
        const response = await fetch(url, {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API call failed:', error);
        
        // If API call fails, try to rediscover backend
        if (error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
            await autoDetectBackendUrl();
            // Retry the request once
            return apiCall(endpoint, options);
        }
        
        throw error;
    }
}

// Health Check
async function checkHealth() {
    try {
        const healthStatus = document.getElementById('health-status');
        healthStatus.innerHTML = 'Checking system health...';
        healthStatus.className = '';
        
        const data = await apiCall('/health');
        
        healthStatus.innerHTML = `
            <strong>Status:</strong> ${data.status.toUpperCase()} 
            | <strong>Service:</strong> ${data.service} 
            | <strong>Environment:</strong> ${data.environment} 
            | <strong>Database:</strong> ${data.db_connected ? 'Connected' : 'Disconnected'}
            | <strong>Server:</strong> ${data.server}
            | <strong>Time:</strong> ${new Date(data.timestamp).toLocaleTimeString()}
        `;
        
        healthStatus.className = data.status === 'healthy' ? 'health-ok' : 
                                data.status === 'degraded' ? 'health-warning' : 'health-error';
        
        // Update environment badge
        const envBadge = document.getElementById('environment-badge');
        envBadge.textContent = data.environment.toUpperCase();
        envBadge.className = `environment-${data.environment.toLowerCase()}`;
        
        // Update server info in footer
        document.getElementById('server-info').textContent = data.server;
        
    } catch (error) {
        document.getElementById('health-status').innerHTML = 
            `<span class="text-danger">Health check failed: ${error.message}</span>`;
        document.getElementById('health-status').className = 'health-error';
    }
}

// User Management
async function loadUsers() {
    try {
        const data = await apiCall('/users');
        const usersList = document.getElementById('users-list');
        
        if (data.data && data.data.length > 0) {
            usersList.innerHTML = data.data.map(user => `
                <div class="list-item">
                    <strong>${user.name}</strong><br>
                    <small>${user.email}</small><br>
                    <small class="text-muted">Created: ${new Date(user.created_at).toLocaleDateString()}</small>
                </div>
            `).join('');
        } else {
            usersList.innerHTML = '<p class="text-muted">No users found</p>';
        }
    } catch (error) {
        document.getElementById('users-list').innerHTML = 
            `<p class="text-danger">Error loading users: ${error.message}</p>`;
    }
}

async function handleUserSubmit(event) {
    event.preventDefault();
    
    const nameInput = document.getElementById('user-name');
    const emailInput = document.getElementById('user-email');
    
    try {
        const result = await apiCall('/users', {
            method: 'POST',
            body: JSON.stringify({
                name: nameInput.value,
                email: emailInput.value
            })
        });
        
        if (result.status === 'success') {
            alert('User added successfully!');
            nameInput.value = '';
            emailInput.value = '';
            loadUsers(); // Refresh the users list
            loadUsersForOrderForm(); // Refresh the user dropdown
        }
    } catch (error) {
        alert(`Error adding user: ${error.message}`);
    }
}

// Product Management
async function loadProducts() {
    try {
        const data = await apiCall('/products');
        const productsList = document.getElementById('products-list');
        
        if (data.data && data.data.length > 0) {
            productsList.innerHTML = data.data.map(product => `
                <div class="list-item">
                    <strong>${product.name}</strong> - $${product.price}<br>
                    <small>${product.description || 'No description'}</small>
                </div>
            `).join('');
        } else {
            productsList.innerHTML = '<p class="text-muted">No products found</p>';
        }
    } catch (error) {
        document.getElementById('products-list').innerHTML = 
            `<p class="text-danger">Error loading products: ${error.message}</p>`;
    }
}

async function handleProductSubmit(event) {
    event.preventDefault();
    
    const nameInput = document.getElementById('product-name');
    const priceInput = document.getElementById('product-price');
    const descriptionInput = document.getElementById('product-description');
    
    try {
        const result = await apiCall('/products', {
            method: 'POST',
            body: JSON.stringify({
                name: nameInput.value,
                price: parseFloat(priceInput.value),
                description: descriptionInput.value
            })
        });
        
        if (result.status === 'success') {
            alert('Product added successfully!');
            nameInput.value = '';
            priceInput.value = '';
            descriptionInput.value = '';
            loadProducts(); // Refresh the products list
        }
    } catch (error) {
        alert(`Error adding product: ${error.message}`);
    }
}

// Order Management
async function loadUsersForOrderForm() {
    try {
        const data = await apiCall('/users');
        const userSelect = document.getElementById('order-user');
        
        // Clear existing options except the first one
        while (userSelect.options.length > 1) {
            userSelect.remove(1);
        }
        
        if (data.data && data.data.length > 0) {
            data.data.forEach(user => {
                const option = document.createElement('option');
                option.value = user.id;
                option.textContent = `${user.name} (${user.email})`;
                userSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error loading users for order form:', error);
    }
}

async function loadOrders() {
    try {
        const data = await apiCall('/orders');
        const ordersList = document.getElementById('orders-list');
        
        if (data.data && data.data.length > 0) {
            ordersList.innerHTML = data.data.map(order => `
                <div class="list-item">
                    <strong>Order #${order.id}</strong><br>
                    <small>User: ${order.user_name || 'Unknown'}</small><br>
                    <small>Total: $${order.total_amount}</small><br>
                    <small>Status: <span class="badge bg-${order.status === 'completed' ? 'success' : 
                                          order.status === 'pending' ? 'warning' : 'danger'}">${order.status}</span></small><br>
                    <small class="text-muted">Created: ${new Date(order.created_at).toLocaleDateString()}</small>
                </div>
            `).join('');
        } else {
            ordersList.innerHTML = '<p class="text-muted">No orders found</p>';
        }
    } catch (error) {
        document.getElementById('orders-list').innerHTML = 
            `<p class="text-danger">Error loading orders: ${error.message}</p>`;
    }
}

async function handleOrderSubmit(event) {
    event.preventDefault();
    
    const userSelect = document.getElementById('order-user');
    const totalInput = document.getElementById('order-total');
    
    try {
        const result = await apiCall('/orders', {
            method: 'POST',
            body: JSON.stringify({
                user_id: parseInt(userSelect.value),
                total_amount: parseFloat(totalInput.value)
            })
        });
        
        if (result.status === 'success') {
            alert('Order created successfully!');
            userSelect.value = '';
            totalInput.value = '';
            loadOrders(); // Refresh the orders list
        }
    } catch (error) {
        alert(`Error creating order: ${error.message}`);
    }
}