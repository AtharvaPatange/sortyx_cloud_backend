# 🚀 Sortyx Waste Classification - Deployment Guide

## Project Overview
**Sortyx** is a waste classification system with a separated **Frontend** (HTML/JS) and **Backend** (FastAPI) architecture.

- **Backend**: FastAPI server with YOLO hand detection + Gemini AI classification
- **Frontend**: Static HTML/CSS/JS with WebRTC camera and WebSocket support
- **Deployment**: Render.com (free tier optimized)

---

## 📁 Project Structure

```
sortyx_cloud_backend/
├── backend/
│   ├── app.py                          # FastAPI server with all AI/ML logic
│   ├── requirements.txt                # Python dependencies
│   ├── render.yaml                     # Render deployment config
│   ├── runtime.txt                     # Python 3.12.7 version
│   ├── models/                         # YOLO models (auto-downloaded on Render)
│   └── README.md                       # Backend documentation
│
├── frontend/
│   ├── index.html                      # Main web application UI
│   ├── config.js                       # Backend API configuration
│   ├── README.md                       # Frontend documentation
│   └── QUICKSTART.md                   # Quick start guide
```

---

## 🔧 Backend Configuration

### Key Files

#### `render.yaml` (Deployment Configuration)
```yaml
runtimeVersion: "3.12.7"               # Python 3.12.7 (critical for Render)
RENDER_FREE_TIER: "true"               # Enables fast YOLO-only classification
```

#### `requirements.txt` (Python Packages)
**Critical versions for Python 3.12.7:**
- `pydantic==2.10.6` - Has pre-built wheels (no compilation needed)
- `pillow==11.0.0` - Fixes setup.py errors
- `torch==2.5.1` - CPU-optimized PyTorch
- `ultralytics==8.3.64` - YOLOv8 models
- `google-genai==1.47.0` - Gemini AI SDK

#### `app.py` (Backend API)
**Key Endpoints:**
- `GET /api/health` - Health check
- `POST /api/detect-hand-wrist` - Hand detection with YOLOv8 Pose
- `POST /api/classify` - Waste classification (YOLO or Gemini AI)
- `GET /api/stats` - Statistics
- `GET /api/bins/status` - Bin status
- `WebSocket /ws` - Real-time updates

**Optimizations for Render Free Tier:**
- Image compression (640px max, 70% JPEG quality)
- Aggressive timeouts on Gemini API
- Automatic YOLO-only mode when `RENDER_FREE_TIER=true`
- Model auto-download from Ultralytics on startup

---

## 🎨 Frontend Configuration

### Key Files

#### `config.js` (API Configuration)
```javascript
API_URL: 'https://sortyx-cloud-backend.onrender.com'  // No trailing slash!
WS_URL: 'wss://sortyx-cloud-backend.onrender.com'
```

**⚠️ CRITICAL:**
- Remove trailing slashes from URLs (prevents `//api/...` double slashes)
- Update `API_URL` when deploying to different backend

#### `index.html` (Web Application)
**Features:**
- Real-time camera feed with hand detection
- Auto-starting continuous scanning
- Voice synthesis for results
- WebSocket for real-time updates
- Disposal bin indicator
- CO2 impact tracking

---

## 🌐 Local Development

### Prerequisites
- Python 3.12.7+
- Node.js (for frontend server, optional)

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
$env:GEMINI_API_KEY = "your-api-key"
$env:PORT = "8000"

# Run backend
python app.py
```

**Backend will be available at:** `http://localhost:8000`

### Frontend Setup

```bash
cd frontend

# Option 1: Python HTTP server
python -m http.server 8080

# Option 2: Node.js HTTP server
npx http-server -p 8080
```

**Frontend will be available at:** `http://localhost:8080`

### Update config.js for Local Testing
```javascript
API_URL: 'http://localhost:8000'     // Local backend
```

---

## ☁️ Render Deployment

### Step 1: Create Render Account & Connect GitHub
1. Go to [render.com](https://render.com)
2. Sign up and connect your GitHub account
3. Grant access to your repository

### Step 2: Deploy Backend

1. Create new **Web Service**
2. **Select repository:** `sortyx_cloud_backend`
3. **Name:** `sortyx-backend`
4. **Runtime:** Python
5. **Branch:** main
6. **Build command:** Default (uses `requirements.txt`)
7. **Start command:** `python backend/app.py`
8. **Environment Variables:**
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `RENDER_FREE_TIER`: `true` (for free tier optimization)

### Step 3: Get Backend URL
Once deployed, Render will provide a URL like:
```
https://sortyx-backend.onrender.com
```

### Step 4: Update Frontend config.js
Update frontend `config.js` with your Render URL:
```javascript
API_URL: 'https://sortyx-backend.onrender.com'  // Your Render URL
```

### Step 5: Deploy Frontend
Options:
- **Netlify:** Drag & drop the `frontend` folder
- **Vercel:** Connect GitHub repo, select `frontend` folder
- **GitHub Pages:** Push to `gh-pages` branch

---

## 🔍 Troubleshooting

### Issue: 404 Errors on Render
**Cause:** Backend still deploying or endpoints missing
**Solution:**
- Wait 3-5 minutes for Render to finish deployment
- Check Render logs for errors
- Verify `render.yaml` is in root of backend directory

### Issue: 502 Bad Gateway
**Cause:** Backend crashed or timeout (usually Gemini API calls)
**Solution:**
- Ensure `RENDER_FREE_TIER=true` is set
- Check backend logs on Render
- YOLO classification should be fast (1-3s), Gemini might timeout (15-30s)

### Issue: Double Slashes in URLs (`//api/stats`)
**Cause:** Trailing slash in `config.js` API_URL
**Solution:**
```javascript
// ❌ WRONG
API_URL: 'https://sortyx-cloud-backend.onrender.com/'

// ✅ CORRECT
API_URL: 'https://sortyx-cloud-backend.onrender.com'
```

### Issue: CORS Errors
**Cause:** Backend not configured for CORS
**Solution:** Backend has CORS enabled with `allow_origins=["*"]`. If still failing:
- Check backend is running
- Verify API_URL is correct in `config.js`

### Issue: Hand Detection Not Working
**Cause:** Low confidence or poor lighting
**Solution:**
- Ensure good lighting
- Show full hand with wrist visible
- Hold steady for 1-2 seconds
- Detection threshold is set to 0.05 (5% confidence minimum)

---

## 📊 Performance Expectations

### Local Development
- Hand detection: 0.5-1s
- Classification (YOLO): 1-2s
- Classification (Gemini): 5-10s

### Render Free Tier
- Hand detection: 0.5-1s
- Classification (YOLO only): 1-2s
- No Gemini (too slow for free tier)

### Render Paid Tier
- Hand detection: 0.5-1s
- Classification (YOLO): 1-2s
- Classification (Gemini): 5-10s

---

## 🔐 Environment Variables

### Required
- `GEMINI_API_KEY` - Google Gemini API key

### Optional
- `PORT` - Server port (default: 8000)
- `ENVIRONMENT` - `production` or `development`
- `RENDER_FREE_TIER` - `true` for Render free tier optimization

---

## 📝 Recent Optimizations

### For Render Free Tier
1. **Image Compression** - Reduces upload time
2. **Faster Models** - Uses `gemini-2.0-flash-exp` only
3. **Automatic YOLO Mode** - Avoids Gemini timeouts
4. **Model Auto-Download** - Ultralytics cache system
5. **Python 3.12.7** - Specific version for consistency

### Configuration
- `RENDER_FREE_TIER=true` automatically switches to fast mode
- YOLO classification: ~1-2 seconds
- No Gemini API calls on free tier (would timeout)

---

## 🚀 Next Steps

1. **Set up Render account** and connect GitHub
2. **Deploy backend** to Render
3. **Update frontend** `config.js` with Render URL
4. **Deploy frontend** to Netlify/Vercel/GitHub Pages
5. **Test** with camera enabled

---

## 📞 Support

- Check logs in Render dashboard
- Verify environment variables are set
- Ensure `render.yaml` and `requirements.txt` are up to date
- Test locally first before deploying

---

**Last Updated:** November 3, 2025
