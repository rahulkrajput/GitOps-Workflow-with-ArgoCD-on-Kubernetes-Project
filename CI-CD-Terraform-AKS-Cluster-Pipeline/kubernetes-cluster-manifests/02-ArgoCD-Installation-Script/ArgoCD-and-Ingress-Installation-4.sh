#!/bin/bash

# Set error handling
set -e

echo "🚀 Starting ArgoCD deployment automation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists kubectl; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if namespace exists
if kubectl get namespace argocd >/dev/null 2>&1; then
    echo "✅ ArgoCD namespace already exists"
else
    echo "📑 Creating ArgoCD namespace..."
    kubectl create namespace argocd
fi

echo "📦 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "🔧 Patching ArgoCD server deployment to add '--insecure' flag..."
kubectl patch deployment argocd-server -n argocd --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

echo "📝 Updating ArgoCD ConfigMap..."
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge \
    -p '{"data":{"server.rootpath":"/argo","server.insecure":"true"}}'

echo "🌐 Creating Ingress resource..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF

echo "🔄 Restarting ArgoCD server deployment..."
kubectl rollout restart deployment argocd-server -n argocd

echo "⏳ Waiting for ArgoCD server to be ready (this may take a few minutes)..."
if kubectl rollout status deployment argocd-server -n argocd --timeout=300s; then
    echo "✅ ArgoCD server deployment successfully restarted"
else
    echo "❌ ArgoCD server deployment failed to restart within the timeout period"
    exit 1
fi

# Get initial admin password
echo "🔑 Retrieving initial admin password..."
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "✅ ArgoCD deployment completed!"
echo "📋 Installation Summary:"
echo "------------------------"
echo "Username: admin"
echo "Password: $ARGO_PASSWORD"
echo "URL: http://<your-ingress-ip>/"
echo "------------------------"

# Verify deployment
echo "📊 Deployment Status:"
echo "ArgoCD Pods:"
kubectl get pods -n argocd
echo "ArgoCD Service:"
kubectl get svc argocd-server -n argocd
echo "ArgoCD Ingress:"
kubectl get ingress argocd-ingress -n argocd   