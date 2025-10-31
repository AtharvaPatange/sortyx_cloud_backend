# Sortyx Cloud Waste Classification System

A modern, scalable waste classification system with **separated frontend and backend architecture**. The backend handles all AI/ML processing, while the frontend provides a responsive web interface that can be deployed independently.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Static)                        │
│  - HTML/CSS/JavaScript                                      │
│  - WebRTC Camera Access                                     │
│  - Real-time UI Updates                                     │
│  - Deployed on: Netlify, Vercel, S3, GitHub Pages          │
└──────────────────┬──────────────────────────────────────────┘
                   │ REST API + WebSocket
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (FastAPI)                        │
│  - YOLOv8 Hand Detection                                    │
│  - Waste Classification (YOLO + Gemini AI)                  │
│  - QR Code Generation                                       │
│  - WebSocket for Real-time Updates                          │
│  - Deployed on: Heroku, AWS, Google Cloud, Azure, Render   │
└─────────────────────────────────────────────────────────────┘
```

### Key Benefits of This Architecture

✅ **Independent Deployment**: Frontend and backend can be deployed separately  
✅ **Scalability**: Scale frontend (CDN) and backend (compute) independently  
✅ **Cost Efficiency**: Serve static frontend from CDN, only pay for backend compute  
✅ **Performance**: Frontend cached globally, backend processes AI workloads  
✅ **Flexibility**: Swap backend implementations without touching frontend  

## 📁 Project Structure

```
sortyx-cloud/
├── backend/                # Backend API server
│   ├── app.py             # Main FastAPI application
│   ├── requirements.txt   # Python dependencies
│   ├── .env.example       # Environment variables template
│   ├── models/            # YOLO model files
│   └── README.md         # Backend documentation
│
├── frontend/              # Frontend web application
│   ├── index.html        # Main application file
│   ├── config.js         # Backend API configuration
│   ├── README.md         # Frontend documentation
│   └── assets/           # Static assets (optional)
│
├── README.md             # This file
└── DEPLOYMENT.md         # Deployment guide
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/sortyx-cloud.git
cd sortyx-cloud
```

### 2. Setup Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY

# Run backend server
python app.py
```

Backend will start on `http://localhost:8000`

### 3. Setup Frontend

```bash
cd frontend

# Update config.js with your backend URL
# For local development, it's already set to http://localhost:8000

# Serve frontend (choose one method)
python -m http.server 8080
# OR
npx serve
# OR
php -S localhost:8080
```

Frontend will be available at `http://localhost:8080`

### 4. Test the Application

1. Open `http://localhost:8080` in your browser
2. Allow camera access when prompted
3. Hold a waste item in your hand in front of the camera
4. The system will automatically detect your hand and classify the item
5. View the classification result and disposal instructions

## 🌐 Deployment

### Frontend Deployment Options

1. **Netlify** (Recommended - Free tier available)
2. **Vercel** (Free tier available)
3. **GitHub Pages** (Free)
4. **AWS S3 + CloudFront**
5. **Azure Static Web Apps**
6. **Google Cloud Storage + CDN**

[See frontend/README.md for detailed deployment instructions]

### Backend Deployment Options

1. **Heroku** (Simple, free tier available)
2. **Google Cloud Run** (Serverless, pay-per-use)
3. **AWS ECS/Fargate** (Scalable containers)
4. **Azure Container Instances**
5. **Render.com** (Simple, automatic deploys)
6. **DigitalOcean App Platform**

[See backend/README.md for detailed deployment instructions]

## 📋 Configuration

### Backend Configuration

Create `backend/.env`:

```bash
# Required
GEMINI_API_KEY=your_gemini_api_key_here

# Optional
PORT=8000
ENVIRONMENT=production
CORS_ORIGINS=https://your-frontend-url.com
```

### Frontend Configuration

Edit `frontend/config.js`:

```javascript
const BACKEND_CONFIG = {
    // Update with your deployed backend URL
    API_URL: 'https://your-backend-api.com',  // Production
    // API_URL: 'http://localhost:8000',  // Development
};
```

## 🔌 API Documentation

Once the backend is running, access the interactive API documentation:

- **Swagger UI**: http://localhost:8000/api/docs
- **ReDoc**: http://localhost:8000/api/redoc

### Main Endpoints

```http
GET  /api/health              # Health check
POST /api/detect-hand-wrist   # Detect hand and object
POST /api/classify            # Classify waste item
GET  /api/stats               # Get statistics
GET  /api/bins/status         # Get bin status
WS   /ws                      # WebSocket connection
```

## 🛠️ Development

### Backend Development

```bash
cd backend

# Install dev dependencies
pip install -r requirements.txt

# Run in development mode with auto-reload
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development

```bash
cd frontend

# Serve with live reload (using any static server)
python -m http.server 8080
```

### Testing

#### Test Backend API

```bash
# Health check
curl http://localhost:8000/api/health

# Test classification (requires base64 image)
curl -X POST http://localhost:8000/api/classify \
  -H "Content-Type: application/json" \
  -d '{"image_base64":"data:image/jpeg;base64,..."}'
```

#### Test Frontend

1. Open DevTools Console
2. Check for errors
3. Verify WebSocket connection
4. Test camera access
5. Test classification flow

## 📊 Features

### AI/ML Features
- ✅ **Hand Detection**: YOLOv8 Pose estimation for CPU-optimized detection
- ✅ **Object Detection**: YOLO for identifying waste items in hand
- ✅ **Waste Classification**: YOLO model + Gemini AI for accurate categorization
- ✅ **QR Code Generation**: Tracking codes for disposal compliance

### UI Features
- ✅ **Real-time Camera Feed**: WebRTC for live video
- ✅ **Auto-scanning**: Automatic hand detection and classification
- ✅ **Visual Feedback**: On-screen overlays and disposal indicators
- ✅ **Voice Announcements**: Audio guidance for disposal
- ✅ **Statistics Dashboard**: Real-time classification stats
- ✅ **Bin Level Monitoring**: Track bin fullness
- ✅ **Responsive Design**: Works on desktop and mobile

### System Features
- ✅ **WebSocket Support**: Real-time updates
- ✅ **RESTful API**: Standard HTTP endpoints
- ✅ **CORS Enabled**: Cross-origin requests supported
- ✅ **Error Handling**: Graceful fallbacks
- ✅ **Logging**: Detailed server logs

## 🔒 Security

### Backend Security
- API key management via environment variables
- CORS configuration for allowed origins
- Input validation with Pydantic models
- Rate limiting (recommended for production)

### Frontend Security
- HTTPS enforcement in production
- Content Security Policy headers
- XSS protection
- Secure WebSocket connections (WSS)

## 📈 Performance

### Backend Optimizations
- CPU-optimized YOLO models (no GPU required)
- Efficient image processing with OpenCV
- Async/await for non-blocking operations
- Model caching to avoid re-loading

### Frontend Optimizations
- Lazy loading of external resources
- Image compression for API calls
- Debounced camera scanning
- Minimal DOM manipulations

## 🐛 Troubleshooting

### Common Issues

#### Camera Not Working
- Ensure HTTPS in production (or use localhost)
- Check browser permissions
- Verify getUserMedia support

#### API Connection Failed
- Check backend is running
- Verify CORS settings
- Check API_URL in config.js
- Inspect Network tab in DevTools

#### Classification Not Working
- Verify GEMINI_API_KEY is set
- Check model files are present
- Monitor backend logs
- Ensure image is properly encoded

#### WebSocket Connection Lost
- Check backend WebSocket endpoint
- Verify WS/WSS protocol
- Check firewall settings
- Monitor browser console

See individual README files for more troubleshooting:
- [Backend Troubleshooting](backend/README.md#troubleshooting)
- [Frontend Troubleshooting](frontend/README.md#troubleshooting)

## 📝 License

MIT License - See LICENSE file for details

## 👥 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🆘 Support

- **Documentation**: See README files in `backend/` and `frontend/` directories
- **Issues**: https://github.com/yourusername/sortyx-cloud/issues
- **Email**: support@sortyx.com
- **Discord**: [Join our community](https://discord.gg/sortyx)

## 🎯 Roadmap

- [ ] Mobile app (React Native / Flutter)
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Offline mode with service workers
- [ ] User authentication and accounts
- [ ] Historical data visualization
- [ ] Integration with waste management systems
- [ ] RESTful API v2 with GraphQL support

## 🙏 Acknowledgments

- **YOLOv8** by Ultralytics
- **Google Gemini AI** for LLM classification
- **FastAPI** framework
- **OpenCV** for image processing
- Community contributors

---

Made with ♻️ by the Sortyx Team
