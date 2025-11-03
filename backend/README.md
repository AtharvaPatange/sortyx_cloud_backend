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

Choose your deployment platform:

### 🚀 Recommended: Google Cloud Run (Best Performance)

**One-command deployment:**

```bash
# Windows PowerShell
.\deploy-gcloud.ps1

# Linux/macOS
chmod +x deploy-gcloud.sh
./deploy-gcloud.sh
```

**Manual deployment:**

```bash
# Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install

# Login and set project
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Enable APIs
gcloud services enable run.googleapis.com cloudbuild.googleapis.com

# Create secret for Gemini API key
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets create GEMINI_API_KEY --data-file=-

# Deploy!
gcloud run deploy sortyx-backend \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --set-secrets GEMINI_API_KEY=GEMINI_API_KEY:latest
```

**📖 Full Guide:** See [GOOGLE_CLOUD_DEPLOY.md](./GOOGLE_CLOUD_DEPLOY.md) for complete instructions.

**⚡ Quick Reference:** See [GCLOUD_QUICKREF.md](./GCLOUD_QUICKREF.md) for common commands.

**🆚 Comparison:** See [RENDER_VS_CLOUDRUN.md](./RENDER_VS_CLOUDRUN.md) for platform comparison.

---

### 📦 Alternative: Render.com (Easiest Setup)

**Quick deployment:**

1. Connect your GitHub repository to Render
2. Create a new Web Service
3. Point to `backend` directory
4. Add environment variable: `GEMINI_API_KEY`
5. Deploy!

**Using render.yaml:**

```yaml
services:
  - type: web
    name: sortyx-backend
    runtime: python
    runtimeVersion: "3.12.7"
    buildCommand: pip install --upgrade pip && pip install -r requirements.txt
    startCommand: python app.py
    envVars:
      - key: GEMINI_API_KEY
        sync: false
      - key: PORT
        value: 8000
      - key: RENDER_FREE_TIER
        value: "true"
```

**⚠️ Note:** Render free tier has limitations:
- 512 MB RAM (tight for YOLO models)
- Sleeps after 15 minutes of inactivity
- 30-60 second cold starts

---

### 🐳 Docker Deployment (Self-Hosted)

**Build and run locally:**

```bash
# Build image
docker build -t sortyx-backend .

# Run container
docker run -p 8080:8080 \
  -e GEMINI_API_KEY=your_key_here \
  sortyx-backend
```

**Using Docker Compose:**

```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "8080:8080"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - PORT=8080
    restart: unless-stopped
```

---

### ☁️ Other Cloud Platforms

#### AWS (ECS/Fargate)
```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ECR_URL
docker build -t sortyx-backend .
docker tag sortyx-backend:latest YOUR_ECR_URL/sortyx-backend:latest
docker push YOUR_ECR_URL/sortyx-backend:latest

# Deploy to ECS (use AWS Console or CLI)
```

#### Azure Container Instances
```bash
# Build and push to ACR
az acr build --registry yourregistry --image sortyx-backend .

# Deploy
az container create \
  --resource-group yourgroup \
  --name sortyx-backend \
  --image yourregistry.azurecr.io/sortyx-backend \
  --cpu 2 --memory 4 \
  --ports 8080 \
  --environment-variables GEMINI_API_KEY=your_key
```

#### Heroku
```bash
heroku login
heroku create sortyx-backend
heroku config:set GEMINI_API_KEY=your_key
git push heroku main
```

---

### 📊 Deployment Comparison

| Platform | Setup Difficulty | Performance | Cost (Low Traffic) | Recommended For |
|----------|-----------------|-------------|-------------------|-----------------|
| **Google Cloud Run** | Medium | ⭐⭐⭐⭐⭐ | $2-5/month | **Production** |
| **Render** | Easy | ⭐⭐⭐ | Free / $7/month | **Prototypes** |
| **Docker (Self-hosted)** | Medium | ⭐⭐⭐⭐ | Server cost | **Custom Setup** |
| **AWS ECS** | Hard | ⭐⭐⭐⭐⭐ | $10+/month | **Enterprise** |
| **Heroku** | Easy | ⭐⭐⭐ | $7+/month | **Hobby Projects** |

**💡 Recommendation:** Start with **Google Cloud Run** for the best balance of performance, cost, and ease of deployment.

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
