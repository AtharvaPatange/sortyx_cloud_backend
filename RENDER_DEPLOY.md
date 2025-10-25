# Sortyx Cloud SmartBin - Render Deployment Guide

## 🚀 Deploy to Render

### Quick Deploy

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

---

## 📋 Deployment Steps

### 1. **Prerequisites**
- GitHub account with cloud-sbin-app repository
- Render account (free tier available)
- Google Gemini API key

### 2. **Connect Repository to Render**

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository: `SortyxAI/cloud-sbin-app`
4. Render will auto-detect it as a Python project

### 3. **Configure Web Service**

Use these settings:

| Setting | Value |
|---------|-------|
| **Name** | `sortyx-smartbin` (or your choice) |
| **Region** | Choose nearest to your users |
| **Branch** | `main` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn app:app --host 0.0.0.0 --port $PORT` |
| **Instance Type** | `Free` or `Starter` |

### 4. **Environment Variables**

Add these in Render dashboard under **Environment**:

```bash
GEMINI_API_KEY=your_actual_gemini_api_key_here
PYTHON_VERSION=3.11.0
```

### 5. **Advanced Settings** (Optional)

- **Health Check Path**: `/health`
- **Auto-Deploy**: Enable (deploys on git push)
- **Docker**: Not needed (using native Python)

---

## 🎯 Start Command Options

### **Recommended (Production)**
```bash
uvicorn app:app --host 0.0.0.0 --port $PORT --workers 1
```

### **With Multiple Workers** (for paid tiers)
```bash
uvicorn app:app --host 0.0.0.0 --port $PORT --workers 2
```

### **With Gunicorn** (alternative)
```bash
gunicorn app:app -w 1 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT
```

---

## 🔧 Troubleshooting

### Issue: Models not loading
**Solution**: Models download automatically on first run. First deployment may take 3-5 minutes.

### Issue: Memory limit exceeded
**Solution**: 
- Use Free tier (512MB) or upgrade to Starter (512MB+)
- Models (YOLO) use ~400MB RAM
- Consider using smaller models if needed

### Issue: Timeout during build
**Solution**:
- Increase build timeout in Render settings
- Ensure `requirements.txt` has correct versions

### Issue: Port binding error
**Solution**: Always use `$PORT` variable (Render assigns this dynamically)

---

## 📊 Monitoring

### Health Check
```bash
curl https://your-app.onrender.com/health
```

Expected response:
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

### Logs
View logs in Render dashboard under **Logs** tab

---

## 💰 Pricing

| Tier | RAM | CPU | Price | Best For |
|------|-----|-----|-------|----------|
| **Free** | 512MB | 0.1 CPU | $0 | Testing |
| **Starter** | 512MB | 0.5 CPU | $7/mo | Light usage |
| **Standard** | 2GB | 1 CPU | $25/mo | Production |

**Recommendation**: Start with **Free tier** for testing, upgrade to **Starter** for production

---

## 🌐 Custom Domain

1. Go to **Settings** in Render dashboard
2. Click **Custom Domain**
3. Add your domain: `smartbin.yourdomain.com`
4. Update DNS records as shown

---

## 🔒 Security Best Practices

1. ✅ **Never commit** `.env` with real API keys
2. ✅ **Use environment variables** in Render dashboard
3. ✅ **Enable HTTPS** (automatic on Render)
4. ✅ **Set up health checks** at `/health`
5. ✅ **Monitor logs** regularly

---

## 📈 Performance Tips

### Cold Starts
- Free tier services sleep after 15 minutes of inactivity
- First request may take 30-60 seconds to wake up
- Upgrade to paid tier for always-on service

### Optimization
```python
# Already optimized in app.py:
- CPU-only mode (no GPU needed)
- Efficient model loading
- Async endpoints
- WebSocket support
```

---

## 🔄 Auto-Deploy Setup

Enable auto-deployment:
1. Go to **Settings** → **Build & Deploy**
2. Enable **Auto-Deploy** for `main` branch
3. Every git push will trigger deployment

---

## 📞 Support

- **Render Docs**: https://render.com/docs
- **Render Community**: https://community.render.com
- **Status Page**: https://status.render.com

---

## ✅ Deployment Checklist

- [ ] Repository pushed to GitHub
- [ ] Render account created
- [ ] Web service configured
- [ ] Environment variables set (GEMINI_API_KEY)
- [ ] Build command: `pip install -r requirements.txt`
- [ ] Start command: `uvicorn app:app --host 0.0.0.0 --port $PORT`
- [ ] Health check enabled at `/health`
- [ ] First deployment completed (wait 3-5 min)
- [ ] Test endpoints working
- [ ] Auto-deploy enabled

---

## 🎉 You're Done!

Your app will be available at:
```
https://your-app-name.onrender.com
```

API documentation:
```
https://your-app-name.onrender.com/docs
```
