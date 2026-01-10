#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Courtmate Local K3d Setup Script                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# ============================================================================
# Step 1: Create Registry and Cluster
# ============================================================================
echo -e "\n${BLUE}Step 1: Creating k3d registry and cluster...${NC}"

# Check if registry already exists
if k3d registry list | grep -q "k3d-registry.localhost"; then
    echo -e "${YELLOW}Registry k3d-registry.localhost already exists, skipping...${NC}"
else
    echo "Creating registry..."
    k3d registry create registry.localhost --port 5000
    echo -e "${GREEN}✓ Registry created${NC}"
fi

# Check if cluster already exists
if k3d cluster list | grep -q "courtmate-local"; then
    echo -e "${YELLOW}Cluster courtmate-local already exists, skipping...${NC}"
else
    echo "Creating cluster with monitoring ports..."
    k3d cluster create courtmate-local --registry-use k3d-registry.localhost:5000 \
        -p "30000:30000@server:0" \
        -p "30091:30091@server:0" \
        -p "30092:30092@server:0"
    echo -e "${GREEN}✓ Cluster created${NC}"
fi

# Switch kubectl context
kubectl config use-context k3d-courtmate-local
echo -e "${GREEN}✓ Switched to k3d-courtmate-local context${NC}"

# ============================================================================
# Step 2: Create Secrets
# ============================================================================
echo -e "\n${BLUE}Step 2: Setting up secrets...${NC}"

# Check if secrets already exist
if kubectl get secret app-secrets &> /dev/null; then
    echo -e "${YELLOW}Secrets app-secrets already exist${NC}"
    read -p "Do you want to update them? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete secret app-secrets
    else
        echo -e "${GREEN}✓ Keeping existing secrets${NC}"
        SKIP_SECRETS=true
    fi
fi

if [ "$SKIP_SECRETS" != "true" ]; then
    kubectl create secret generic app-secrets \
      --from-literal=SUPABASE_URL="https://jpsixfhphercrvwkxnxa.supabase.co" \
      --from-literal=SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impwc2l4ZmhwaGVyY3J2d2t4bnhhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjQ5Nzk4OSwiZXhwIjoyMDc4MDczOTg5fQ.ZH3YuC0txZdrLAvY8oGXVmmZYsLK2G4HV0tYKCSugV8" \
      --from-literal=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impwc2l4ZmhwaGVyY3J2d2t4bnhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0OTc5ODksImV4cCI6MjA3ODA3Mzk4OX0.hnvouKuvjlP5ysCUOK2EaAiLhdCKVqVbPVxPrbCQHss" \
      --from-literal=SUPABASE_JWT_SECRET="ujpRvzhf2YBEFXMW+gbiHc0S9lR1pscnNJN02okeqyxWEd8KGG6WJiq4Wwm9Kgla7yO13mm15iZOKXUSzDyK6w==" \
      --from-literal=AUTH_SECRET="your_nextauth_secret" \
      --from-literal=AUTH_GOOGLE_ID="your_google_id" \
      --from-literal=AUTH_GOOGLE_SECRET="your_google_secret" \
      --from-literal=NEXT_PUBLIC_GOOGLE_MAPS_API_KEY="AIzaSyDlDX_qX-3kVzQ_SYt3ZD6b7ceWNTbPHT4"
    
    echo -e "${GREEN}✓ Secrets created${NC}"
fi

# ============================================================================
# Step 3: Build and Push Docker Images
# ============================================================================
echo -e "\n${BLUE}Step 3: Building and pushing Docker images...${NC}"

# UI
echo -e "${YELLOW}Building courtmate-ui...${NC}"
cd "$PROJECT_ROOT/Courtmate-ui"
docker build --no-cache -t localhost:5000/courtmate-ui:v1 .
docker push localhost:5000/courtmate-ui:v1
echo -e "${GREEN}✓ UI image pushed${NC}"

# User Service
echo -e "${YELLOW}Building user-service...${NC}"
cd "$PROJECT_ROOT/Courtmate-User-Service"
docker build -t localhost:5000/user-service:v1 .
docker push localhost:5000/user-service:v1
echo -e "${GREEN}✓ User Service image pushed${NC}"

# Court Service
echo -e "${YELLOW}Building court-service...${NC}"
cd "$PROJECT_ROOT/Courtmate-Court-Service"
docker build -t localhost:5000/court-service:v1 .
docker push localhost:5000/court-service:v1
echo -e "${GREEN}✓ Court Service image pushed${NC}"

# Booking Service
echo -e "${YELLOW}Building booking-service...${NC}"
cd "$PROJECT_ROOT/Courtmate-Booking-Service"
docker build -t localhost:5000/booking-service:v1 .
docker push localhost:5000/booking-service:v1
echo -e "${GREEN}✓ Booking Service image pushed${NC}"

# ============================================================================
# Step 4: Deploy to Kubernetes
# ============================================================================
echo -e "\n${BLUE}Step 4: Deploying to Kubernetes...${NC}"

cd "$PROJECT_ROOT"

# Apply deployments
echo -e "${YELLOW}Applying deployment manifests...${NC}"
kubectl apply -f Courtmate-Infra/k8s/deployments/
echo -e "${GREEN}✓ Deployments applied${NC}"

# Apply services
echo -e "${YELLOW}Applying service manifests...${NC}"
kubectl apply -f Courtmate-Infra/k8s/services/
echo -e "${GREEN}✓ Services applied${NC}"

# ============================================================================
# Step 5: Deploy Monitoring Stack
# ============================================================================
echo -e "\n${BLUE}Step 5: Deploying monitoring stack (Fluentd + Prometheus + Grafana)...${NC}"

# Create monitoring namespace
echo -e "${YELLOW}Creating monitoring namespace...${NC}"
kubectl apply -f Courtmate-Infra/k8s/namespaces/monitoring-namespace.yaml
echo -e "${GREEN}✓ Monitoring namespace created${NC}"

# Deploy Fluentd for logging
echo -e "${YELLOW}Deploying Fluentd for centralized logging...${NC}"
kubectl apply -f Courtmate-Infra/k8s/logging/
echo -e "${GREEN}✓ Fluentd deployed${NC}"

# Deploy Prometheus and Grafana for metrics
echo -e "${YELLOW}Deploying Prometheus and Grafana for metrics...${NC}"
kubectl apply -f Courtmate-Infra/k8s/monitoring/
echo -e "${GREEN}✓ Prometheus and Grafana deployed${NC}"

# ============================================================================
# Step 6: Wait for Rollout
# ============================================================================
echo -e "\n${BLUE}Step 6: Waiting for deployments to be ready...${NC}"

kubectl rollout status deployment/courtmate-ui --timeout=5m || true
kubectl rollout status deployment/user-service --timeout=5m || true
kubectl rollout status deployment/court-service --timeout=5m || true
kubectl rollout status deployment/booking-service --timeout=5m || true
kubectl rollout status deployment/prometheus -n monitoring --timeout=3m || true
kubectl rollout status deployment/grafana -n monitoring --timeout=3m || true

echo -e "${GREEN}✓ Deployments ready (or timed out)${NC}"

# ============================================================================
# Summary
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  Setup Complete! 🎉                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Access your application:${NC}"
echo -e "${YELLOW}  UI: http://localhost:30000${NC}"

echo -e "\n${GREEN}Useful commands:${NC}"
echo -e "${YELLOW}  View pods:${NC}              kubectl get pods"
echo -e "${YELLOW}  View logs:${NC}             kubectl logs -f deployment/<deployment-name>"
echo -e "${YELLOW}  View services:${NC}         kubectl get svc"
echo -e "${YELLOW}  Stop cluster:${NC}          k3d cluster stop courtmate-local"
echo -e "${YELLOW}  Start cluster:${NC}         k3d cluster start courtmate-local"
echo -e "${YELLOW}  Delete cluster:${NC}        k3d cluster delete courtmate-local"

echo -e "\n${GREEN}Next steps:${NC}"
echo -e "  1. Wait a few moments for pods to start"
echo -e "  2. Check pod status: kubectl get pods"
echo -e "  3. View any errors: kubectl logs -f deployment/<name>"
echo -e "  4. Access the app at http://localhost:30000"

echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  IMPORTANT: For Local Development (npm run dev)           ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${BLUE}If you're running the UI locally with 'npm run dev':${NC}"
echo -e "  You need to start port forwarding to connect to k3d services"
echo -e "\n${GREEN}Run this command in a separate terminal:${NC}"
echo -e "  ${YELLOW}./start-port-forward.sh${NC}"
echo -e "\n${BLUE}This will expose:${NC}"
echo -e "  - Booking Service at localhost:8002"
echo -e "  - Court Service at localhost:8001"
echo -e "  - User Service at localhost:8003"
