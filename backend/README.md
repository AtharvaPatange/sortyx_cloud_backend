# Sortyx Backend API Server

This is the backend API server for Sortyx Waste Classification System. It handles all AI/ML processing, including hand detection, object classification, and waste categorization.

## 🏗️ Architecture

The backend is a standalone FastAPI application that provides REST API endpoints and WebSocket support for real-time communication.

### Key Features
- **Hand/Wrist Detection**: YOLOv8 Pose estimation for CPU-optimized hand detection
- **Waste Classification**: YOLO model + Google Gemini AI for accurate classification
- **QR Code Generation**: Tracking codes for disposal compliance
- **WebSocket Support**: Real-time updates to connected clients
- **CORS Enabled**: Ready for cross-origin requests from frontend

## 📁 Project Structure

```
backend/
├── app.py              # Main FastAPI application
├── requirements.txt    # Python dependencies
├── .env.example        # Environment variables template
├── models/             # YOLO model files
│   ├── yolov8n.pt
│   ├── yolov8n-pose.pt
│   └── best.pt
└── README.md          # This file
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY
```

### 3. Add YOLO Models

Place your trained YOLO models in the `models/` directory:
- `yolov8n.pt` - Object detection model
- `yolov8n-pose.pt` - Pose estimation model for hand detection
- `best.pt` - Custom waste classification model (optional)

The application will automatically download `yolov8n.pt` and `yolov8n-pose.pt` if not found.

### 4. Run Development Server

```bash
python app.py
```

The server will start on `http://localhost:8000`

Access API documentation at:
- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

## 🔌 API Endpoints

### Health Check
```http
GET /api/health
```
Returns server status and model loading information.

### Hand Detection
```http
POST /api/detect-hand-wrist
Content-Type: application/json

{
  "image_base64": "data:image/jpeg;base64,..."
}
```
Detects hand, wrist, and objects in the image.

**Response:**
```json
{
  "hand_detected": true,
  "wrist_detected": true,
  "object_in_hand": true,
  "cropped_image": "data:image/jpeg;base64,...",
  "confidence": 0.95,
  "message": "Hand, wrist, and object detected"
}
```

### Classification
```http
POST /api/classify
Content-Type: application/json

{
  "image_base64": "data:image/jpeg;base64,...",
  "classification_method": "model"  // or "llm"
}
```

**Response:**
```json
{
  "classification": "Recyclable",
  "confidence": 0.92,
  "item_name": "Plastic Bottle",
  "bin_color": "Green",
  "qr_code": "data:image/png;base64,...",
  "explanation": "AI model: 92.0% confidence. This item can be recycled.",
  "timestamp": "2025-10-31T12:00:00",
  "processing_time": 2.3
}
```

### Get Statistics
```http
GET /api/stats
```
Returns classification statistics.

### Get Bin Status
```http
GET /api/bins/status
```
Returns current bin levels and status.

### WebSocket Connection
```
ws://localhost:8000/ws
```
Real-time updates for classifications and sensor data.

## 🔧 Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Required
GEMINI_API_KEY=your_gemini_api_key_here

# Optional
PORT=8000
ENVIRONMENT=production
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com
```

### CORS Configuration

By default, the backend accepts requests from any origin (`allow_origins=["*"]`). 

For production, update the CORS middleware in `app.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],  # Your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 🌐 Deployment

### Docker Deployment

Create a `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create models directory
RUN mkdir -p models

# Expose port
EXPOSE 8000

# Run application
CMD ["python", "app.py"]
```

Build and run:
```bash
docker build -t sortyx-backend .
docker run -p 8000:8000 -e GEMINI_API_KEY=your_key sortyx-backend
```

### Cloud Deployment

#### Heroku
```bash
# Login to Heroku
heroku login

# Create app
heroku create sortyx-backend

# Set environment variables
heroku config:set GEMINI_API_KEY=your_key

# Deploy
git push heroku main
```

#### AWS (ECS/Fargate)
1. Build Docker image
2. Push to Amazon ECR
3. Create ECS task definition
4. Deploy to Fargate cluster

#### Google Cloud Run
```bash
# Build and push
gcloud builds submit --tag gcr.io/your-project/sortyx-backend

# Deploy
gcloud run deploy sortyx-backend \
  --image gcr.io/your-project/sortyx-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=your_key
```

#### Azure Container Instances
```bash
# Build image
az acr build --registry yourregistry --image sortyx-backend .

# Deploy
az container create \
  --resource-group yourgroup \
  --name sortyx-backend \
  --image yourregistry.azurecr.io/sortyx-backend \
  --cpu 2 --memory 4 \
  --ports 8000 \
  --environment-variables GEMINI_API_KEY=your_key
```

### Render.com Deployment

Create `render.yaml`:

```yaml
services:
  - type: web
    name: sortyx-backend
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: python app.py
    envVars:
      - key: GEMINI_API_KEY
        sync: false
      - key: PORT
        value: 8000
```

## 🔍 Troubleshooting

### Common Issues

#### Models Not Loading
- Ensure models are in the `models/` directory
- Check file permissions
- Verify sufficient disk space

#### Hand Detection Not Working
- Ensure image is properly base64 encoded
- Check image quality and resolution
- Verify YOLOv8 pose model is loaded

#### Classification Errors
- Verify GEMINI_API_KEY is set correctly
- Check API quota limits
- Monitor logs for detailed error messages

#### CORS Errors from Frontend
- Update `allow_origins` in CORS middleware
- Ensure frontend URL is whitelisted
- Check that credentials are properly configured

### Debug Mode

Enable detailed logging:

```python
# In app.py, change logging level:
logging.basicConfig(level=logging.DEBUG)
```

### Performance Optimization

For production:

1. **Use Gunicorn** with multiple workers:
```bash
pip install gunicorn
gunicorn app:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

2. **Enable response compression**:
```python
from fastapi.middleware.gzip import GZipMiddleware
app.add_middleware(GZipMiddleware, minimum_size=1000)
```

3. **Add caching** for model predictions:
```python
from functools import lru_cache

@lru_cache(maxsize=100)
def cached_classification(image_hash):
    # Your classification logic
    pass
```

## 📊 Monitoring

### Health Check Endpoint

Monitor server health:
```bash
curl http://localhost:8000/api/health
```

### Logging

Logs are written to stdout. In production, use a log aggregation service:
- AWS CloudWatch
- Google Cloud Logging
- Azure Monitor
- Datadog
- Sentry (for error tracking)

## 🛡️ Security

### Best Practices

1. **API Key Security**
   - Never commit `.env` file
   - Use secrets management (AWS Secrets Manager, Azure Key Vault)
   - Rotate keys regularly

2. **Rate Limiting**
   ```python
   from slowapi import Limiter, _rate_limit_exceeded_handler
   from slowapi.util import get_remote_address
   
   limiter = Limiter(key_func=get_remote_address)
   app.state.limiter = limiter
   
   @app.post("/api/classify")
   @limiter.limit("10/minute")
   async def classify_waste(request: Request):
       # ...
   ```

3. **Input Validation**
   - Already using Pydantic models
   - Validate image size and format
   - Sanitize all user inputs

4. **HTTPS Only in Production**
   - Use reverse proxy (nginx, Caddy)
   - Enable SSL/TLS certificates
   - Redirect HTTP to HTTPS

## 📈 Scaling

### Horizontal Scaling

Deploy multiple instances behind a load balancer:

```bash
# Using Docker Compose
docker-compose up --scale backend=3
```

### Vertical Scaling

Increase resources for better performance:
- CPU: 2-4 cores recommended
- Memory: 4-8 GB recommended
- GPU: Optional, but increases speed significantly

### Database Integration

For production, add database support:

```python
from sqlalchemy import create_engine
from databases import Database

DATABASE_URL = os.getenv("DATABASE_URL")
database = Database(DATABASE_URL)

@app.on_event("startup")
async def startup():
    await database.connect()

@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()
```

## 📝 License

MIT License - See LICENSE file for details

## 🆘 Support

- Email: support@sortyx.com
- Issues: https://github.com/yourusername/sortyx/issues
- Documentation: https://docs.sortyx.com
