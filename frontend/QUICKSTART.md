# 🚀 Quick Start - Frontend

## ✅ Setup Complete!

Your frontend is now configured to connect to the backend API.

## 🧪 Test Locally

### 1. Make sure Backend is Running

In Terminal 1 (if not already running):
```powershell
cd "d:\cloud bin\cloud-sbin-app\backend"
.\venv\Scripts\activate
python app.py
```

Backend should be running at: **http://localhost:8000**

### 2. Start Frontend Server

In Terminal 2 (current terminal):
```powershell
cd "d:\cloud bin\cloud-sbin-app\frontend"
python -m http.server 8080
```

### 3. Open in Browser

Open: **http://localhost:8080**

### 4. Test the App

1. ✅ Camera should start automatically after 2 seconds
2. ✅ Hold a waste item in your hand
3. ✅ System will detect your hand and classify the item
4. ✅ View results and disposal instructions

## 🔧 Configuration

The backend URL is configured in `config.js`:

```javascript
API_URL: 'http://localhost:8000'  // For local development
```

For production deployment, update this to your deployed backend URL:

```javascript
API_URL: 'https://your-backend.onrender.com'  // For production
```

## 🐛 Troubleshooting

### Camera Not Working
- Use **HTTPS** in production (or localhost for dev)
- Allow camera permissions in browser
- Try Chrome/Edge (best WebRTC support)

### "Connection Failed" Error
- Check backend is running on port 8000
- Check browser console for errors (F12)
- Verify `config.js` has correct backend URL

### API Errors
- Open browser DevTools → Network tab
- Look for failed requests (red)
- Check backend logs in Terminal 1

## 📱 Browser Console

Open DevTools (F12) to see:
- ✅ Configuration logs
- ✅ WebSocket connection status
- ✅ Hand detection results
- ✅ Classification responses
- ❌ Any errors

## 🎯 Next Steps

Once local testing works:

1. **Deploy Backend** → See `backend/README.md`
2. **Update config.js** with production backend URL
3. **Deploy Frontend** → See `frontend/README.md`

---

**Need help?** Check the main README.md for detailed documentation.
