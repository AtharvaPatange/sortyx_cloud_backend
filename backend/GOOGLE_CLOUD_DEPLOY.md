# 🚀 Google Cloud Run Deployment Guide

Complete guide to deploying the Sortyx Backend API to Google Cloud Run.

## 📋 Prerequisites

1. **Google Cloud Account** with billing enabled
2. **Google Cloud SDK (gcloud)** installed
   - Download: https://cloud.google.com/sdk/docs/install
   - Verify: `gcloud --version`

3. **Docker** installed (for local testing)
   - Download: https://docs.docker.com/get-docker/

---

## 🔧 Initial Setup (One-Time)

### 1. Install Google Cloud SDK

**Windows (PowerShell):**
```powershell
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe
```

**macOS:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 2. Initialize gcloud & Login

```bash
# Login to your Google Cloud account
gcloud auth login

# Set your project (create one if needed)
gcloud projects create sortyx-backend-prod --name="Sortyx Backend"
gcloud config set project sortyx-backend-prod

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### 3. Set Up Secrets (Gemini API Key)

```bash
# Create secret for Gemini API key
echo -n "YOUR_GEMINI_API_KEY_HERE" | gcloud secrets create GEMINI_API_KEY --data-file=-

# Grant Cloud Run access to the secret
gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
  --member="serviceAccount:YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# To find your project number:
gcloud projects describe sortyx-backend-prod --format="value(projectNumber)"
```

---

## 🚀 Deployment Methods

### **Method 1: Quick Deploy (Recommended for First Time)**

Deploy directly from your local machine:

```bash
# Navigate to backend directory
cd "d:\cloud bin\cloud-sbin-app\backend"

# Deploy to Cloud Run (one command!)
gcloud run deploy sortyx-backend \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0 \
  --port 8080 \
  --set-env-vars ENVIRONMENT=production,PORT=8080 \
  --set-secrets GEMINI_API_KEY=GEMINI_API_KEY:latest
```

**What happens:**
- Cloud Build automatically detects the Dockerfile
- Builds the container image
- Pushes to Google Container Registry
- Deploys to Cloud Run
- Returns a public URL like: `https://sortyx-backend-xxxxxxxxx-uc.a.run.app`

---

### **Method 2: Build Locally & Deploy**

For faster iterations or testing:

```bash
# Navigate to backend directory
cd "d:\cloud bin\cloud-sbin-app\backend"

# Build Docker image locally
docker build -t gcr.io/sortyx-backend-prod/sortyx-backend:latest .

# Test locally (optional)
docker run -p 8080:8080 \
  -e GEMINI_API_KEY="your_key_here" \
  gcr.io/sortyx-backend-prod/sortyx-backend:latest

# Push to Google Container Registry
docker push gcr.io/sortyx-backend-prod/sortyx-backend:latest

# Deploy to Cloud Run
gcloud run deploy sortyx-backend \
  --image gcr.io/sortyx-backend-prod/sortyx-backend:latest \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0 \
  --port 8080 \
  --set-env-vars ENVIRONMENT=production,PORT=8080 \
  --set-secrets GEMINI_API_KEY=GEMINI_API_KEY:latest
```

---

### **Method 3: Automated CI/CD with Cloud Build**

Set up automatic deployments on git push:

#### Step 1: Connect Your Repository

```bash
# Connect GitHub repository (one-time)
gcloud beta builds triggers create github \
  --repo-name=sortyx_cloud_backend \
  --repo-owner=AtharvaPatange \
  --branch-pattern="^main$" \
  --build-config=backend/cloudbuild.yaml
```

#### Step 2: Push to Deploy

```bash
# Now every push to main branch auto-deploys
cd "d:\cloud bin\cloud-sbin-app\backend"
git add .
git commit -m "Deploy to Cloud Run"
git push origin main
```

**Monitor builds:**
```bash
gcloud builds list --limit 5
gcloud builds log <BUILD_ID>
```

---

## 🔍 Verify Deployment

### 1. Get Service URL

```bash
gcloud run services describe sortyx-backend \
  --region us-central1 \
  --format="value(status.url)"
```

### 2. Test Health Endpoint

```bash
# Replace with your actual service URL
curl https://sortyx-backend-xxxxxxxxx-uc.a.run.app/api/health
```

Expected response:
```json
{
  "status": "ready",
  "timestamp": "2025-11-03T...",
  "models_loaded": {
    "yolo_detection": true,
    "yolo_pose": true,
    "yolo_classification": false,
    "gemini_configured": true
  },
  "ready": true,
  "hand_detection": "YOLOv8 Pose (CPU-optimized)"
}
```

### 3. Test API Endpoints

```bash
# Test hand detection (use your actual base64 image)
curl -X POST https://sortyx-backend-xxxxxxxxx-uc.a.run.app/api/detect-hand-wrist \
  -H "Content-Type: application/json" \
  -d '{"image_base64": "data:image/jpeg;base64,..."}'
```

---

## 🌍 Update Frontend Config

Once deployed, update your frontend `config.js`:

```javascript
const CONFIG = {
    API_URL: 'https://sortyx-backend-xxxxxxxxx-uc.a.run.app',  // Your Cloud Run URL
    WS_URL: 'wss://sortyx-backend-xxxxxxxxx-uc.a.run.app/ws'
};
```

---

## 📊 Monitoring & Logs

### View Logs

```bash
# Stream live logs
gcloud run services logs tail sortyx-backend --region us-central1

# View recent logs
gcloud run services logs read sortyx-backend --region us-central1 --limit 50
```

### View Metrics (Cloud Console)

1. Go to: https://console.cloud.google.com/run
2. Click on `sortyx-backend`
3. View metrics: requests, latency, CPU, memory

---

## 💰 Cost Optimization

Cloud Run pricing (as of 2025):
- **Free tier**: 2 million requests/month, 360,000 GB-seconds, 180,000 vCPU-seconds
- **Paid**: ~$0.00002400/request + compute time

**Tips to reduce costs:**
1. **Scale to zero**: Set `--min-instances 0` (already configured)
2. **Right-size resources**: Start with 2Gi memory, adjust if needed
3. **Use free tier**: Stay under 2M requests/month
4. **Set max instances**: Prevent runaway costs with `--max-instances 10`

**Check current costs:**
```bash
# View billing
gcloud beta billing accounts list
```

---

## 🔒 Security Best Practices

### 1. Restrict CORS Origins

Update `app.py` environment variable on Cloud Run:

```bash
gcloud run services update sortyx-backend \
  --region us-central1 \
  --set-env-vars ALLOWED_ORIGINS="https://yourdomain.com,http://localhost:8080"
```

### 2. Enable Identity-Aware Proxy (Optional)

For private API access:

```bash
gcloud run services update sortyx-backend \
  --region us-central1 \
  --no-allow-unauthenticated
```

### 3. Set Up Custom Domain

```bash
# Map custom domain
gcloud run domain-mappings create \
  --service sortyx-backend \
  --domain api.yourdomain.com \
  --region us-central1
```

---

## 🛠️ Maintenance & Updates

### Update Deployment

```bash
# Quick redeploy (rebuilds from source)
gcloud run deploy sortyx-backend --source . --region us-central1

# Or push to git if CI/CD is set up
git push origin main
```

### Update Environment Variables

```bash
gcloud run services update sortyx-backend \
  --region us-central1 \
  --set-env-vars NEW_VAR=value
```

### Update Secrets

```bash
# Update Gemini API key
echo -n "NEW_API_KEY" | gcloud secrets versions add GEMINI_API_KEY --data-file=-
```

### Scale Resources

```bash
# Increase memory for larger models
gcloud run services update sortyx-backend \
  --region us-central1 \
  --memory 4Gi \
  --cpu 4
```

---

## 🐛 Troubleshooting

### Issue: "Service not ready" / 502 errors

**Cause**: Cold start takes time to download YOLO models

**Solution 1**: Keep service warm with scheduled pings
```bash
# Set minimum instances to 1 (small cost increase)
gcloud run services update sortyx-backend \
  --region us-central1 \
  --min-instances 1
```

**Solution 2**: Use Cloud Scheduler to ping every 5 minutes
```bash
gcloud scheduler jobs create http keep-warm \
  --schedule="*/5 * * * *" \
  --uri="https://sortyx-backend-xxxxxxxxx-uc.a.run.app/api/health" \
  --http-method=GET
```

### Issue: "Out of memory" errors

**Solution**: Increase memory allocation
```bash
gcloud run services update sortyx-backend \
  --region us-central1 \
  --memory 4Gi
```

### Issue: "Request timeout"

**Solution**: Increase timeout (max 3600s)
```bash
gcloud run services update sortyx-backend \
  --region us-central1 \
  --timeout 600
```

### Issue: "Permission denied" for secrets

**Solution**: Grant secret access
```bash
PROJECT_NUMBER=$(gcloud projects describe sortyx-backend-prod --format="value(projectNumber)")

gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

---

## 📚 Additional Resources

- **Cloud Run Documentation**: https://cloud.google.com/run/docs
- **Cloud Build Documentation**: https://cloud.google.com/build/docs
- **Pricing Calculator**: https://cloud.google.com/products/calculator
- **Quotas & Limits**: https://cloud.google.com/run/quotas

---

## 🎯 Quick Command Reference

```bash
# Deploy
gcloud run deploy sortyx-backend --source . --region us-central1

# View logs
gcloud run services logs tail sortyx-backend --region us-central1

# Get URL
gcloud run services describe sortyx-backend --region us-central1 --format="value(status.url)"

# Update env vars
gcloud run services update sortyx-backend --region us-central1 --set-env-vars KEY=value

# Update secrets
echo -n "NEW_SECRET" | gcloud secrets versions add SECRET_NAME --data-file=-

# Delete service
gcloud run services delete sortyx-backend --region us-central1
```

---

## ✅ Deployment Checklist

- [ ] Install Google Cloud SDK
- [ ] Login: `gcloud auth login`
- [ ] Create/set project: `gcloud config set project PROJECT_ID`
- [ ] Enable APIs: `gcloud services enable run.googleapis.com cloudbuild.googleapis.com`
- [ ] Create secret: `gcloud secrets create GEMINI_API_KEY`
- [ ] Deploy: `gcloud run deploy sortyx-backend --source .`
- [ ] Test: `curl https://YOUR_URL/api/health`
- [ ] Update frontend: Set API_URL in `config.js`
- [ ] Set up monitoring: View logs and metrics
- [ ] (Optional) Set up CI/CD: Connect GitHub repo

---

**🎉 You're all set! Your backend is now running on Google Cloud Run!**

For issues or questions, check the troubleshooting section above or view logs:
```bash
gcloud run services logs tail sortyx-backend --region us-central1
```
