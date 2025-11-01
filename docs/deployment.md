# Deployment Guide

## Prerequisites

### Hardware Requirements
- 4x Raspberry Pi 5 (8GB RAM recommended)
- 4x 64GB+ SD cards (Class 10 or better)
- Network switch/router (UDM Dream Machine)
- Synology NAS for persistent storage
- Ethernet cables for all nodes

### Software Requirements
- Ansible 2.12+
- Python 3.8+
- Go 1.19+
- kubectl
- helm
- kustomize

### Network Requirements
- Static IP addresses for all Raspberry Pi nodes
- Port forwarding configured on UDM router
- NFS share configured on Synology NAS

## Pre-Deployment Setup

### 1. Prepare Raspberry Pi Nodes

#### Flash SD Cards
```bash
# Download Raspberry Pi OS Lite (64-bit)
# Use Raspberry Pi Imager or similar tool
# Enable SSH and set hostnames during imaging
```

#### Configure Network
```bash
# Edit /etc/dhcpcd.conf on each Pi
interface eth0
static ip_address=192.168.1.10/24  # node1
static ip_address=192.168.1.11/24  # node2
static ip_address=192.168.1.12/24  # node3
static ip_address=192.168.1.13/24  # node4
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

#### Set Hostnames
```bash
# On each Pi, edit /etc/hostname
# node1, node2, node3, node4
```

### 2. Configure UDM Router

#### Port Forwarding
- **Port 80** → 192.168.1.240 (HTTP)
- **Port 443** → 192.168.1.240 (HTTPS)
- **Port 9000** → 192.168.1.240 (Traefik Dashboard)

#### DHCP Reservations
- Reserve IP addresses for all Pi nodes
- Ensure MetalLB range (192.168.1.240-250) is excluded

### 3. Configure Synology NAS

#### NFS Share Setup
```bash
# Create shared folder: k8s-storage
# Enable NFS service
# Configure NFS permissions for cluster access
# Share path: /volume1/k8s-storage
```

#### NFS Export Configuration
```bash
# /etc/exports
/volume1/k8s-storage 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

## Deployment Steps

### Step 1: Project Setup

```bash
# Clone the project
git clone <repository-url>
cd bm-k8s-pi

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### Step 2: Configure Inventory

```bash
# Copy and edit inventory file
cp inventory.example inventory.ini
nano inventory.ini

# Update IP addresses and configuration
# Ensure all variables match your network setup
```

### Step 3: Deploy Cluster

```bash
# Run deployment script
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Step 4: Verify Deployment

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Verify services
kubectl get svc -A
kubectl get storageclass
```

## Post-Deployment Configuration

### 1. Configure DNS (Optional)

#### Local DNS Resolution
```bash
# Add to /etc/hosts on your local machine
192.168.1.240 traefik.local
192.168.1.240 grafana.local
192.168.1.240 app.local
```

#### Public Domain (Recommended)
```bash
# Configure your domain registrar
# Point A records to your public IP
# Update Traefik configuration for SSL
```

### 2. SSL/TLS Configuration

#### Let's Encrypt Integration
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Configure ClusterIssuer for Let's Encrypt
# Update ingress annotations for SSL
```

### 3. Monitoring Setup

#### Grafana Dashboards
```bash
# Access Grafana at http://grafana.<your-network>.nip.io
# Default credentials: admin / prom-operator
# Import Kubernetes dashboards
```

#### Alerting Configuration
```bash
# Configure Prometheus alerting rules
# Set up notification channels
# Test alert delivery
```

## Application Deployment

### 1. Deploy Sample Application

```bash
# Apply base configuration
kubectl apply -k kustomize/base/

# Check deployment status
kubectl get pods -l app=sample-app
kubectl get svc sample-app
kubectl get ingress sample-app
```

### 2. Custom Application Deployment

#### Using Helm
```bash
# Create custom Helm chart
helm create myapp

# Deploy with custom values
helm install myapp ./myapp --values values.yaml
```

#### Using Kustomize
```bash
# Create overlay for production
mkdir -p kustomize/overlays/prod

# Apply production configuration
kubectl apply -k kustomize/overlays/prod/
```

## Troubleshooting

### Common Issues

#### 1. MetalLB IP Assignment
```bash
# Check MetalLB status
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l app=metallb

# Verify IP range configuration
kubectl get ipaddresspools -n metallb-system
```

#### 2. Traefik Not Accessible
```bash
# Check Traefik pods
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Verify service configuration
kubectl get svc -n traefik
kubectl describe svc traefik -n traefik
```

#### 3. Storage Issues
```bash
# Check NFS provisioner
kubectl get pods -n storage
kubectl logs -n storage -l app=nfs-subdir-external-provisioner

# Test NFS connectivity
kubectl exec -it <pod> -- mount | grep nfs
```

### Diagnostic Commands

```bash
# Cluster health check
kubectl get componentstatuses
kubectl get events --sort-by='.lastTimestamp'

# Network connectivity
kubectl exec -it <pod> -- ping <target>
kubectl exec -it <pod> -- curl <service>

# Resource usage
kubectl top nodes
kubectl top pods
```

## Maintenance

### Regular Tasks

#### 1. Backup
```bash
# Backup etcd
kubectl exec -n kube-system etcd-<node> -- etcdctl snapshot save /tmp/backup.db

# Backup persistent volumes
# Use your NAS backup solution
```

#### 2. Updates
```bash
# Update Kubernetes
kubectl drain <node> --ignore-daemonsets
# Update node
kubectl uncordon <node>

# Update applications
helm upgrade <release> <chart>
```

#### 3. Monitoring
```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A

# Review logs
kubectl logs -n <namespace> <pod>
```