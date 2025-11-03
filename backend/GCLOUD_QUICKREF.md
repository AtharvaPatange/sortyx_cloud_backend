# 🎯 Google Cloud Run - Quick Reference

## 🚀 One-Command Deploy

```bash
cd backend
gcloud run deploy sortyx-backend --source . --region us-central1 --allow-unauthenticated
```

---

## 📋 Essential Commands

### Deploy & Update
```bash
# Quick deploy from source
gcloud run deploy sortyx-backend --source . --region us-central1

# Deploy from Docker image
gcloud run deploy sortyx-backend --image gcr.io/PROJECT_ID/sortyx-backend:latest --region us-central1

# Update environment variables
gcloud run services update sortyx-backend --region us-central1 --set-env-vars KEY=VALUE

# Update secrets
echo -n "NEW_SECRET" | gcloud secrets versions add SECRET_NAME --data-file=-
```

### Monitor & Debug
```bash
# Get service URL
gcloud run services describe sortyx-backend --region us-central1 --format="value(status.url)"

# Stream logs (live)
gcloud run services logs tail sortyx-backend --region us-central1 --follow

# Read recent logs
gcloud run services logs read sortyx-backend --region us-central1 --limit 100

# List deployments
gcloud run services list --region us-central1

# Get service details
gcloud run services describe sortyx-backend --region us-central1
```

### Scale & Resources
```bash
# Increase memory
gcloud run services update sortyx-backend --region us-central1 --memory 4Gi

# Increase CPU
gcloud run services update sortyx-backend --region us-central1 --cpu 4

# Keep warm (prevent cold starts)
gcloud run services update sortyx-backend --region us-central1 --min-instances 1

# Allow scale to zero
gcloud run services update sortyx-backend --region us-central1 --min-instances 0

# Set max instances (cost control)
gcloud run services update sortyx-backend --region us-central1 --max-instances 10
```

### Secrets Management
```bash
# Create secret
echo -n "SECRET_VALUE" | gcloud secrets create SECRET_NAME --data-file=-

# Update secret
echo -n "NEW_VALUE" | gcloud secrets versions add SECRET_NAME --data-file=-

# List secrets
gcloud secrets list

# Grant Cloud Run access to secret
PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format="value(projectNumber)")
gcloud secrets add-iam-policy-binding SECRET_NAME \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Cost Management
```bash
# View service usage
gcloud run services describe sortyx-backend --region us-central1 --format="yaml(status)"

# Delete service (stop charges)
gcloud run services delete sortyx-backend --region us-central1

# List all Cloud Run services
gcloud run services list --platform managed
```

---

## 🔧 Configuration

### Environment Variables (app.py)
- `PORT` - Server port (Cloud Run sets automatically)
- `ENVIRONMENT` - production/development
- `GEMINI_API_KEY` - From Secret Manager
- `ALLOWED_ORIGINS` - CORS origins (comma-separated)
- `RENDER_FREE_TIER` - Set to "false" for Cloud Run

### Resource Recommendations
- **Memory**: 2Gi (default) - 4Gi (for larger models)
- **CPU**: 2 (default) - 4 (for faster inference)
- **Timeout**: 300s (default) - 600s (for slow LLM calls)
- **Min Instances**: 0 (save cost) - 1 (prevent cold starts)
- **Max Instances**: 10 (default) - 100 (high traffic)

---

## 🐛 Troubleshooting

### "Service unavailable" / 502 errors
```bash
# Check logs
gcloud run services logs tail sortyx-backend --region us-central1

# Keep service warm
gcloud run services update sortyx-backend --region us-central1 --min-instances 1
```

### "Out of memory"
```bash
# Increase memory
gcloud run services update sortyx-backend --region us-central1 --memory 4Gi
```

### "Request timeout"
```bash
# Increase timeout
gcloud run services update sortyx-backend --region us-central1 --timeout 600
```

### "Permission denied" for secrets
```bash
# Get project number
PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format="value(projectNumber)")

# Grant access
gcloud secrets add-iam-policy-binding SECRET_NAME \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Cold start taking too long
```bash
# Option 1: Keep 1 instance always warm
gcloud run services update sortyx-backend --region us-central1 --min-instances 1

# Option 2: Use Cloud Scheduler to ping every 5 minutes
gcloud scheduler jobs create http keep-warm \
  --schedule="*/5 * * * *" \
  --uri="https://YOUR_SERVICE_URL/api/health" \
  --http-method=GET
```

---

## 💰 Cost Estimation

**Cloud Run Free Tier (per month):**
- 2 million requests
- 360,000 GB-seconds of memory
- 180,000 vCPU-seconds

**Paid Pricing (as of 2025):**
- ~$0.024 per million requests
- ~$0.00002400 per GB-second
- ~$0.00001000 per vCPU-second

**Example Monthly Cost (2Gi RAM, 2 CPU, 100k requests/month):**
- ~$2-5/month (well within free tier if < 2M requests)

---

## 🔒 Security Checklist

- [ ] Use secrets for API keys (not environment variables)
- [ ] Restrict CORS origins in production
- [ ] Enable Cloud Run authentication if needed
- [ ] Set up custom domain with SSL
- [ ] Monitor logs for suspicious activity
- [ ] Set max instances to prevent runaway costs
- [ ] Use least-privilege IAM roles
- [ ] Regularly rotate secrets

---

## 📊 Monitoring

### View in Cloud Console
- **Services**: https://console.cloud.google.com/run
- **Logs**: https://console.cloud.google.com/logs
- **Metrics**: https://console.cloud.google.com/monitoring

### Key Metrics to Watch
- Request count
- Request latency (p50, p95, p99)
- Error rate
- Memory utilization
- CPU utilization
- Billable container instance time

---

## 🎯 Production Checklist

- [ ] Deploy successful: `gcloud run deploy`
- [ ] Health check passes: `curl URL/api/health`
- [ ] CORS configured: Update `ALLOWED_ORIGINS`
- [ ] Secrets set up: `GEMINI_API_KEY` in Secret Manager
- [ ] Resources optimized: Memory/CPU/Timeout
- [ ] Monitoring enabled: Check Cloud Console
- [ ] Frontend updated: Set `API_URL` in `config.js`
- [ ] Domain configured: (Optional) Custom domain
- [ ] CI/CD set up: (Optional) Auto-deploy on push

---

## 🌐 Service URL Format

```
https://SERVICE_NAME-PROJECT_HASH-REGION_CODE.a.run.app
```

Example:
```
https://sortyx-backend-a1b2c3d4-uc.a.run.app
```

---

## 📞 Support & Resources

- **Documentation**: https://cloud.google.com/run/docs
- **Pricing**: https://cloud.google.com/run/pricing
- **Quotas**: https://cloud.google.com/run/quotas
- **Troubleshooting**: https://cloud.google.com/run/docs/troubleshooting
- **Support**: https://cloud.google.com/support

---

**💡 Pro Tips:**
1. Use `--min-instances 1` in production to avoid cold starts
2. Set up Cloud Scheduler to ping your service every 5 minutes
3. Use Cloud Monitoring alerts for high error rates
4. Keep secrets in Secret Manager, never in code
5. Use Cloud Build triggers for CI/CD automation
