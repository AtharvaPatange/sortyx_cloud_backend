# 🚀 Vertex AI Backend Deployment Guide

## Overview

This guide helps you deploy the **GPU-optimized Vertex AI backend** to Google Cloud Run as a separate service (`sortyx-backend-vertex`) alongside your existing Gemini API backend (`sortyx-backend`).

### Performance Comparison

| Feature | Gemini API Backend | Vertex AI Backend |
|---------|-------------------|-------------------|
| **Service Name** | `sortyx-backend` | `sortyx-backend-vertex` |
| **AI Provider** | Gemini API (external) | Vertex AI (internal GCP) |
| **Authentication** | API Key | IAM (automatic) |
| **Response Time** | 2-5 seconds | 0.5-2 seconds |
| **Performance** | Baseline | **60-70% faster** |
| **Quota (RPM)** | 60 | 300+ |
| **Network** | Internet roundtrip | Internal GCP network |
| **Memory** | 2Gi | 4Gi |
| **CPU** | 2 cores | 4 cores |
| **GPU Ready** | ❌ CPU-only | ✅ GPU-optimized |

---

## 📋 Prerequisites

### 1. Files Required
Ensure these files exist in your `backend/` directory:
```
backend/
├── vertex.py                     # GPU-optimized backend code
├── requirements-vertex.txt       # Vertex AI dependencies
├── Dockerfile.vertex            # Optimized Dockerfile
├── deploy-vertex.ps1            # Deployment script
└── models/ (optional)           # YOLO models (auto-downloaded if missing)
```

### 2. Google Cloud Setup
- ✅ GCP Project: **sortyx** (ID: `sortyx`)
- ✅ Project Number: `168152601641`
- ✅ Service Account: `168152601641-compute@developer.gserviceaccount.com`
- ✅ Billing enabled
- ✅ Google Cloud SDK installed

### 3. Check Authentication
```powershell
# Login if needed
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project sortyx
```

---

## 🔧 Deployment Steps

### Step 1: Navigate to Backend Directory
```powershell
cd "d:\cloud bin\cloud-sbin-app\backend"
```

### Step 2: Run Deployment Script
```powershell
.\deploy-vertex.ps1
```

### What the Script Does:
1. ✅ Validates prerequisites (gcloud CLI, authentication)
2. ✅ Enables required APIs:
   - Cloud Run API
   - Cloud Build API
   - Vertex AI API
   - Generative Language API
3. ✅ Grants IAM permissions:
   - `roles/aiplatform.user` (Vertex AI access)
   - `roles/serviceusage.serviceUsageConsumer`
4. ✅ Builds Docker image using `Dockerfile.vertex`
5. ✅ Deploys to Cloud Run as `sortyx-backend-vertex`
6. ✅ Configures environment variables:
   - `GCP_PROJECT_ID=sortyx`
   - `GCP_REGION=us-central1`
   - `ENVIRONMENT=production`

### Step 3: Wait for Deployment
- **First deployment**: 5-10 minutes (Docker build + push)
- **Subsequent deployments**: 2-5 minutes

---

## ✅ Post-Deployment Verification

### 1. Check Service URL
The deployment script will output:
```
Vertex AI Backend is live!
========================================
Service URL: https://sortyx-backend-vertex-xxx-uc.a.run.app
```

### 2. Test Health Endpoint
```powershell
$VERTEX_URL = "https://sortyx-backend-vertex-xxx-uc.a.run.app"
curl "$VERTEX_URL/api/health"
```

**Expected Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "provider": "vertex_ai",
  "models_loaded": true
}
```

### 3. Test Classification Endpoint
```powershell
# Test with a base64-encoded image
curl -X POST "$VERTEX_URL/api/classify" `
  -H "Content-Type: application/json" `
  -d '{
    "image_base64": "YOUR_BASE64_IMAGE_HERE"
  }'
```

### 4. Monitor Logs
```powershell
# Real-time logs
gcloud run services logs tail sortyx-backend-vertex --region us-central1

# Or view in Cloud Console
https://console.cloud.google.com/run?project=sortyx
```

---

## 🎯 Performance Testing

### Compare Both Backends

#### Test Gemini API Backend
```powershell
$GEMINI_URL = "https://sortyx-backend-xxx-uc.a.run.app"
Measure-Command { curl "$GEMINI_URL/api/classify" -Method POST -Body '{"image_base64":"..."}' }
```

#### Test Vertex AI Backend
```powershell
$VERTEX_URL = "https://sortyx-backend-vertex-xxx-uc.a.run.app"
Measure-Command { curl "$VERTEX_URL/api/classify" -Method POST -Body '{"image_base64":"..."}' }
```

### Expected Results:
- **Gemini API**: 2-5 seconds
- **Vertex AI**: 0.5-2 seconds (60-70% faster)

---

## 🔄 Update Frontend to Use Vertex AI

### Option 1: Environment Variable (Recommended)
```javascript
// frontend/config.js
const API_URL = process.env.REACT_APP_API_URL || 'https://sortyx-backend-vertex-xxx-uc.a.run.app';
export default API_URL;
```

### Option 2: Direct Configuration
```javascript
// frontend/config.js
const API_URL = 'https://sortyx-backend-vertex-xxx-uc.a.run.app';
export default API_URL;
```

### Deploy Updated Frontend to Vercel
```powershell
cd ../frontend
vercel --prod
```

---

## 🛠️ Troubleshooting

### Issue 1: API Not Enabled
**Error:** `API [aiplatform.googleapis.com] not enabled`

**Solution:**
```powershell
gcloud services enable aiplatform.googleapis.com --project=sortyx
gcloud services enable generativelanguage.googleapis.com --project=sortyx
```

### Issue 2: Permission Denied
**Error:** `Permission denied to access Vertex AI`

**Solution:**
```powershell
$PROJECT_NUMBER = "168152601641"
$SERVICE_ACCOUNT = "${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding sortyx `
  --member="serviceAccount:${SERVICE_ACCOUNT}" `
  --role="roles/aiplatform.user"
```

### Issue 3: Docker Build Fails
**Error:** `Dockerfile.vertex not found`

**Solution:**
```powershell
# Make sure you're in the backend directory
cd "d:\cloud bin\cloud-sbin-app\backend"

# Verify files exist
ls Dockerfile.vertex, vertex.py, requirements-vertex.txt
```

### Issue 4: Model Download Fails
**Error:** `Failed to download YOLO models`

**Solution:**
Models are auto-downloaded to `/home/appuser/.cache/ultralytics/` on first request. Ensure:
```dockerfile
# In Dockerfile.vertex (already configured)
ENV YOLO_CONFIG_DIR=/home/appuser/.cache/ultralytics
RUN chown -R appuser:appuser /home/appuser
```

### Issue 5: Slow Cold Starts
**Problem:** First request after idle takes 30+ seconds

**Solution:** Set minimum instances
```powershell
gcloud run services update sortyx-backend-vertex `
  --min-instances 1 `
  --region us-central1 `
  --project sortyx
```
⚠️ **Note:** Costs ~$5-10/month with 1 always-on instance

---

## 📊 Monitoring & Optimization

### View Metrics in Cloud Console
```
https://console.cloud.google.com/run/detail/us-central1/sortyx-backend-vertex/metrics?project=sortyx
```

### Key Metrics to Monitor:
- **Request Count**: Total API calls
- **Request Latency**: p50, p95, p99
- **Error Rate**: 4xx, 5xx responses
- **Instance Count**: Active containers
- **CPU Utilization**: Usage patterns
- **Memory Utilization**: Usage patterns

### Cost Optimization

#### Current Configuration
```
Memory: 4Gi
CPU: 4 cores
Min instances: 0 (auto-scales down)
Max instances: 10
```

#### Estimated Monthly Costs:
- **Low traffic** (100 requests/day): ~$1-2/month
- **Medium traffic** (1000 requests/day): ~$5-10/month
- **High traffic** (10000 requests/day): ~$30-50/month

#### Reduce Costs:
```powershell
# Lower memory if not needed
gcloud run services update sortyx-backend-vertex `
  --memory 2Gi `
  --region us-central1

# Lower CPU if not needed
gcloud run services update sortyx-backend-vertex `
  --cpu 2 `
  --region us-central1
```

---

## 🔐 Security Best Practices

### 1. Enable Authentication (Optional)
For production, consider requiring authentication:
```powershell
gcloud run services update sortyx-backend-vertex `
  --no-allow-unauthenticated `
  --region us-central1
```

### 2. Set Up IAM Invoker
```powershell
# Allow specific service account to invoke
gcloud run services add-iam-policy-binding sortyx-backend-vertex `
  --member="serviceAccount:YOUR_FRONTEND_SA@sortyx.iam.gserviceaccount.com" `
  --role="roles/run.invoker" `
  --region us-central1
```

### 3. Enable VPC Egress
For internal-only traffic:
```powershell
gcloud run services update sortyx-backend-vertex `
  --vpc-egress all-traffic `
  --vpc-connector YOUR_VPC_CONNECTOR `
  --region us-central1
```

---

## 🚦 Rollback & Cleanup

### Rollback to Previous Revision
```powershell
# List revisions
gcloud run revisions list --service sortyx-backend-vertex --region us-central1

# Rollback
gcloud run services update-traffic sortyx-backend-vertex `
  --to-revisions REVISION_NAME=100 `
  --region us-central1
```

### Delete Service
```powershell
gcloud run services delete sortyx-backend-vertex `
  --region us-central1 `
  --project sortyx
```

---

## 📚 Additional Resources

- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Gemini 1.5 Flash Model Card](https://ai.google.dev/models/gemini)
- [YOLOv8 Documentation](https://docs.ultralytics.com/)

---

## 🎉 Success Checklist

- [ ] Deployed `sortyx-backend-vertex` successfully
- [ ] Health endpoint returns `{"status": "ok"}`
- [ ] Classification endpoint returns predictions
- [ ] Response time < 2 seconds (60-70% improvement)
- [ ] Logs show Vertex AI connections
- [ ] Frontend updated to use new URL
- [ ] Monitoring dashboard configured
- [ ] Both backends running for comparison

---

## 💡 Next Steps

1. **Performance Testing**: Compare both backends with real traffic
2. **Frontend Update**: Switch to faster Vertex AI backend
3. **Monitor Costs**: Track usage and optimize resources
4. **Scale Testing**: Test with concurrent requests
5. **Production Ready**: Enable authentication and monitoring alerts

---

**Need help?** Check troubleshooting section or run:
```powershell
gcloud run services logs tail sortyx-backend-vertex --region us-central1
```
