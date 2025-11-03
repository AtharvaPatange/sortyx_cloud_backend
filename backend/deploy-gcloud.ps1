# Google Cloud Run Deployment Script for Windows PowerShell
# Run this script from the backend directory

Write-Host "🚀 Sortyx Backend - Google Cloud Run Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$PROJECT_ID = "sortyx-backend-prod"
$SERVICE_NAME = "sortyx-backend"
$REGION = "us-central1"
$MEMORY = "2Gi"
$CPU = "2"
$TIMEOUT = "300"
$MAX_INSTANCES = "10"
$MIN_INSTANCES = "0"

# Check if gcloud is installed
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Google Cloud SDK not found!" -ForegroundColor Red
    Write-Host "Please install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Google Cloud SDK found" -ForegroundColor Green

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Docker not found (optional for local testing)" -ForegroundColor Yellow
}

# Ask user for project ID
Write-Host ""
$userProjectId = Read-Host "Enter your Google Cloud Project ID (or press Enter to use `'$PROJECT_ID`')"
if ($userProjectId) {
    $PROJECT_ID = $userProjectId
}

# Set project
Write-Host ""
Write-Host "📦 Setting project to: $PROJECT_ID" -ForegroundColor Yellow
gcloud config set project $PROJECT_ID

# Check if user is logged in
Write-Host ""
Write-Host "👤 Checking authentication..." -ForegroundColor Yellow
$account = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $account) {
    Write-Host "🔐 Please log in to Google Cloud" -ForegroundColor Yellow
    gcloud auth login
}
Write-Host "✅ Authenticated as: $account" -ForegroundColor Green

# Enable required APIs
Write-Host ""
Write-Host "🔧 Enabling required APIs (may take a minute)..." -ForegroundColor Yellow
gcloud services enable run.googleapis.com --quiet 2>$null
gcloud services enable cloudbuild.googleapis.com --quiet 2>$null
gcloud services enable containerregistry.googleapis.com --quiet 2>$null
gcloud services enable secretmanager.googleapis.com --quiet 2>$null
Write-Host "✅ APIs enabled" -ForegroundColor Green

# Check for Gemini API key secret
Write-Host ""
Write-Host "🔑 Checking for GEMINI_API_KEY secret..." -ForegroundColor Yellow
$secretExists = gcloud secrets describe GEMINI_API_KEY 2>$null
if (-not $secretExists) {
    Write-Host "❌ GEMINI_API_KEY secret not found" -ForegroundColor Red
    $apiKey = Read-Host "Enter your Gemini API Key (or press Enter to skip and add later)"
    if ($apiKey) {
        Write-Host "Creating secret..." -ForegroundColor Yellow
        $apiKey | gcloud secrets create GEMINI_API_KEY --data-file=-
        
        # Grant access to Cloud Run
        $projectNumber = gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
        gcloud secrets add-iam-policy-binding GEMINI_API_KEY `
            --member="serviceAccount:${projectNumber}-compute@developer.gserviceaccount.com" `
            --role="roles/secretmanager.secretAccessor" --quiet
        
        Write-Host "✅ Secret created and access granted" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Skipping secret creation - deployment may fail" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ GEMINI_API_KEY secret exists" -ForegroundColor Green
}

# Deployment method selection
Write-Host ""
Write-Host "📋 Choose deployment method:" -ForegroundColor Cyan
Write-Host "  1. Quick Deploy (from source - recommended for first time)"
Write-Host "  2. Build & Deploy (using Dockerfile)"
Write-Host "  3. Setup CI/CD (auto-deploy on git push)"
Write-Host ""
$method = Read-Host "Enter choice (1-3)"

switch ($method) {
    "1" {
        Write-Host ""
        Write-Host "🚀 Deploying to Cloud Run from source..." -ForegroundColor Yellow
        Write-Host "This may take 5-10 minutes on first deployment..." -ForegroundColor Yellow
        
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
            --port 8080 `
            --set-env-vars "ENVIRONMENT=production,PORT=8080" `
            --set-secrets "GEMINI_API_KEY=GEMINI_API_KEY:latest"
    }
    
    "2" {
        Write-Host ""
        Write-Host "🔨 Building Docker image..." -ForegroundColor Yellow
        docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME:latest .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Build successful" -ForegroundColor Green
            
            Write-Host "📤 Pushing to Container Registry..." -ForegroundColor Yellow
            docker push gcr.io/$PROJECT_ID/$SERVICE_NAME:latest
            
            Write-Host "🚀 Deploying to Cloud Run..." -ForegroundColor Yellow
            gcloud run deploy $SERVICE_NAME `
                --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest `
                --region $REGION `
                --platform managed `
                --allow-unauthenticated `
                --memory $MEMORY `
                --cpu $CPU `
                --timeout $TIMEOUT `
                --max-instances $MAX_INSTANCES `
                --min-instances $MIN_INSTANCES `
                --port 8080 `
                --set-env-vars "ENVIRONMENT=production,PORT=8080" `
                --set-secrets "GEMINI_API_KEY=GEMINI_API_KEY:latest"
        } else {
            Write-Host "❌ Build failed" -ForegroundColor Red
            exit 1
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "🔗 Setting up CI/CD with Cloud Build..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Prerequisites:" -ForegroundColor Cyan
        Write-Host "  1. Your code must be in a GitHub repository"
        Write-Host "  2. You need to connect GitHub to Cloud Build first"
        Write-Host ""
        Write-Host "Visit: https://console.cloud.google.com/cloud-build/triggers" -ForegroundColor Yellow
        Write-Host "Then run this command:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "gcloud beta builds triggers create github \\" -ForegroundColor White
        Write-Host "  --repo-name=sortyx_cloud_backend \\" -ForegroundColor White
        Write-Host "  --repo-owner=AtharvaPatange \\" -ForegroundColor White
        Write-Host "  --branch-pattern=`'^main`$`' \\" -ForegroundColor White
        Write-Host "  --build-config=backend/cloudbuild.yaml" -ForegroundColor White
        Write-Host ""
        exit 0
    }
    
    default {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
        exit 1
    }
}

# Check deployment status
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    
    # Get service URL
    Write-Host "🌍 Getting service URL..." -ForegroundColor Yellow
    $serviceUrl = gcloud run services describe $SERVICE_NAME `
        --region $REGION `
        --format="value(status.url)"
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "🎉 Your backend is live!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Service URL: $serviceUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test health endpoint:"
    Write-Host "     curl $serviceUrl/api/health" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2. Update your frontend config.js:"
    Write-Host "     API_URL: `'$serviceUrl`'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  3. View logs:"
    Write-Host "     gcloud run services logs tail $SERVICE_NAME --region $REGION" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  4. View in console:"
    Write-Host "     https://console.cloud.google.com/run?project=$PROJECT_ID" -ForegroundColor Yellow
    Write-Host ""
    
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs with:" -ForegroundColor Yellow
    Write-Host "gcloud builds list --limit 1" -ForegroundColor White
    Write-Host ""
    exit 1
}
