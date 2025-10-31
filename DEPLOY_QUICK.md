# 🚀 Complete Deployment Guide - Sortyx Cloud

**Quick deployment guide for separated frontend and backend architecture**

## ⚡ Quick Deploy (5 minutes)

### Backend → Render.com (Free)

1. Create `render.yaml` in `backend/`:
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
```

2. Push to GitHub
3. Go to https://dashboard.render.com
4. New → Blueprint → Connect repo
5. Add `GEMINI_API_KEY` in environment variables
6. Deploy! Get URL: `https://sortyx-backend.onrender.com`

### Frontend → Netlify (Free)

1. Update `frontend/config.js`:
```javascript
API_URL: 'https://sortyx-backend.onrender.com'
```

2. Go to https://app.netlify.com
3. Drag `frontend/` folder to upload area
4. Done! Get URL: `https://sortyx.netlify.app`

---

## 📚 Detailed Deployment Options

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guides covering:
- Heroku
- Google Cloud Run
- AWS (ECS/Fargate)
- Azure Container Instances
- DigitalOcean
- Vercel
- GitHub Pages
- AWS S3 + CloudFront

---

## 🔧 Post-Deployment Checklist

- [ ] Backend health check returns "healthy"
- [ ] Frontend loads without errors
- [ ] Camera access works (HTTPS required)
- [ ] Hand detection works
- [ ] Classification works
- [ ] WebSocket connected
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active
- [ ] Monitoring setup
- [ ] Backup strategy defined

---

## 🆘 Quick Troubleshooting

**Backend not working?**
```bash
curl https://your-backend-url.com/api/health
```

**Frontend can't connect to backend?**
- Check `config.js` has correct backend URL
- Verify CORS settings in backend
- Check browser console for errors

**Camera not working?**
- Must use HTTPS (or localhost)
- Allow camera permissions in browser

---

**Need help?** See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.
