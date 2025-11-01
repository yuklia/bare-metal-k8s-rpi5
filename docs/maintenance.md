# Maintenance Guide

## Regular Maintenance Tasks

### Daily Tasks

#### Cluster Health Check
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Verify critical services
kubectl get pods -n kube-system
kubectl get pods -n metallb-system
kubectl get pods -n traefik
```

#### Resource Monitoring
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Monitor storage usage
kubectl get pvc -A
kubectl get pv
```

### Weekly Tasks

#### Backup Operations
```bash
# Create etcd backup
kubectl exec -n kube-system etcd-<node> -- etcdctl snapshot save /tmp/backup-$(date +%Y%m%d).db

# Backup persistent volumes
# Use your NAS backup solution for NFS data

# Backup configurations
kubectl get all -A -o yaml > cluster-backup-$(date +%Y%m%d).yaml
```

#### Log Analysis
```bash
# Check system logs
sudo journalctl -u kubelet --since "1 week ago" | grep -i error

# Analyze pod logs
kubectl logs -n kube-system -l component=etcd --since=168h
kubectl logs -n traefik -l app.kubernetes.io/name=traefik --since=168h
```

#### Security Updates
```bash
# Check for security vulnerabilities
kubectl get pods -A -o json | jq '.items[] | select(.spec.containers[].image | contains("vulnerable"))'

# Update base images
kubectl set image deployment/<name> <container>=<new-image> -n <namespace>
```

### Monthly Tasks

#### System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Kubernetes components
sudo apt update
sudo apt install -y kubelet=<new-version> kubeadm=<new-version> kubectl=<new-version>
```

#### Performance Optimization
```bash
# Analyze resource usage patterns
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Optimize resource requests/limits
kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,CPU_LIMIT:.spec.containers[*].resources.limits.cpu
```

#### Network Optimization
```bash
# Check network policies
kubectl get networkpolicies -A

# Monitor network performance
kubectl top pods -A | grep -E "(traefik|ingress)"

# Analyze service endpoints
kubectl get endpoints -A
```

## Update Procedures

### Kubernetes Version Updates

#### Control Plane Update
```bash
# 1. Backup etcd
kubectl exec -n kube-system etcd-<node> -- etcdctl snapshot save /tmp/backup.db

# 2. Update control plane
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v<new-version>

# 3. Update kubelet
sudo apt update
sudo apt install -y kubelet=<new-version>
sudo systemctl restart kubelet
```

#### Worker Node Updates
```bash
# 1. Drain node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 2. Update packages
sudo apt update
sudo apt install -y kubelet=<new-version> kubeadm=<new-version>

# 3. Update kubelet
sudo systemctl restart kubelet

# 4. Uncordon node
kubectl uncordon <node-name>
```

### Application Updates

#### Helm Chart Updates
```bash
# Check for updates
helm repo update
helm list -A

# Update specific release
helm upgrade <release-name> <chart> -n <namespace>

# Rollback if needed
helm rollback <release-name> <revision> -n <namespace>
```

#### Kustomize Updates
```bash
# Apply updated configuration
kubectl apply -k kustomize/overlays/prod/

# Verify changes
kubectl get pods -A
kubectl rollout status deployment/<name> -n <namespace>
```

## Backup and Recovery

### Backup Strategy

#### etcd Backups
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/etcd"
mkdir -p $BACKUP_DIR

# Find etcd pod
ETCD_POD=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].metadata.name}')

# Create backup
kubectl exec -n kube-system $ETCD_POD -- etcdctl snapshot save /tmp/backup.db

# Copy backup to host
kubectl cp kube-system/$ETCD_POD:/tmp/backup.db $BACKUP_DIR/etcd-backup-$DATE.db

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "etcd-backup-*.db" -mtime +7 -delete
```

#### Configuration Backups
```bash
# Backup all resources
kubectl get all -A -o yaml > cluster-backup-$(date +%Y%m%d).yaml

# Backup specific namespaces
kubectl get all -n <namespace> -o yaml > <namespace>-backup-$(date +%Y%m%d).yaml

# Backup persistent volumes
kubectl get pv -o yaml > pv-backup-$(date +%Y%m%d).yaml
kubectl get pvc -A -o yaml > pvc-backup-$(date +%Y%m%d).yaml
```

#### Storage Backups
```bash
# NFS data backup
rsync -av /volume1/k8s-storage/ /volume1/backup/k8s-storage-$(date +%Y%m%d)/

# Database backups (if applicable)
kubectl exec -n <namespace> <pod-name> -- pg_dump <database> > backup-$(date +%Y%m%d).sql
```

### Recovery Procedures

#### etcd Recovery
```bash
# 1. Stop kubelet
sudo systemctl stop kubelet

# 2. Restore etcd
sudo kubeadm reset
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12

# 3. Restore data
sudo kubeadm init phase etcd local --experimental-upload-certs
sudo kubeadm join phase control-plane-prepare all
sudo kubeadm join phase control-plane-join etcd
```

#### Application Recovery
```bash
# Restore from backup
kubectl apply -f cluster-backup-$(date +%Y%m%d).yaml

# Verify restoration
kubectl get all -A
kubectl get pv
kubectl get pvc -A
```

## Performance Monitoring

### Resource Monitoring

#### CPU and Memory
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -A

# Resource requests/limits analysis
kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEMORY_REQ:.spec.containers[*].resources.requests.memory,MEMORY_LIMIT:.spec.containers[*].resources.limits.memory
```

#### Storage Monitoring
```bash
# Storage usage
kubectl get pvc -A
kubectl get pv

# Storage class analysis
kubectl get storageclass
kubectl describe storageclass <class-name>
```

### Network Monitoring

#### Service Performance
```bash
# Service endpoints
kubectl get endpoints -A

# Network policies
kubectl get networkpolicies -A

# Ingress status
kubectl get ingress -A
kubectl describe ingress <name> -n <namespace>
```

#### Load Balancer Status
```bash
# MetalLB status
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system

# Traefik status
kubectl get pods -n traefik
kubectl get svc -n traefik
```

## Security Maintenance

### Access Control

#### RBAC Review
```bash
# Check roles and bindings
kubectl get roles -A
kubectl get rolebindings -A
kubectl get clusterroles
kubectl get clusterrolebindings

# Review service accounts
kubectl get serviceaccounts -A
```

#### Network Policies
```bash
# Review network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy <name> -n <namespace>

# Test policy enforcement
kubectl exec -it <pod> -n <namespace> -- ping <target>
```

### Vulnerability Management

#### Image Scanning
```bash
# Check for vulnerable images
kubectl get pods -A -o json | jq '.items[] | select(.spec.containers[].image | contains("vulnerable"))'

# Update base images
kubectl set image deployment/<name> <container>=<new-image> -n <namespace>
```

#### Security Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update container runtime
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

## Automation Scripts

### Health Check Script
```bash
#!/bin/bash
# health-check.sh

echo "=== Kubernetes Cluster Health Check ==="
echo "Date: $(date)"
echo ""

# Check nodes
echo "Node Status:"
kubectl get nodes -o wide
echo ""

# Check pods
echo "Pod Status:"
kubectl get pods -A --field-selector=status.phase!=Running
echo ""

# Check services
echo "Service Status:"
kubectl get svc -A
echo ""

# Check storage
echo "Storage Status:"
kubectl get pvc -A
echo ""

# Resource usage
echo "Resource Usage:"
kubectl top nodes --no-headers | head -5
echo ""
```

### Backup Script
```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/cluster"

echo "Starting cluster backup at $DATE"
mkdir -p $BACKUP_DIR

# Backup etcd
echo "Backing up etcd..."
ETCD_POD=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kube-system $ETCD_POD -- etcdctl snapshot save /tmp/backup.db
kubectl cp kube-system/$ETCD_POD:/tmp/backup.db $BACKUP_DIR/etcd-backup-$DATE.db

# Backup configurations
echo "Backing up configurations..."
kubectl get all -A -o yaml > $BACKUP_DIR/cluster-backup-$DATE.yaml
kubectl get pv -o yaml > $BACKUP_DIR/pv-backup-$DATE.yaml
kubectl get pvc -A -o yaml > $BACKUP_DIR/pvc-backup-$DATE.yaml

# Cleanup old backups
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
find $BACKUP_DIR -name "*.yaml" -mtime +7 -delete

echo "Backup completed successfully"
```

### Update Script
```bash
#!/bin/bash
# update.sh

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <kubernetes-version>"
    exit 1
fi

echo "Updating Kubernetes to version $VERSION"

# Update packages
sudo apt update
sudo apt install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION

# Update control plane
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v$VERSION

# Restart kubelet
sudo systemctl restart kubelet

echo "Update completed successfully"
```

## Maintenance Schedule

### Daily (Automated)
- [ ] Cluster health check
- [ ] Resource monitoring
- [ ] Log analysis

### Weekly (Manual)
- [ ] Backup operations
- [ ] Security review
- [ ] Performance analysis

### Monthly (Manual)
- [ ] System updates
- [ ] Kubernetes updates
- [ ] Security patches

### Quarterly (Manual)
- [ ] Architecture review
- [ ] Capacity planning
- [ ] Disaster recovery testing

## Documentation

### Maintenance Log
Keep a detailed log of all maintenance activities:
- Date and time
- Type of maintenance
- Actions taken
- Results and observations
- Issues encountered
- Resolution steps

### Change Management
Document all changes to the cluster:
- Change request details
- Implementation plan
- Rollback procedures
- Testing results
- Approval and sign-off
