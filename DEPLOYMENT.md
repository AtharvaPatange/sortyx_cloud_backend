# Sortyx CloudApp - Deployment Guide

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Docker (optional, for containerized deployment)
- Git
- Gemini API Key

### Local Development Setup

1. **Clone the repository**
```bash
git clone <your-stash-repo-url>
cd CloudApp
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment**
```bash
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY
```

5. **Run the application**
```bash
python app.py
# Or: uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

6. **Access the application**
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health

---

## 🐳 Docker Deployment

### Build and run with Docker Compose

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Manual Docker build

```bash
# Build image
docker build -t sortyx-cloudapp:latest .

# Run container
docker run -d \
  -p 8000:8000 \
  -e GEMINI_API_KEY=your_key_here \
  -v $(pwd)/models:/app/models \
  -v $(pwd)/uploads:/app/uploads \
  --name sortyx-cloudapp \
  sortyx-cloudapp:latest
```

---

## ☁️ Cloud Deployment

### AWS ECS / Fargate

1. Build and push to ECR:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-ecr-url>
docker build -t sortyx-cloudapp .
docker tag sortyx-cloudapp:latest <your-ecr-url>/sortyx-cloudapp:latest
docker push <your-ecr-url>/sortyx-cloudapp:latest
```

2. Create ECS task definition with:
   - Container port: 8000
   - Environment variable: GEMINI_API_KEY
   - Health check: /health endpoint

### Google Cloud Run

```bash
gcloud builds submit --tag gcr.io/PROJECT_ID/sortyx-cloudapp
gcloud run deploy sortyx-cloudapp \
  --image gcr.io/PROJECT_ID/sortyx-cloudapp \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=your_key_here
```

### Azure Container Instances

```bash
az container create \
  --resource-group myResourceGroup \
  --name sortyx-cloudapp \
  --image sortyx-cloudapp:latest \
  --dns-name-label sortyx-cloudapp \
  --ports 8000 \
  --environment-variables GEMINI_API_KEY=your_key_here
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| GEMINI_API_KEY | Yes | - | Google Gemini API key for AI classification |
| DEBUG | No | True | Enable debug mode |
| HOST | No | 0.0.0.0 | Server host |
| PORT | No | 8000 | Server port |
| MAX_FILE_SIZE | No | 10485760 | Max upload size (bytes) |
| UPLOAD_FOLDER | No | ./static/uploads | Upload directory |

### Models

The application requires these YOLO models:
- `yolov8n.pt` - Object detection
- `yolov8n-pose.pt` - Hand/wrist detection
- `best.pt` (optional) - Custom classification model

Models are auto-downloaded on first run or place them in `models/` directory.

---

## 📊 Monitoring & Health Checks

### Health Check Endpoint
```bash
curl http://localhost:8000/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-25T10:00:00",
  "models_loaded": {
    "yolo_detection": true,
    "yolo_pose": true,
    "yolo_classification": false,
    "gemini_configured": true
  },
  "hand_detection": "YOLOv8 Pose (CPU-optimized, no MediaPipe)"
}
```

### Key Metrics to Monitor
- Response time for `/classify` endpoint
- Model loading status
- Memory usage (models can use 500MB-1GB)
- CPU usage during inference

---

## 🔒 Security Considerations

1. **API Key Management**: Never commit `.env` file with real API keys
2. **CORS**: Configure `CORS_ORIGINS` for production
3. **Rate Limiting**: Add rate limiting for public APIs
4. **File Upload**: Validate file types and sizes
5. **HTTPS**: Use SSL/TLS in production

---

## 🐛 Troubleshooting

### Models not loading
```bash
# Manually download models
python -c "from ultralytics import YOLO; YOLO('yolov8n.pt'); YOLO('yolov8n-pose.pt')"
```

### Port already in use
```bash
# Find process using port 8000
lsof -i :8000
# Kill process
kill -9 <PID>
```

### Memory issues
- Reduce model size (use nano models)
- Increase container memory limits
- Use CPU-only mode (already configured)

---

## 📝 API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

Key endpoints:
- `POST /detect-hand-wrist` - Detect hand and object
- `POST /classify` - Classify waste item
- `GET /health` - Health check
- `GET /stats` - Get statistics
- `WS /ws` - WebSocket for real-time updates

---

## 📞 Support

For issues or questions:
- Check logs: `docker-compose logs -f`
- Review health endpoint: `/health`
- Check system requirements
