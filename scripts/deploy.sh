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
INVENTORY_FILE="$PROJECT_DIR/inventory.ini"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Ansible is installed
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Check if inventory file exists
    if [ ! -f "$INVENTORY_FILE" ]; then
        log_error "Inventory file not found: $INVENTORY_FILE"
        log_info "Please copy inventory.example to inventory.ini and configure it."
        exit 1
    fi
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/homelab-k8s-pi ]; then
        log_error "SSH private key not found: ~/.ssh/homelab-k8s-pi"
        log_info "Please generate an SSH key pair first."
        exit 1
    fi
    
    log_info "Prerequisites check passed."
}

test_connectivity() {
    log_info "Testing connectivity to Raspberry Pi nodes..."
    
    # Test SSH connectivity to all nodes
    ansible all -i "$INVENTORY_FILE" -m ping
    
    if [ $? -eq 0 ]; then
        log_info "Connectivity test passed."
    else
        log_error "Connectivity test failed. Please check your network configuration."
        exit 1
    fi
}

deploy_cluster() {
    log_info "Starting Kubernetes cluster deployment..."
    
    # Run the main playbook
    cd "$PROJECT_DIR/ansible" && ansible-playbook -i "$INVENTORY_FILE" playbooks/main.yml -v && cd -
    
    if [ $? -eq 0 ]; then
        log_info "Kubernetes cluster deployment completed successfully!"
    else
        log_error "Cluster deployment failed. Please check the logs above."
        exit 1
    fi
}

post_deployment_checks() {
    log_info "Running post-deployment checks..."
    
    # Get the control plane node
    CONTROL_PLANE=$(ansible-inventory -i "$INVENTORY_FILE" --list | jq -r '.control_plane.hosts[0]')
    
    if [ -z "$CONTROL_PLANE" ]; then
        log_error "Could not determine control plane node."
        exit 1
    fi
    
    # Copy kubeconfig from control plane
    log_info "Copying kubeconfig from control plane node..."
    scp "$CONTROL_PLANE:/home/yuklia/.kube/config" ~/.kube/config
    
    # Test kubectl access
    log_info "Testing kubectl access..."
    kubectl get nodes
    
    if [ $? -eq 0 ]; then
        log_info "Kubernetes cluster is accessible!"
    else
        log_error "Failed to access Kubernetes cluster."
        exit 1
    fi
}

show_access_info() {
    log_info "Cluster deployment completed successfully!"
    echo
    echo "Access Information:"
    echo "=================="
    echo "Kubernetes Dashboard: kubectl proxy"
    echo "Traefik Dashboard: http://traefik.<your-network>.nip.io"
    echo "Grafana: http://grafana.<your-network>.nip.io"
    echo
    echo "Default credentials:"
    echo "Grafana: admin / prom-operator"
    echo
    echo "To access your cluster:"
    echo "kubectl get nodes"
    echo "kubectl get pods -A"
}

# Main execution
main() {
    log_info "Starting Kubernetes Raspberry Pi cluster deployment..."
    
    check_prerequisites
    test_connectivity
    deploy_cluster
    post_deployment_checks
    show_access_info
    
    log_info "Deployment completed successfully!"
}

# Run main function
main "$@"
