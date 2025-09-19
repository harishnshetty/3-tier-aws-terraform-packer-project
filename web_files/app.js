// Global configuration
let BACKEND_API_URL = '';
let API_DISCOVERY_ATTEMPTS = 0;
const MAX_DISCOVERY_ATTEMPTS = 3;

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

// Enhanced auto-detection with multiple strategies
async function autoDetectBackendUrl() {
    const statusElement = document.getElementById('api-config-status');
    statusElement.innerHTML = 'Auto-detecting backend API...';
    statusElement.className = 'text-info';
    
    // Get current host information
    const currentHost = window.location.hostname;
    const currentProtocol = window.location.protocol;
    
    // Try different discovery strategies
    const discoveryStrategies = [
        discoverFromMetaTags,
        discoverFromHealthEndpoint,
        discoverFromCommonPatterns,
        discoverFromEnvironment
    ];
    
    for (const strategy of discoveryStrategies) {
        const url = await strategy();
        if (url) {
            BACKEND_API_URL = url;
            statusElement.innerHTML = `✅ Backend detected: ${url}`;
            statusElement.className = 'text-success';
            console.log(`Using backend API: ${url}`);
            return;
        }
    }
    
    // If all strategies fail, use intelligent fallback
    const fallbackUrl = getIntelligentFallback();
    BACKEND_API_URL = fallbackUrl;
    statusElement.innerHTML = `⚠️ Using fallback: ${fallbackUrl}`;
    statusElement.className = 'text-warning';
    console.log(`Using fallback API: ${fallbackUrl}`);
}

// Strategy 1: Check for meta tags or configuration in HTML
async function discoverFromMetaTags() {
    // Check for meta tag with backend URL
    const metaTag = document.querySelector('meta[name="backend-api-url"]');
    if (metaTag) {
        return metaTag.getAttribute('content');
    }
    
    // Check for global config variable
    if (window.APP_CONFIG && window.APP_CONFIG.API_BASE_URL) {
        return window.APP_CONFIG.API_BASE_URL + '/api';
    }
    
    return null;
}

// Strategy 2: Try common health endpoints
async function discoverFromHealthEndpoint() {
    const testUrls = [
        // Same server different path (common in dev)
        `${window.location.origin}/api/health`,
        
        // Same domain different port (common pattern)
        `${window.location.origin.replace(/:\d+/, ':80')}/api/health`,
        `${window.location.origin.replace(/:\d+/, ':8080')}/api/health`,
        
        // Common internal ALB patterns
        `http://internal-${window.location.hostname}/api/health`,
        `http://app.${window.location.hostname}/api/health`,
        `http://api.${window.location.hostname}/api/health`,
        `http://backend.${window.location.hostname}/api/health`,
        
        // AWS ALB common patterns
        `http://${window.location.hostname.replace('web-', 'app-')}/api/health`,
        `http://${window.location.hostname.replace('frontend-', 'backend-')}/api/health`,
    ];
    
    for (const url of testUrls) {
        try {
            console.log(`Testing health endpoint: ${url}`);
            const response = await fetch(url, {
                method: 'GET',
                signal: AbortSignal.timeout(2000)
            });
            
            if (response.ok) {
                const data = await response.json();
                if (data.service === 'api-backend') {
                    return url.replace('/health', '');
                }
            }
        } catch (error) {
            // Continue to next URL
            console.log(`Health check failed for ${url}: ${error.message}`);
        }
    }
    
    return null;
}

// Strategy 3: Try common backend URL patterns
async function discoverFromCommonPatterns() {
    const commonPatterns = [
        // Relative path (if served from same server)
        '/api',
        
        // Common backend hostnames
        'http://backend/api',
        'http://app-alb/api',
        'http://internal-app-alb/api',
        'http://app.internal/api',
        'http://api.internal/api',
        
        // AWS-specific patterns
        'http://app-alb-123456789.ap-south-1.elb.amazonaws.com/api',
    ];
    
    for (const pattern of commonPatterns) {
        try {
            const testUrl = `${pattern}/health`;
            console.log(`Testing pattern: ${testUrl}`);
            const response = await fetch(testUrl, {
                method: 'GET',
                signal: AbortSignal.timeout(2000)
            });
            
            if (response.ok) {
                const data = await response.json();
                if (data.service === 'api-backend') {
                    return pattern;
                }
            }
        } catch (error) {
            // Continue to next pattern
            console.log(`Pattern ${pattern} failed: ${error.message}`);
        }
    }
    
    return null;
}

// Strategy 4: Try to discover from environment
async function discoverFromEnvironment() {
    // Try to get backend URL from server-side environment
    try {
        const response = await fetch('/env-config');
        if (response.ok) {
            const config = await response.json();
            if (config.backendUrl) {
                return config.backendUrl;
            }
        }
    } catch (error) {
        // Ignore, this is optional
    }
    
    return null;
}

// Intelligent fallback based on current environment
function getIntelligentFallback() {
    const hostname = window.location.hostname;
    
    // Local development
    if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '') {
        return 'http://localhost:80/api';
    }
    
    // AWS ALB pattern detection
    if (hostname.includes('elb.amazonaws.com')) {
        // Replace web with app in ALB hostname
        return hostname.replace('web', 'app').replace('frontend', 'backend') + '/api';
    }
    
    // Default fallback
    return `${window.location.origin}/api`;
}

// Enhanced API call with retry and discovery
async function apiCall(endpoint, options = {}) {
    const maxRetries = 2;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            if (!BACKEND_API_URL) {
                await autoDetectBackendUrl();
            }
            
            const url = `${BACKEND_API_URL}${endpoint}`;
            console.log(`API Call (attempt ${attempt}): ${url}`);
            
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
            console.error(`API call failed (attempt ${attempt}):`, error);
            
            if (attempt === maxRetries) {
                // Last attempt failed, try to rediscover backend
                BACKEND_API_URL = ''; // Reset to force rediscovery
                if (API_DISCOVERY_ATTEMPTS < MAX_DISCOVERY_ATTEMPTS) {
                    API_DISCOVERY_ATTEMPTS++;
                    await autoDetectBackendUrl();
                    // Retry the request
                    continue;
                }
                throw error;
            }
            
            // Wait before retrying
            await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
        }
    }
}

// Health Check with better error handling
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
        const healthStatus = document.getElementById('health-status');
        healthStatus.innerHTML = `
            <span class="text-danger">
                Health check failed: ${error.message}<br>
                <small>Backend API: ${BACKEND_API_URL || 'Not discovered'}</small>
            </span>
        `;
        healthStatus.className = 'health-error';
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