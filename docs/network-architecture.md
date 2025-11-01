# Network Architecture and Traffic Flow

## Overview

This document describes the network architecture and traffic flow for the Kubernetes Raspberry Pi cluster deployment.

## Network Topology

```
Internet
    │
    ▼
UDM Dream Machine Router (192.168.1.1)
    │
    ├─── MetalLB Load Balancer (192.168.1.240-250)
    │         │
    │         ▼
    │    Traefik Ingress Controller
    │         │
    │         ▼
    ├─── Kubernetes Cluster
    │    ├─── node1 (Control Plane) - 192.168.1.10
    │    ├─── node2 (Worker) - 192.168.1.11
    │    ├─── node3 (Worker) - 192.168.1.12
    │    └─── node4 (Worker) - 192.168.1.13
    │
    └─── Synology NAS (192.168.1.100)
```

## IP Address Allocation

### Network Configuration
- **Network**: 192.168.1.0/24
- **Gateway**: 192.168.1.1 (UDM Router)
- **DNS**: 192.168.1.1 (UDM Router)

### Kubernetes Cluster
- **Control Plane**: 192.168.1.10 (node1)
- **Worker Nodes**: 192.168.1.11-13 (node2-4)
- **Pod Subnet**: 10.244.0.0/16
- **Service Subnet**: 10.96.0.0/12

### Load Balancer
- **MetalLB Range**: 192.168.1.240-250
- **Traefik External IP**: 192.168.1.240
- **Sample App External IP**: 192.168.1.241

### Storage
- **Synology NAS**: 192.168.1.100
- **NFS Share**: /volume1/k8s-storage

## Traffic Flow Diagrams

### 1. External User Accessing Web Application

```
User Browser
    │
    ▼
Internet (HTTPS/80)
    │
    ▼
UDM Router (Port Forward 80/443 → 192.168.1.240)
    │
    ▼
MetalLB Load Balancer (192.168.1.240)
    │
    ▼
Traefik Ingress Controller
    │
    ▼
Kubernetes Service (ClusterIP)
    │
    ▼
Kubernetes Pod (Application Container)
```

### 2. Internal Cluster Communication

```
Control Plane (node1)
    │
    ├─── etcd (Cluster State)
    ├─── kube-apiserver (API Server)
    ├─── kube-controller-manager (Controllers)
    └─── kube-scheduler (Scheduler)
    │
    ▼
Worker Nodes (node2, node3, node4)
    │
    ├─── kubelet (Node Agent)
    ├─── kube-proxy (Network Proxy)
    └─── Application Pods
```

### 3. Storage Access Flow

```
Application Pod
    │
    ▼
PersistentVolumeClaim (PVC)
    │
    ▼
StorageClass (nfs-storage)
    │
    ▼
NFS Subdir External Provisioner
    │
    ▼
Synology NAS (192.168.1.100:/volume1/k8s-storage)
```

## Port Configuration

### UDM Router Port Forwards
- **Port 80** → 192.168.1.240 (HTTP)
- **Port 443** → 192.168.1.240 (HTTPS)
- **Port 9000** → 192.168.1.240 (Traefik Dashboard)

### Kubernetes Services
- **Traefik**: 80, 443, 9000
- **Prometheus**: 9090
- **Grafana**: 3000
- **Sample App**: 80

## Network Security

### Firewall Rules
- **External Access**: Only ports 80, 443, 9000
- **Internal Cluster**: Full communication between nodes
- **Storage Access**: NFS port 2049 from cluster to NAS

### Security Groups
- **Control Plane**: Full cluster access
- **Worker Nodes**: Limited to necessary services
- **Load Balancer**: External access + cluster access

## DNS Configuration

### External Access (nip.io)
- **Traefik Dashboard**: traefik.192.168.1.0.nip.io
- **Grafana**: grafana.192.168.1.0.nip.io
- **Sample App**: app.192.168.1.0.nip.io

### Internal Cluster
- **Service Discovery**: Kubernetes DNS (10.96.0.10)
- **Node Communication**: Direct IP addressing

## Load Balancing Strategy

### MetalLB Configuration
- **Mode**: Layer 2
- **IP Range**: 192.168.1.240-250
- **Protocol**: ARP for IP assignment

### Traefik Load Balancing
- **Algorithm**: Round Robin
- **Health Checks**: HTTP probes
- **Session Affinity**: Configurable per service

## Monitoring and Observability

### Network Monitoring
- **Prometheus**: Collects metrics from all nodes
- **Grafana**: Visualizes network performance
- **Traefik**: Access logs and metrics

### Traffic Analysis
- **Packet Capture**: Available on UDM router
- **Flow Logs**: Kubernetes network policies
- **Service Mesh**: Optional Istio integration

## Troubleshooting

### Common Network Issues
1. **MetalLB IP Conflict**: Check for duplicate IPs
2. **Traefik Not Accessible**: Verify port forwarding
3. **Pod Communication**: Check CNI configuration
4. **Storage Access**: Verify NFS connectivity

### Diagnostic Commands
```bash
# Check cluster networking
kubectl get nodes -o wide
kubectl get pods -A -o wide

# Verify MetalLB
kubectl get svc -A
kubectl describe svc -n metallb-system

# Test connectivity
kubectl exec -it <pod> -- ping <target>
kubectl exec -it <pod> -- curl <service>
```

## Future Enhancements

### Planned Improvements
- **SSL/TLS Termination**: Let's Encrypt integration
- **Service Mesh**: Istio or Linkerd deployment
- **Network Policies**: Enhanced security rules
- **Multi-cluster**: Federation capabilities
- **CDN Integration**: CloudFlare or similar
