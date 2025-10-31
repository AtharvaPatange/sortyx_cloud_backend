# Sortyx Frontend

This is the frontend web application for Sortyx Waste Classification System. It's a pure HTML/CSS/JavaScript application that communicates with the backend API.

## 🏗️ Architecture

The frontend is a **static web application** that can be:
- Served by any web server (nginx, Apache, Caddy)
- Deployed to static hosting services (Netlify, Vercel, GitHub Pages, S3)
- Served from a CDN for global distribution

### Key Features
- **Pure HTML/CSS/JavaScript** - No build process required
- **Real-time Camera Access** - WebRTC for live video feed
- **WebSocket Support** - Real-time updates from backend
- **Responsive Design** - Works on desktop and mobile devices
- **Offline-Ready** - Service worker for offline functionality (optional)

## 📁 Project Structure

```
frontend/
├── index.html          # Main application file
├── config.js           # Configuration for backend API URL
├── README.md          # This file
└── assets/            # (Optional) Static assets
    ├── images/
    ├── videos/
    └── icons/
```

## 🚀 Quick Start

### Option 1: Local Development

The easiest way to serve the frontend locally:

#### Using Python
```bash
cd frontend
python -m http.server 8080
```
Then open http://localhost:8080

#### Using Node.js
```bash
cd frontend
npx serve
```

#### Using PHP
```bash
cd frontend
php -S localhost:8080
```

### Option 2: Production Server

#### Nginx Configuration

Create `/etc/nginx/sites-available/sortyx-frontend`:

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    
    root /var/www/sortyx-frontend;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable and restart:
```bash
sudo ln -s /etc/nginx/sites-available/sortyx-frontend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Apache Configuration

Create `.htaccess`:

```apache
# Enable rewrite engine
RewriteEngine On

# Redirect to index.html for SPA
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/css application/json application/javascript text/xml application/xml
</IfModule>

# Browser caching
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
</IfModule>
```

## 🔧 Configuration

### Backend API URL

Create a `config.js` file in the frontend directory:

```javascript
// Configuration for Sortyx Frontend
const BACKEND_CONFIG = {
    // Update this with your backend API URL
    API_URL: 'http://localhost:8000',  // Development
    // API_URL: 'https://api.sortyx.com',  // Production
    
    // WebSocket URL (usually same as API_URL with ws/wss protocol)
    WS_URL: 'ws://localhost:8000',  // Development
    // WS_URL: 'wss://api.sortyx.com',  // Production
    
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
        AUTO_START_DELAY: 2000  // ms before auto-starting scanning
    }
};

// Auto-detect protocol for WebSocket
if (BACKEND_CONFIG.API_URL.startsWith('https://')) {
    BACKEND_CONFIG.WS_URL = BACKEND_CONFIG.API_URL.replace('https://', 'wss://');
} else {
    BACKEND_CONFIG.WS_URL = BACKEND_CONFIG.API_URL.replace('http://', 'ws://');
}
```

Then include it in `index.html`:

```html
<script src="config.js"></script>
```

And update all API calls in `index.html` to use the config:

```javascript
// Instead of:
fetch('/api/health')

// Use:
fetch(`${BACKEND_CONFIG.API_URL}${BACKEND_CONFIG.ENDPOINTS.HEALTH}`)
```

## 🌐 Deployment Options

### 1. Netlify

#### Method 1: Drag & Drop
1. Go to https://app.netlify.com
2. Drag your frontend folder to the upload area
3. Done! Your site is live

#### Method 2: GitHub Integration
1. Push your code to GitHub
2. Connect your repository to Netlify
3. Configure build settings:
   - Build command: (leave empty)
   - Publish directory: `frontend`
4. Add environment variables (if needed)
5. Deploy!

#### Method 3: Netlify CLI
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Deploy
cd frontend
netlify deploy --prod
```

Create `netlify.toml`:

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"

[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.css"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### 2. Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd frontend
vercel --prod
```

Create `vercel.json`:

```json
{
  "version": 2,
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        }
      ]
    }
  ]
}
```

### 3. GitHub Pages

```bash
# Enable GitHub Pages in repository settings
# Select 'main' branch and '/frontend' folder (or root if frontend is at root)
# Your site will be available at: https://username.github.io/repository-name
```

Create `.github/workflows/deploy.yml` for automatic deployment:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./frontend
```

### 4. AWS S3 + CloudFront

```bash
# Create S3 bucket
aws s3 mb s3://sortyx-frontend

# Enable static website hosting
aws s3 website s3://sortyx-frontend --index-document index.html

# Upload files
aws s3 sync frontend/ s3://sortyx-frontend/ --acl public-read

# Create CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name sortyx-frontend.s3.amazonaws.com \
  --default-root-object index.html
```

Create `deploy-s3.sh`:

```bash
#!/bin/bash

# Build (if needed)
# npm run build

# Sync to S3
aws s3 sync frontend/ s3://sortyx-frontend/ \
  --acl public-read \
  --delete \
  --cache-control max-age=31536000,public

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"

echo "Deployment complete!"
```

### 5. Azure Static Web Apps

```bash
# Install Azure CLI
az login

# Create static web app
az staticwebapp create \
  --name sortyx-frontend \
  --resource-group your-resource-group \
  --source frontend \
  --location "East US" \
  --branch main \
  --token YOUR_GITHUB_TOKEN
```

Create `staticwebapp.config.json`:

```json
{
  "navigationFallback": {
    "rewrite": "/index.html"
  },
  "routes": [
    {
      "route": "/*",
      "allowedRoles": ["anonymous"]
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html"
    }
  }
}
```

### 6. Google Cloud Storage + CDN

```bash
# Create bucket
gsutil mb gs://sortyx-frontend

# Upload files
gsutil -m rsync -r -d frontend/ gs://sortyx-frontend/

# Make public
gsutil iam ch allUsers:objectViewer gs://sortyx-frontend

# Enable website configuration
gsutil web set -m index.html gs://sortyx-frontend

# Create CDN
gcloud compute backend-buckets create sortyx-frontend-backend \
  --gcs-bucket-name=sortyx-frontend \
  --enable-cdn
```

## 🔒 Security Best Practices

### HTTPS Configuration

Always use HTTPS in production:

```javascript
// In config.js, automatically use HTTPS in production
const BACKEND_CONFIG = {
    API_URL: window.location.protocol === 'https:' 
        ? 'https://api.sortyx.com' 
        : 'http://localhost:8000'
};
```

### Content Security Policy

Add to `index.html` `<head>`:

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline' 'unsafe-eval'; 
               style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; 
               font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; 
               img-src 'self' data: blob:; 
               connect-src 'self' ws: wss: http://localhost:8000 https://api.sortyx.com;
               media-src 'self' blob:;">
```

### CORS Headers

Ensure your backend allows requests from your frontend domain:

```python
# In backend/app.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 📱 Progressive Web App (Optional)

Make your app installable:

### 1. Create `manifest.json`

```json
{
  "name": "Sortyx Waste Classifier",
  "short_name": "Sortyx",
  "description": "AI-powered waste classification system",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0f2027",
  "theme_color": "#6a11cb",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### 2. Create `service-worker.js`

```javascript
const CACHE_NAME = 'sortyx-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/config.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
```

### 3. Register Service Worker in `index.html`

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/service-worker.js')
    .then(reg => console.log('Service Worker registered'))
    .catch(err => console.error('Service Worker registration failed', err));
}
```

## 🧪 Testing

### Local Testing with Different Backends

```javascript
// In config.js
const BACKEND_CONFIG = {
    API_URL: process.env.BACKEND_URL || 'http://localhost:8000'
};
```

### Browser Compatibility Testing

Supported browsers:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Required features:
- WebRTC (getUserMedia)
- WebSocket
- ES6+ JavaScript
- Fetch API

### Mobile Testing

Use Chrome DevTools device emulation or test on real devices:
- iOS Safari
- Android Chrome
- Samsung Internet

## 📊 Performance Optimization

### Image Optimization

```javascript
// Reduce camera resolution for better performance
const constraints = {
    video: {
        width: { ideal: 1280 },  // Reduce to 640 for lower-end devices
        height: { ideal: 720 },  // Reduce to 480 for lower-end devices
        facingMode: 'environment'
    }
};
```

### Lazy Loading

```html
<link rel="preload" as="style" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700;800&display=swap">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700;800&display=swap" media="print" onload="this.media='all'">
```

### Minification (Optional)

For production, minify your HTML/CSS/JS:

```bash
# Install minifiers
npm install -g html-minifier clean-css-cli terser

# Minify HTML
html-minifier --collapse-whitespace --remove-comments index.html -o index.min.html

# Minify CSS (if extracted)
cleancss -o styles.min.css styles.css

# Minify JS (if extracted)
terser app.js -o app.min.js
```

## 🔍 Troubleshooting

### Camera Not Working

1. **Check HTTPS**: Camera requires HTTPS (except localhost)
2. **Check Permissions**: Allow camera access in browser
3. **Check Constraints**: Verify camera constraints are supported

### WebSocket Connection Failed

1. **Check Backend URL**: Ensure WS_URL is correct
2. **Check CORS**: Backend must allow WebSocket connections
3. **Check Firewall**: WebSocket port must be open

### API Calls Failing

1. **Check Backend**: Ensure backend is running
2. **Check CORS**: Backend must allow your frontend domain
3. **Check Network**: Use browser DevTools Network tab
4. **Check API URL**: Verify BACKEND_CONFIG.API_URL is correct

### Performance Issues

1. **Reduce Camera Resolution**: Lower video constraints
2. **Increase Scan Interval**: Increase SCAN_INTERVAL in config
3. **Disable Animations**: Comment out heavy CSS animations
4. **Check Backend**: Backend processing might be slow

## 📝 License

MIT License - See LICENSE file for details

## 🆘 Support

- Email: support@sortyx.com
- Issues: https://github.com/yourusername/sortyx/issues
- Documentation: https://docs.sortyx.com
