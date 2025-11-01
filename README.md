# Bare Metal k8s on Raspberry Pi Cluster 4 nodes

This project provides a fully automated Ansible-based solution to deploy a production-ready Kubernetes cluster on 4 Raspberry Pi instances.

## Architecture Overview

```
Internet → UDM Router → MetalLB → Traefik Ingress → Kubernetes Services
```

### Node Configuration
- **node1**: Kubernetes Control Plane (Manager)
- **node2**: Kubernetes Worker Node
- **node3**: Kubernetes Worker Node  
- **node4**: Kubernetes Worker Node

### Network Flow
1. User accesses website from browser
2. Traffic routes through UDM Router
3. MetalLB load balancer distributes traffic
4. Traefik Ingress Controller routes to appropriate services
5. Kubernetes pods serve the application

## Prerequisites

### Hardware Requirements
- 4x Raspberry Pi 5 (8GB RAM recommended)
- 4x 64GB+ SD cards
- Network switch/router (UDM Dream Machine)
- Synology NAS for persistent storage

### Software Requirements
- Ansible 2.12+
- Python 3.8+
- Go 1.19+
- kubectl
- helm
- kustomize

## Raspberry Pi Inital Setup (Manual)

### SD Card Preparation

1. **Download Raspberry Pi Imager**:
   - Visit [raspberrypi.com/software](https://www.raspberrypi.com/software/)
   - Download and install Raspberry Pi Imager for your operating system
   - Raspberry Pi Imager is available for Windows, macOS, and Linux

2. **Prepare SD Cards**:
   - Insert a 64GB+ SD card into your computer
   - Open Raspberry Pi Imager
   - Click "Choose OS" and select "Raspberry Pi OS (other)"
   - Choose "Raspberry Pi OS Lite (64-bit)" (recommended for headless servers)
   - Click "Choose Storage" and select your SD card
   - **Important**: Click the gear icon (⚙️) to configure advanced options:
     - Set hostname (e.g., `node1`, `node2`, `node3`, `node4`)
     - Enable SSH
     - **Enable public key authentication only** (disable password authentication)
     - Add your SSH public key for secure access
     - Configure wireless LAN if using WiFi
   - Click "Write" to flash the SD card
   - Repeat for all 4 Raspberry Pi instances

### Node Configuration

Each Raspberry Pi node should be configured with the following usernames:
- **node1**: Username `yuklia`
- **node2**: Username `yuklia` 
- **node3**: Username `yuklia`
- **node4**: Username `yuklia`

### Network Configuration

The Kubernetes cluster operates on a dedicated VLAN configured on the UDM router:
- **VLAN Network**: 192.168.101.0/24
- **Purpose**: Isolated network for Kubernetes cluster traffic
- **Benefits**: Network segmentation, security isolation, dedicated bandwidth

Ensure all Raspberry Pi nodes are connected to this VLAN for optimal cluster performance and security.

### Raspberry Pi OS Lite 64-bit Benefits

- **Lightweight**: Minimal resource usage, ideal for Kubernetes nodes
- **64-bit Support**: Full ARM64 architecture support for better performance
- **Headless Operation**: No GUI overhead, perfect for server deployments
- **Security**: Regular security updates and patches
- **Compatibility**: Optimized for Raspberry Pi 4 hardware

### Post-Installation Steps

1. **First Boot**:
   - Insert SD card into Raspberry Pi
   - Power on and wait for first boot to complete
   - The Pi will automatically expand the filesystem

2. **Network Configuration**:
   - Ensure all Pis are connected to the UDM VLAN 192.168.101.0/24
   - Note the IP addresses assigned to each Pi on the VLAN
   - Verify SSH connectivity using public key authentication:
     ```bash
     ssh yuklia@192.168.101.11 -i ~/.ssh/homelab-k8s-pi
     ssh yuklia@192.168.101.12 -i ~/.ssh/homelab-k8s-pi
     ssh yuklia@192.168.101.13 -i ~/.ssh/homelab-k8s-pi
     ssh yuklia@192.168.101.14 -i ~/.ssh/homelab-k8s-pi
     ```

3. **Update System**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   ```

4. **Verify 64-bit Architecture**:
   ```bash
   uname -m
   # Should return: aarch64
   ```

## Quick Start

1. **Clone and setup**:
   ```bash
   cd bm-k8s-pi
   ./scripts/setup.sh
   ```

2. **Configure inventory**:
   ```bash
   cp inventory.example inventory.ini
   # Edit inventory.ini with your Pi IP addresses
   ```

3. **Deploy cluster**:
   ```bash
   ./scripts/deploy.sh
   ```

4. **Access cluster**:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

## Project Structure

```
bm-k8s-pi/
├── ansible/                 # Ansible playbooks and roles
│   ├── group_vars/         # Group variables
│   ├── host_vars/          # Host-specific variables
│   ├── roles/              # Reusable Ansible roles
│   └── playbooks/          # Main playbooks
├── helm/                   # Helm charts
├── kustomize/              # Kustomize overlays
├── scripts/                # Automation scripts
├── docs/                   # Documentation and schemas
└── terraform/              # Infrastructure as code (optional)
```

## Features

- ✅ Automated Kubernetes installation
- ✅ MetalLB load balancer
- ✅ Traefik ingress controller with HTTPS
- ✅ Persistent storage with Synology NAS
- ✅ Monitoring and logging stack
- ✅ Security hardening
- ✅ Backup and recovery procedures

## Documentation

- [Network Architecture](docs/network-architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Maintenance](docs/maintenance.md)
