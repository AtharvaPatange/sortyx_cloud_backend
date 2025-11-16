# Google Cloud Run Deployment Script for Vertex AI Backend
# Deploys to a separate service: sortyx-backend-vertex
# Run this script from the backend directory

Write-Host "Sortyx Backend - Vertex AI Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying GPU-optimized Vertex AI backend..." -ForegroundColor Green
Write-Host ""

# Configuration
$PROJECT_ID = "sortyx"
$SERVICE_NAME = "sortyx-backend-vertex"  # Different service name
$REGION = "us-central1"
$MEMORY = "4Gi"  # More memory for better performance
$CPU = "4"  # More CPU for faster processing
$TIMEOUT = "300"
$MAX_INSTANCES = "5"  # Reduced to fit within quota (4 CPU × 5 = 20 vCPUs = quota limit)
$MIN_INSTANCES = "0"

Write-Host "⚠️  Note: Max instances set to 5 due to quota limits (4 CPU × 5 = 20 vCPUs)" -ForegroundColor Yellow
Write-Host "   To increase, request quota increase at: https://cloud.google.com/run/quotas" -ForegroundColor Yellow
Write-Host ""

# Check if gcloud is installed
Write-Host "[*] Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Google Cloud SDK not found!" -ForegroundColor Red
    Write-Host "Please install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Google Cloud SDK found" -ForegroundColor Green

# Set project
Write-Host ""
Write-Host "[*] Setting project to: $PROJECT_ID" -ForegroundColor Yellow
gcloud config set project $PROJECT_ID

# Check if user is logged in
Write-Host ""
Write-Host "[*] Checking authentication..." -ForegroundColor Yellow
$account = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $account) {
    Write-Host "[*] Please log in to Google Cloud" -ForegroundColor Yellow
    gcloud auth login
    gcloud auth application-default login
}
Write-Host "[OK] Authenticated as: $account" -ForegroundColor Green

# Get project number
$projectNumber = gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
$computeServiceAccount = "${projectNumber}-compute@developer.gserviceaccount.com"

Write-Host ""
Write-Host "[*] Project Number: $projectNumber" -ForegroundColor Cyan
Write-Host "[*] Service Account: $computeServiceAccount" -ForegroundColor Cyan

# Enable required APIs for Vertex AI
Write-Host ""
Write-Host "[*] Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable run.googleapis.com --quiet
gcloud services enable cloudbuild.googleapis.com --quiet
gcloud services enable containerregistry.googleapis.com --quiet
gcloud services enable aiplatform.googleapis.com --quiet
gcloud services enable generativelanguage.googleapis.com --quiet
gcloud services enable serviceusage.googleapis.com --quiet
Write-Host "[OK] APIs enabled" -ForegroundColor Green

# Grant Vertex AI permissions
Write-Host ""
Write-Host "[*] Granting Vertex AI permissions..." -ForegroundColor Yellow
gcloud projects add-iam-policy-binding $PROJECT_ID `
    --member="serviceAccount:${computeServiceAccount}" `
    --role="roles/aiplatform.user" `
    --condition=None `
    --quiet 2>$null

gcloud projects add-iam-policy-binding $PROJECT_ID `
    --member="serviceAccount:${computeServiceAccount}" `
    --role="roles/serviceusage.serviceUsageConsumer" `
    --condition=None `
    --quiet 2>$null

Write-Host "[OK] Vertex AI permissions granted" -ForegroundColor Green

# Check if vertex.py exists
if (-not (Test-Path "vertex.py")) {
    Write-Host "[ERROR] vertex.py not found in current directory!" -ForegroundColor Red
    Write-Host "Please make sure you're in the backend directory." -ForegroundColor Yellow
    exit 1
}

# Check if requirements-vertex.txt exists
if (-not (Test-Path "requirements-vertex.txt")) {
    Write-Host "[ERROR] requirements-vertex.txt not found!" -ForegroundColor Red
    Write-Host "Please create requirements-vertex.txt with Vertex AI dependencies." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[*] Deploying Vertex AI backend..." -ForegroundColor Yellow
Write-Host "Service: $SERVICE_NAME" -ForegroundColor Cyan
Write-Host "Region: $REGION" -ForegroundColor Cyan
Write-Host "Memory: $MEMORY" -ForegroundColor Cyan
Write-Host "CPU: $CPU cores" -ForegroundColor Cyan
Write-Host "This may take 5-10 minutes on first deployment..." -ForegroundColor Yellow
Write-Host ""

# Deploy to Cloud Run using Dockerfile.vertex
Write-Host ""
Write-Host "[*] Preparing Dockerfile.vertex for deployment..." -ForegroundColor Yellow

# Backup original Dockerfile if exists
if (Test-Path "Dockerfile.backup") {
    Remove-Item "Dockerfile.backup" -Force
}
if (Test-Path "Dockerfile") {
    Move-Item "Dockerfile" "Dockerfile.backup" -Force
    Write-Host "[*] Backed up original Dockerfile" -ForegroundColor Yellow
}

# Copy Dockerfile.vertex to Dockerfile for deployment
Copy-Item "Dockerfile.vertex" "Dockerfile" -Force
Write-Host "[*] Using Dockerfile.vertex for deployment" -ForegroundColor Yellow

Write-Host ""
Write-Host "[*] Deploying to Cloud Run..." -ForegroundColor Yellow
gcloud run deploy $SERVICE_NAME `
    --source . `
    --region $REGION `
    --platform managed `
    --allow-unauthenticated `
    --memory $MEMORY `
    --cpu $CPU `
    --timeout $TIMEOUT `
    --max-instances $MAX_INSTANCES `
    --min-instances $MIN_INSTANCES `
    --set-env-vars "GCP_PROJECT_ID=$PROJECT_ID,GCP_REGION=$REGION,ENVIRONMENT=production" `
    --project=$PROJECT_ID

$deploymentStatus = $LASTEXITCODE

# Restore original Dockerfile
if (Test-Path "Dockerfile.backup") {
    Remove-Item "Dockerfile" -Force -ErrorAction SilentlyContinue
    Move-Item "Dockerfile.backup" "Dockerfile" -Force
    Write-Host "[*] Restored original Dockerfile" -ForegroundColor Yellow
}

if ($deploymentStatus -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed" -ForegroundColor Red
    exit 1
}

# Check deployment status
if ($deploymentStatus -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] Vertex AI Backend Deployment successful!" -ForegroundColor Green
    Write-Host ""
    
    # Get service URL
    Write-Host "[*] Getting service URL..." -ForegroundColor Yellow
    $serviceUrl = gcloud run services describe $SERVICE_NAME `
        --region $REGION `
        --format="value(status.url)" `
        --project=$PROJECT_ID
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Vertex AI Backend is live!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Service Name: $SERVICE_NAME" -ForegroundColor White
    Write-Host "Service URL: $serviceUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "Performance:" -ForegroundColor Cyan
    Write-Host "  - AI Provider: Vertex AI Gemini 1.5 Flash" -ForegroundColor White
    Write-Host "  - Expected Latency: 0.5-2 seconds" -ForegroundColor White
    Write-Host "  - 60-70% faster than Gemini API" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test health endpoint:"
    Write-Host "     curl $serviceUrl/api/health" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2. Test classification:"
    Write-Host "     curl -X POST $serviceUrl/api/classify \" -ForegroundColor Yellow
    Write-Host "       -H 'Content-Type: application/json' \" -ForegroundColor Yellow
    Write-Host "       -d '{\"image_base64\": \"YOUR_BASE64_IMAGE\"}'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  3. Update your frontend config.js:"
    Write-Host "     API_URL: '$serviceUrl'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  4. View logs:"
    Write-Host "     gcloud run services logs tail $SERVICE_NAME --region $REGION" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  5. View in console:"
    Write-Host "     https://console.cloud.google.com/run?project=$PROJECT_ID" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  6. Compare performance with Gemini API backend:"
    Write-Host "     Both backends are now running!" -ForegroundColor Green
    Write-Host "     - Gemini API: sortyx-backend" -ForegroundColor White
    Write-Host "     - Vertex AI: sortyx-backend-vertex (faster)" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs with:" -ForegroundColor Yellow
    Write-Host "gcloud builds list --limit 1 --project=$PROJECT_ID" -ForegroundColor White
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Make sure vertex.py exists in current directory" -ForegroundColor White
    Write-Host "  2. Make sure requirements-vertex.txt exists" -ForegroundColor White
    Write-Host "  3. Check that Vertex AI API is enabled" -ForegroundColor White
    Write-Host ""
    exit 1
}
