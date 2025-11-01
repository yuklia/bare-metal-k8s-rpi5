#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_os() {
    log_info "Checking operating system..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "macOS detected. Installing dependencies via Homebrew..."
        install_macos_deps
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "Linux detected. Installing dependencies via package manager..."
        install_linux_deps
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

install_macos_deps() {
    log_info "Installing macOS dependencies..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install required packages
    log_info "Installing required packages..."
    brew install ansible kubectl helm kustomize go jq
    
    log_info "macOS dependencies installed successfully."
}

install_linux_deps() {
    log_info "Installing Linux dependencies..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        log_info "Installing Ubuntu/Debian dependencies..."
        sudo apt-get update
        sudo apt-get install -y ansible kubectl helm kustomize golang-go jq
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        log_info "Installing CentOS/RHEL dependencies..."
        sudo yum install -y epel-release
        sudo yum install -y ansible kubectl helm kustomize golang jq
    else
        log_error "Unsupported Linux distribution. Please install dependencies manually."
        exit 1
    fi
    
    log_info "Linux dependencies installed successfully."
}

setup_ssh_keys() {
    log_info "Setting up SSH keys..."
    
    if [ ! -f ~/.ssh/homelab-k8s-pi ]; then
        log_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/homelab-k8s-pi -N ""
        log_info "SSH key pair generated successfully."
    else
        log_info "SSH key pair already exists."
    fi
    
    log_info "SSH public key:"
    cat ~/.ssh/homelab-k8s-pi.pub
    echo
    log_warn "Please add this public key to your Raspberry Pi nodes."
}

setup_inventory() {
    log_info "Setting up Ansible inventory..."
    
    if [ ! -f "$PROJECT_DIR/inventory.ini" ]; then
        log_info "Creating inventory.ini from template..."
        cp "$PROJECT_DIR/inventory.example" "$PROJECT_DIR/inventory.ini"
        log_warn "Please edit inventory.ini with your Raspberry Pi IP addresses."
    else
        log_info "Inventory file already exists."
    fi
}

install_helm_repos() {
    log_info "Adding Helm repositories..."
    
    helm repo add traefik https://traefik.github.io/charts
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
    
    helm repo update
    
    log_info "Helm repositories added successfully."
}

create_sample_app() {
    log_info "Creating sample application manifests..."
    
    mkdir -p "$PROJECT_DIR/kustomize/base"
    mkdir -p "$PROJECT_DIR/kustomize/overlays/prod"
    
    # Create base kustomization
    cat > "$PROJECT_DIR/kustomize/base/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml

commonLabels:
  app: sample-app
EOF

    # Create sample deployment
    cat > "$PROJECT_DIR/kustomize/base/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

    # Create sample service
    cat > "$PROJECT_DIR/kustomize/base/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

    # Create sample ingress
    cat > "$PROJECT_DIR/kustomize/base/ingress.yaml" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: app.{{ ansible_default_ipv4.network }}.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF

    log_info "Sample application manifests created successfully."
}

# Main execution
main() {
    log_info "Setting up Kubernetes Raspberry Pi cluster project..."
    
    check_os
    setup_ssh_keys
    setup_inventory
    install_helm_repos
    create_sample_app
    
    log_info "Setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Edit inventory.ini with your Raspberry Pi IP addresses"
    echo "2. Add SSH public key to your Raspberry Pi nodes"
    echo "3. Run ./scripts/deploy.sh to deploy the cluster"
}

# Run main function
main "$@"
