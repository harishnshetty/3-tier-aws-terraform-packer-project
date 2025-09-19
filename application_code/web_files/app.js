// Global configuration
let BACKEND_API_URL = '';
let CONFIG_LOADED = false;

// DOM Ready
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

async function initializeApp() {
    console.log('Initializing Three-Tier Web Application');
    
    // Load configuration first
    await loadConfiguration();
    
    // Auto-detect backend API URL
    await autoDetectBackendUrl();
    
    // Set up event listeners
    document.getElementById('user-form').addEventListener('submit', handleUserSubmit);
    document.getElementById('product-form').addEventListener('submit', handleProductSubmit);
    document.getElementById('order-form').addEventListener('submit', handleOrderSubmit);
    
    // Load initial data
    checkHealth();
    loadUsers();
    loadProducts();
    loadOrders();
    loadUsersForOrderForm();
}

// Load configuration from multiple sources
async function loadConfiguration() {
    // Try to load from config.js first
    if (window.APP_CONFIG && window.APP_CONFIG.API_BASE_URL) {
        BACKEND_API_URL = window.APP_CONFIG.API_BASE_URL;
        CONFIG_LOADED = true;
        console.log('Configuration loaded from config.js:', BACKEND_API_URL);
        return;
    }
    
    // Try to load from meta tag
    const metaTag = document.querySelector('meta[name="backend-api-url"]');
    if (metaTag && metaTag.content && metaTag.content !== 'http://APP_ALB_DNS_PLACEHOLDER/api') {
        BACKEND_API_URL = metaTag.content;
        CONFIG_LOADED = true;
        console.log('Configuration loaded from meta tag:', BACKEND_API_URL);
        return;
    }
    
    // Try to load from env-config endpoint
    try {
        const response = await fetch('/env-config');
        if (response.ok) {
            const config = await response.json();
            if (config.backendUrl) {
                BACKEND_API_URL = config.backendUrl;
                CONFIG_LOADED = true;
                console.log('Configuration loaded from env-config:', BACKEND_API_URL);
                return;
            }
        }
    } catch (error) {
        console.log('Could not load configuration from env-config:', error.message);
    }
    
    console.log('No pre-configured backend URL found, will use auto-discovery');
}

// Enhanced auto-detection with multiple strategies
async function autoDetectBackendUrl() {
    const statusElement = document.getElementById('api-config-status');
    
    // If we already have a configured URL, use it
    if (CONFIG_LOADED && BACKEND_API_URL) {
        statusElement.innerHTML = `✅ Using configured backend: ${BACKEND_API_URL}`;
        statusElement.className = 'text-success';
        console.log(`Using configured backend API: ${BACKEND_API_URL}`);
        return;
    }
    
    statusElement.innerHTML = 'Auto-detecting backend API...';
    statusElement.className = 'text-info';
    
    // Try different discovery strategies
    const discoveryStrategies = [
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

// Strategy 1: Try common health endpoints
async function discoverFromHealthEndpoint() {
    const testUrls = [
        // Same server different path (common in dev)
        `${window.location.origin}/api`,
        
        // Same domain different port (common pattern)
        `${window.location.origin.replace(/:\d+/, ':80')}/api`,
        `${window.location.origin.replace(/:\d+/, ':8080')}/api`,
        
        // Common internal ALB patterns
        `http://internal-${window.location.hostname}/api`,
        `http://app.${window.location.hostname}/api`,
        `http://api.${window.location.hostname}/api`,
        `http://backend.${window.location.hostname}/api`,
        
        // AWS ALB common patterns
        `http://${window.location.hostname.replace('web-', 'app-')}/api`,
        `http://${window.location.hostname.replace('frontend-', 'backend-')}/api`,
    ];
    
    for (const url of testUrls) {
        try {
            console.log(`Testing health endpoint: ${url}/health`);
            const response = await fetch(`${url}/health`, {
                method: 'GET',
                signal: AbortSignal.timeout(3000)
            });
            
            if (response.ok) {
                const data = await response.json();
                if (data.service === 'api-backend') {
                    return url;
                }
            }
        } catch (error) {
            // Continue to next URL
            console.log(`Health check failed for ${url}: ${error.message}`);
        }
    }
    
    return null;
}

// Strategy 2: Try common backend URL patterns
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
    ];
    
    for (const pattern of commonPatterns) {
        try {
            const testUrl = `${pattern}/health`;
            console.log(`Testing pattern: ${testUrl}`);
            const response = await fetch(testUrl, {
                method: 'GET',
                signal: AbortSignal.timeout(3000)
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

// Strategy 3: Try to discover from environment
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
        return 'http://localhost/api';
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
            
            // Default options
            const fetchOptions = {
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                mode: 'cors',
                credentials: 'omit',
                ...options
            };
            
            // For non-GET requests, ensure we have a body
            if (options.method && options.method !== 'GET' && options.body) {
                fetchOptions.body = JSON.stringify(options.body);
            }
            
            const response = await fetch(url, fetchOptions);
            
            // Check if response is JSON
            const contentType = response.headers.get('content-type');
            let data;
            
            if (contentType && contentType.includes('application/json')) {
                data = await response.json();
            } else {
                const text = await response.text();
                console.warn(`Non-JSON response from ${url}:`, text);
                
                // Try to parse as JSON anyway (some APIs don't set proper content-type)
                try {
                    data = JSON.parse(text);
                } catch (parseError) {
                    throw new Error(`Expected JSON but got ${contentType}: ${text.substring(0, 100)}`);
                }
            }
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}, message: ${data.message || 'Unknown error'}`);
            }
            
            return data;
            
        } catch (error) {
            console.error(`API call failed (attempt ${attempt}):`, error);
            
            // If it's a CORS error, we need to handle it differently
            if (error.message.includes('CORS') || error.message.includes('NetworkError') || error.message.includes('Failed to fetch')) {
                console.error('Network error detected. Trying without CORS mode.');
                
                // Try without CORS mode
                try {
                    const simpleUrl = `${BACKEND_API_URL}${endpoint}`;
                    const simpleResponse = await fetch(simpleUrl, { 
                        method: 'GET',
                        mode: 'no-cors'
                    });
                    console.log('Simple fetch response:', simpleResponse);
                } catch (simpleError) {
                    console.error('Simple fetch also failed:', simpleError);
                }
            }
            
            if (attempt === maxRetries) {
                throw new Error(`Failed after ${maxRetries} attempts: ${error.message}`);
            }
            
            // Wait before retrying
            await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
        }
    }
}

// Enhanced error display
function showError(context, error) {
    const errorElement = document.getElementById(`${context}-error`) || 
                         document.getElementById(`${context}-list`) || 
                         document.getElementById('health-status');
    
    let errorMessage = error.message;
    
    // Provide more user-friendly error messages
    if (error.message.includes('CORS') || error.message.includes('NetworkError') || error.message.includes('Failed to fetch')) {
        errorMessage = 'Connection error. Please check if the backend server is running and accessible.';
    }
    
    if (errorElement) {
        errorElement.innerHTML = `
            <div class="alert alert-danger">
                <strong>Error loading ${context}:</strong> ${errorMessage}
                <br><small>URL: ${BACKEND_API_URL}/${context.toLowerCase()}</small>
                <br><small>Check browser console for details</small>
            </div>
        `;
    }
    
    console.error(`Error in ${context}:`, error);
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
        if (envBadge) {
            envBadge.textContent = data.environment.toUpperCase();
            envBadge.className = `environment-${data.environment.toLowerCase()}`;
        }
        
        // Update server info in footer
        const serverInfo = document.getElementById('server-info');
        if (serverInfo) {
            serverInfo.textContent = data.server;
        }
        
    } catch (error) {
        const healthStatus = document.getElementById('health-status');
        healthStatus.innerHTML = `
            <span class="text-danger">
                Health check failed: ${error.message}<br>
                <small>Backend API: ${BACKEND_API_URL || 'Not discovered'}</small>
            </span>
        `;
        healthStatus.className = 'health-error';
        showError('health', error);
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
        showError('users', error);
    }
}

async function handleUserSubmit(event) {
    event.preventDefault();
    
    const nameInput = document.getElementById('user-name');
    const emailInput = document.getElementById('user-email');
    
    try {
        const result = await apiCall('/users', {
            method: 'POST',
            body: {
                name: nameInput.value,
                email: emailInput.value
            }
        });
        
        if (result.status === 'success') {
            alert('User added successfully!');
            nameInput.value = '';
            emailInput.value = '';
            loadUsers();
            loadUsersForOrderForm();
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
        showError('products', error);
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
            body: {
                name: nameInput.value,
                price: parseFloat(priceInput.value),
                description: descriptionInput.value
            }
        });
        
        if (result.status === 'success') {
            alert('Product added successfully!');
            nameInput.value = '';
            priceInput.value = '';
            descriptionInput.value = '';
            loadProducts();
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
        
        if (userSelect) {
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
        showError('orders', error);
    }
}

async function handleOrderSubmit(event) {
    event.preventDefault();
    
    const userSelect = document.getElementById('order-user');
    const totalInput = document.getElementById('order-total');
    const statusSelect = document.getElementById('order-status');
    
    try {
        const result = await apiCall('/orders', {
            method: 'POST',
            body: {
                user_id: parseInt(userSelect.value),
                total_amount: parseFloat(totalInput.value),
                status: statusSelect.value
            }
        });
        
        if (result.status === 'success') {
            alert('Order created successfully!');
            userSelect.value = '';
            totalInput.value = '';
            statusSelect.value = 'pending';
            loadOrders();
        }
    } catch (error) {
        alert(`Error creating order: ${error.message}`);
    }
}

// Debug function to test backend connectivity
async function testBackendConnectivity() {
    console.log('Testing backend connectivity...');
    
    try {
        // Test basic connectivity
        const response = await fetch(`${BACKEND_API_URL}/health`, {
            method: 'GET',
            mode: 'cors',
            credentials: 'omit'
        });
        
        console.log('Health check response:', response.status, response.statusText);
        
        if (response.ok) {
            const data = await response.json();
            console.log('Health data:', data);
        }
        
        return true;
    } catch (error) {
        console.error('Backend connectivity test failed:', error);
        return false;
    }
}