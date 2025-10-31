// Configuration for Sortyx Frontend
const BACKEND_CONFIG = {
    // Update this with your backend API URL
    // Development: http://localhost:8000
    // Production: https://your-backend-api.com
    API_URL: 'http://localhost:8000',
    
    // WebSocket URL (auto-detected from API_URL)
    WS_URL: '',  // Will be set automatically
    
    // API endpoints
    ENDPOINTS: {
        HEALTH: '/api/health',
        DETECT_HAND: '/api/detect-hand-wrist',
        CLASSIFY: '/api/classify',
        STATS: '/api/stats',
        BINS_STATUS: '/api/bins/status',
        WS: '/ws'
    },
    
    // App settings
    SETTINGS: {
        SCAN_INTERVAL: 800,  // ms between hand detection scans
        RESULT_DISPLAY_TIME: 8000,  // ms to show classification result
        AUTO_START_DELAY: 2000,  // ms before auto-starting scanning
        ERROR_DISPLAY_TIME: 3000,  // ms to show error messages
        RESET_TIMEOUT: 8000  // ms before resetting to scanning after classification
    }
};

// Auto-detect protocol for WebSocket
if (BACKEND_CONFIG.API_URL.startsWith('https://')) {
    BACKEND_CONFIG.WS_URL = BACKEND_CONFIG.API_URL.replace('https://', 'wss://');
} else if (BACKEND_CONFIG.API_URL.startsWith('http://')) {
    BACKEND_CONFIG.WS_URL = BACKEND_CONFIG.API_URL.replace('http://', 'ws://');
}

// Helper function to build full URL
function getAPIUrl(endpoint) {
    return `${BACKEND_CONFIG.API_URL}${endpoint}`;
}

// Helper function to get WebSocket URL
function getWebSocketUrl() {
    return `${BACKEND_CONFIG.WS_URL}${BACKEND_CONFIG.ENDPOINTS.WS}`;
}

// Log configuration on load
console.log('🔧 Frontend Configuration:');
console.log('   API URL:', BACKEND_CONFIG.API_URL);
console.log('   WebSocket URL:', BACKEND_CONFIG.WS_URL);
console.log('   Scan Interval:', BACKEND_CONFIG.SETTINGS.SCAN_INTERVAL, 'ms');
