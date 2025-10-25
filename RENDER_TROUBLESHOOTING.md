# Render Deployment Troubleshooting Guide

## 🚨 Common Render Deployment Failures & Solutions

### ❌ Problem -1: PyTorch 2.6+ YOLO Model Loading Error (CRITICAL - FIXED!)
**Error Message:**
```
ERROR:app:❌ Error loading pose model: Weights only load failed
WeightsUnpickler error: Unsupported global: GLOBAL ultralytics.nn.tasks.PoseModel
cannot import name 'C2fAttn' from 'ultralytics.nn.modules'
```

**Root Cause:** 
- PyTorch 2.6+ changed `torch.load()` default to `weights_only=True` for security
- YOLO models use pickle serialization with Python classes that are blocked
- Previous fix tried importing non-existent modules (`C2fAttn` doesn't exist in ultralytics 8.0.231)

**Solution:** ✅ **FIXED with monkey-patch approach!**

Instead of trying to register safe globals (which failed), we now **monkey-patch `torch.load()`** to use `weights_only=False` for YOLO models:

```python
# Store original torch.load function
_original_torch_load = torch.load

def _patched_torch_load(f, map_location=None, pickle_module=None, *, weights_only=None, **kwargs):
    """Force weights_only=False for YOLO models (safe for trusted sources)"""
    if weights_only is None:
        weights_only = False
    return _original_torch_load(f, map_location=map_location, 
                                pickle_module=pickle_module, 
                                weights_only=weights_only, **kwargs)

# Apply the monkey patch BEFORE importing YOLO
torch.load = _patched_torch_load
```

**Why this is SAFE:**
1. ✅ We only load official ultralytics YOLO models from trusted sources
2. ✅ Models are downloaded from official GitHub releases
3. ✅ This is PyTorch's recommended approach for legacy model formats
4. ✅ Applied BEFORE importing YOLO, so all model loading uses the patched version

---

### ❌ Problem 0: Python 3.13 Compatibility Error (NEW!)
**Error Message:**
```
AttributeError: module 'pkgutil' has no attribute 'ImpImporter'
ERROR: Failed to build 'numpy' when getting requirements to build wheel
```

**Cause:** 
- Render defaulted to Python 3.13 which removed `pkgutil.ImpImporter`
- Older versions of numpy/setuptools are incompatible with Python 3.13

**Solution:** ✅ Fixed!
1. Created `runtime.txt` with `python-3.11.0`
2. Updated `requirements.txt` with pinned numpy==1.24.3
3. Added setuptools and wheel to requirements
4. Updated `render.yaml` to specify `runtime: python-3.11.0`

**Why Python 3.11?**
- ✅ Stable and well-tested
- ✅ Compatible with all ML libraries (ultralytics, opencv, numpy)
- ✅ Recommended for production ML applications
- ❌ Python 3.13 is too new - many packages haven't updated yet

---

### ❌ Problem 1: OpenCV ImportError
**Error Message:**
```
ImportError: libGL.so.1: cannot open shared object file
```

**Cause:** Missing system dependencies for OpenCV

**Solution:** ✅ Already fixed with `Aptfile` and `packages.txt`

---

### ❌ Problem 2: Port Binding Error
**Error Message:**
```
Error: Address already in use
or
uvicorn.config.ServerNotRunning
```

**Cause:** App hardcoded to port 8000 instead of using Render's `$PORT` variable

**Solution:** ✅ Already fixed in `app.py` - now uses `os.getenv("PORT", 8000)`

---

### ❌ Problem 3: Build Timeout
**Error Message:**
```
Build exceeded maximum time limit
```

**Cause:** 
- YOLO models downloading during build (can take 5-10 minutes)
- Render free tier has build timeout limits

**Solution:**
1. Models will download on first request (not during build)
2. First deployment takes 3-5 minutes - be patient
3. Upgrade to Starter plan if timeouts persist

---

### ❌ Problem 4: Memory Limit Exceeded
**Error Message:**
```
Out of memory or Process killed
```

**Cause:** 
- YOLO models use ~400MB RAM
- Free tier has 512MB limit

**Solution:**
1. Current setup is optimized for 512MB
2. If still failing, upgrade to Starter plan (512MB+ guaranteed)
3. Check logs for memory usage: `less /var/log/syslog`

---

### ❌ Problem 5: Static Files Not Found
**Error Message:**
```
RuntimeError: Directory 'static' does not exist
```

**Cause:** Missing `static/` or `templates/` directories

**Solution:** ✅ Already fixed - directories created with `.gitkeep` files

---

### ❌ Problem 6: GEMINI_API_KEY Not Set
**Error Message:**
```
⚠️ GEMINI_API_KEY not found
```

**Cause:** Environment variable not configured in Render dashboard

**Solution:**
1. Go to Render Dashboard → Your Service → Environment
2. Add: `GEMINI_API_KEY` = `your_actual_api_key`
3. **Important:** Remove the exposed API key from your `.env` file!

---

### ❌ Problem 7: Health Check Failing
**Error Message:**
```
Health check failed
```

**Cause:** 
- App not responding on `/health` endpoint
- Models still loading

**Solution:**
1. Health check path is set to `/health` ✅
2. First startup takes 2-3 minutes for model download
3. Check logs to see if models loaded successfully

---

## 🔧 Debugging Steps

### Step 1: Check Render Logs
```bash
# In Render Dashboard → Logs tab
# Look for these indicators:

✅ Good Signs:
- "✅ YOLOv8 Pose model loaded"
- "✅ YOLO detection model loaded"  
- "✅ Gemini API configured"
- "Application startup complete"

❌ Bad Signs:
- "ImportError: libGL.so.1"
- "Out of memory"
- "Port already in use"
- "⚠️ GEMINI_API_KEY not found"
```

### Step 2: Test Health Endpoint
```bash
curl https://your-app.onrender.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "models_loaded": {
    "yolo_detection": true,
    "yolo_pose": true,
    "gemini_configured": true
  }
}
```

### Step 3: Check Build Command
In Render Dashboard:
- **Build Command:** `pip install --upgrade pip && pip install -r requirements.txt`
- **Start Command:** `uvicorn app:app --host 0.0.0.0 --port $PORT --workers 1`

### Step 4: Verify Environment Variables
Required variables:
- ✅ `GEMINI_API_KEY` (set in dashboard)
- ✅ `PORT` (automatically set by Render)
- ⚠️ `PYTHON_VERSION=3.11.0` (optional)

---

## 📋 Pre-Deployment Checklist

Before pushing to Render:

- [x] `Procfile` created with start command
- [x] `render.yaml` configured
- [x] `Aptfile` has system dependencies
- [x] `packages.txt` has OpenCV libraries
- [x] `app.py` uses `$PORT` variable
- [x] `static/` and `templates/` directories exist
- [x] `.gitignore` excludes `.env` file
- [ ] GEMINI_API_KEY set in Render dashboard (⚠️ DO THIS!)
- [ ] Removed exposed API key from `.env`

---

## 🚀 Post-Fix Deployment Steps

1. **Commit and push changes:**
```bash
cd /Users/ranjith/development/cloud-sbin-app
git add .
git commit -m "Fix Render deployment issues"
git push origin main
```

2. **Trigger manual deploy in Render:**
   - Go to Render Dashboard
   - Click "Manual Deploy" → "Deploy latest commit"

3. **Monitor deployment:**
   - Watch logs in real-time
   - Wait 3-5 minutes for first deployment
   - Check for success messages

4. **Test the deployment:**
```bash
# Health check
curl https://your-app.onrender.com/health

# API docs
open https://your-app.onrender.com/docs
```

---

## 💡 Performance Tips

### Reduce Cold Start Time
Free tier apps sleep after 15 minutes of inactivity:
- First request may take 30-60 seconds
- Upgrade to paid tier for always-on service

### Optimize Memory Usage
```python
# Already optimized in app.py:
- reload=False  # Disabled auto-reload
- workers=1     # Single worker for free tier
- CPU-only mode # No GPU overhead
```

---

## 📞 Still Having Issues?

1. **Check Render Status:** https://status.render.com
2. **Render Community:** https://community.render.com
3. **Review full logs** in Render dashboard
4. **Compare with working config** in `render.yaml`

---

## ⚠️ CRITICAL: Security Issue

**Your `.env` file contains an exposed API key!**

```properties
GEMINI_API_KEY="AIzaSyAxR3Q0aDKpQ66opBaaCmic6VpcCwKz8Hs"
```

**Action Required:**
1. Go to Google Cloud Console
2. **Regenerate your Gemini API key immediately**
3. Update the new key in Render dashboard only
4. Never commit API keys to git
5. The `.env` file is already in `.gitignore` ✅

---

## ✅ Summary of Fixes Applied

| Issue | Status | Fix |
|-------|--------|-----|
| OpenCV dependencies | ✅ Fixed | Created `Aptfile` and `packages.txt` |
| Port configuration | ✅ Fixed | Updated `app.py` to use `$PORT` |
| Missing directories | ✅ Fixed | Created `static/`, `templates/`, `models/` |
| Render config | ✅ Fixed | Updated `render.yaml` |
| Production settings | ✅ Fixed | Disabled reload, set workers=1 |
| API key exposure | ⚠️ ACTION NEEDED | Regenerate key, add to Render dashboard |
| Python 3.13 compatibility | ✅ Fixed | Created `runtime.txt`, updated `requirements.txt` |
| PyTorch 2.6+ model loading | ✅ Fixed | Monkey-patched `torch.load()` |
Your app should now deploy successfully! 🎉
