#!/bin/bash
# Google Cloud Run Deployment Script for Linux/macOS
# Run: chmod +x deploy-gcloud.sh && ./deploy-gcloud.sh

set -e

echo "🚀 Sortyx Backend - Google Cloud Run Deployment"
echo "================================================"
echo ""

# Configuration
PROJECT_ID="${PROJECT_ID:-sortyx-backend-prod}"
SERVICE_NAME="sortyx-backend"
REGION="us-central1"
MEMORY="2Gi"
CPU="2"
TIMEOUT="300"
MAX_INSTANCES="10"
MIN_INSTANCES="0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if gcloud is installed
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Google Cloud SDK not found!${NC}"
    echo -e "${YELLOW}Please install from: https://cloud.google.com/sdk/docs/install${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Google Cloud SDK found${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker not found (optional for local testing)${NC}"
fi

# Ask user for project ID
echo ""
read -p "Enter your Google Cloud Project ID (or press Enter to use '$PROJECT_ID'): " user_project_id
if [ -n "$user_project_id" ]; then
    PROJECT_ID="$user_project_id"
fi

# Set project
echo ""
echo -e "${YELLOW}📦 Setting project to: $PROJECT_ID${NC}"
gcloud config set project "$PROJECT_ID"

# Check if user is logged in
echo ""
echo -e "${YELLOW}👤 Checking authentication...${NC}"
account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
if [ -z "$account" ]; then
    echo -e "${YELLOW}🔐 Please log in to Google Cloud${NC}"
    gcloud auth login
    account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
fi
echo -e "${GREEN}✅ Authenticated as: $account${NC}"

# Enable required APIs
echo ""
echo -e "${YELLOW}🔧 Enabling required APIs (may take a minute)...${NC}"
gcloud services enable run.googleapis.com --quiet 2>/dev/null || true
gcloud services enable cloudbuild.googleapis.com --quiet 2>/dev/null || true
gcloud services enable containerregistry.googleapis.com --quiet 2>/dev/null || true
gcloud services enable secretmanager.googleapis.com --quiet 2>/dev/null || true
echo -e "${GREEN}✅ APIs enabled${NC}"

# Check for Gemini API key secret
echo ""
echo -e "${YELLOW}🔑 Checking for GEMINI_API_KEY secret...${NC}"
if ! gcloud secrets describe GEMINI_API_KEY &>/dev/null; then
    echo -e "${RED}❌ GEMINI_API_KEY secret not found${NC}"
    read -p "Enter your Gemini API Key (or press Enter to skip): " api_key
    if [ -n "$api_key" ]; then
        echo -e "${YELLOW}Creating secret...${NC}"
        echo -n "$api_key" | gcloud secrets create GEMINI_API_KEY --data-file=-
        
        # Grant access to Cloud Run
        project_number=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
        gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
            --member="serviceAccount:${project_number}-compute@developer.gserviceaccount.com" \
            --role="roles/secretmanager.secretAccessor" --quiet
        
        echo -e "${GREEN}✅ Secret created and access granted${NC}"
    else
        echo -e "${YELLOW}⚠️  Skipping secret creation - deployment may fail${NC}"
    fi
else
    echo -e "${GREEN}✅ GEMINI_API_KEY secret exists${NC}"
fi

# Deployment method selection
echo ""
echo -e "${CYAN}📋 Choose deployment method:${NC}"
echo "  1. Quick Deploy (from source - recommended for first time)"
echo "  2. Build & Deploy (using Dockerfile)"
echo "  3. Setup CI/CD (auto-deploy on git push)"
echo ""
read -p "Enter choice (1-3): " method

case "$method" in
    1)
        echo ""
        echo -e "${YELLOW}🚀 Deploying to Cloud Run from source...${NC}"
        echo -e "${YELLOW}This may take 5-10 minutes on first deployment...${NC}"
        
        gcloud run deploy "$SERVICE_NAME" \
            --source . \
            --region "$REGION" \
            --platform managed \
            --allow-unauthenticated \
            --memory "$MEMORY" \
            --cpu "$CPU" \
            --timeout "$TIMEOUT" \
            --max-instances "$MAX_INSTANCES" \
            --min-instances "$MIN_INSTANCES" \
            --port 8080 \
            --set-env-vars "ENVIRONMENT=production,PORT=8080" \
            --set-secrets "GEMINI_API_KEY=GEMINI_API_KEY:latest"
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}🔨 Building Docker image...${NC}"
        docker build -t "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest" .
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Build successful${NC}"
            
            echo -e "${YELLOW}📤 Pushing to Container Registry...${NC}"
            docker push "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest"
            
            echo -e "${YELLOW}🚀 Deploying to Cloud Run...${NC}"
            gcloud run deploy "$SERVICE_NAME" \
                --image "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest" \
                --region "$REGION" \
                --platform managed \
                --allow-unauthenticated \
                --memory "$MEMORY" \
                --cpu "$CPU" \
                --timeout "$TIMEOUT" \
                --max-instances "$MAX_INSTANCES" \
                --min-instances "$MIN_INSTANCES" \
                --port 8080 \
                --set-env-vars "ENVIRONMENT=production,PORT=8080" \
                --set-secrets "GEMINI_API_KEY=GEMINI_API_KEY:latest"
        else
            echo -e "${RED}❌ Build failed${NC}"
            exit 1
        fi
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}🔗 Setting up CI/CD with Cloud Build...${NC}"
        echo ""
        echo -e "${CYAN}Prerequisites:${NC}"
        echo "  1. Your code must be in a GitHub repository"
        echo "  2. You need to connect GitHub to Cloud Build first"
        echo ""
        echo -e "${YELLOW}Visit: https://console.cloud.google.com/cloud-build/triggers${NC}"
        echo -e "${YELLOW}Then run this command:${NC}"
        echo ""
        echo "gcloud beta builds triggers create github \\"
        echo "  --repo-name=sortyx_cloud_backend \\"
        echo "  --repo-owner=AtharvaPatange \\"
        echo "  --branch-pattern='^main$' \\"
        echo "  --build-config=backend/cloudbuild.yaml"
        echo ""
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

# Check deployment status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo ""
    
    # Get service URL
    echo -e "${YELLOW}🌍 Getting service URL...${NC}"
    service_url=$(gcloud run services describe "$SERVICE_NAME" \
        --region "$REGION" \
        --format="value(status.url)")
    
    echo ""
    echo -e "${CYAN}================================================${NC}"
    echo -e "${GREEN}🎉 Your backend is live!${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""
    echo -e "Service URL: ${service_url}"
    echo ""
    echo -e "${CYAN}📝 Next steps:${NC}"
    echo "  1. Test health endpoint:"
    echo -e "     ${YELLOW}curl ${service_url}/api/health${NC}"
    echo ""
    echo "  2. Update your frontend config.js:"
    echo -e "     ${YELLOW}API_URL: '${service_url}'${NC}"
    echo ""
    echo "  3. View logs:"
    echo -e "     ${YELLOW}gcloud run services logs tail $SERVICE_NAME --region $REGION${NC}"
    echo ""
    echo "  4. View in console:"
    echo -e "     ${YELLOW}https://console.cloud.google.com/run?project=$PROJECT_ID${NC}"
    echo ""
    
else
    echo ""
    echo -e "${RED}❌ Deployment failed${NC}"
    echo ""
    echo -e "${YELLOW}Check logs with:${NC}"
    echo "gcloud builds list --limit 1"
    echo ""
    exit 1
fi
