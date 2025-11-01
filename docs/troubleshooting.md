# Troubleshooting Guide

## Common Issues and Solutions

### 1. Cluster Initialization Issues

#### Problem: kubeadm init fails
```bash
# Check system requirements
kubectl get nodes
kubectl describe node <node-name>

# Verify system configuration
sudo swapoff -a
swapon --show
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

#### Solution: Reset and reinitialize
```bash
# On control plane node
sudo kubeadm reset
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12
```

### 2. Node Joining Issues

#### Problem: Worker nodes fail to join cluster
```bash
# Check join command
sudo kubeadm token create --print-join-command

# Verify network connectivity
ping <control-plane-ip>
telnet <control-plane-ip> 6443
```

#### Solution: Regenerate join token
```bash
# On control plane
sudo kubeadm token create --print-join-command

# On worker node
sudo kubeadm reset
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### 3. MetalLB Issues

#### Problem: External IPs not assigned
```bash
# Check MetalLB status
kubectl get pods -n metallb-system
kubectl logs -n metallb-system -l app=metallb

# Verify IP address pool
kubectl get ipaddresspools -n metallb-system
kubectl describe ipaddresspool -n metallb-system
```

#### Solution: Reconfigure IP pool
```bash
# Update IP range in inventory.ini
# Redeploy MetalLB
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

### 4. Traefik Issues

#### Problem: Traefik not accessible externally
```bash
# Check Traefik pods
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Verify service configuration
kubectl get svc -n traefik
kubectl describe svc traefik -n traefik
```

#### Solution: Check port forwarding and service type
```bash
# Ensure service is LoadBalancer type
kubectl patch svc traefik -n traefik -p '{"spec":{"type":"LoadBalancer"}}'

# Verify external IP assignment
kubectl get svc -n traefik -o wide
```

### 5. Storage Issues

#### Problem: NFS volumes not mounting
```bash
# Check NFS provisioner
kubectl get pods -n storage
kubectl logs -n storage -l app=nfs-subdir-external-provisioner

# Test NFS connectivity
kubectl exec -it <pod> -- mount | grep nfs
```

#### Solution: Verify NFS configuration
```bash
# Check Synology NAS NFS exports
# Ensure proper permissions
# Verify network connectivity to NAS
```

### 6. Network Connectivity Issues

#### Problem: Pods cannot communicate
```bash
# Check CNI status
kubectl get pods -n kube-system -l k8s-app=flannel
kubectl logs -n kube-system -l k8s-app=flannel

# Verify network policies
kubectl get networkpolicies -A
```

#### Solution: Restart CNI components
```bash
# Restart Flannel
kubectl delete pods -n kube-system -l k8s-app=flannel

# Check node network configuration
ip route show
ip link show
```

### 7. Resource Exhaustion

#### Problem: Nodes running out of resources
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check node capacity
kubectl describe node <node-name>
```

#### Solution: Resource management
```bash
# Set resource limits in deployments
# Scale down non-critical workloads
# Add resource requests/limits to pods
```

## Diagnostic Commands

### Cluster Health Check
```bash
# Overall cluster status
kubectl get componentstatuses
kubectl get events --sort-by='.lastTimestamp'

# Node status
kubectl get nodes -o wide
kubectl describe node <node-name>

# Pod status
kubectl get pods -A -o wide
kubectl describe pod <pod-name> -n <namespace>
```

### Network Diagnostics
```bash
# Service connectivity
kubectl get svc -A
kubectl describe svc <service-name> -n <namespace>

# Endpoint verification
kubectl get endpoints -A
kubectl describe endpoints <service-name> -n <namespace>

# Network policies
kubectl get networkpolicies -A
kubectl describe networkpolicy <policy-name> -n <namespace>
```

### Storage Diagnostics
```bash
# Storage classes
kubectl get storageclass
kubectl describe storageclass <class-name>

# Persistent volumes
kubectl get pv
kubectl describe pv <pv-name>

# Persistent volume claims
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>
```

### Log Analysis
```bash
# Pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# System logs
sudo journalctl -u kubelet -f
sudo journalctl -u docker -f

# Container logs
sudo docker logs <container-id>
```

## Performance Issues

### High CPU Usage
```bash
# Identify resource-intensive pods
kubectl top pods -A --sort-by=cpu

# Check node CPU usage
kubectl top nodes

# Analyze resource requests/limits
kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,CPU_LIMIT:.spec.containers[*].resources.limits.cpu
```

### High Memory Usage
```bash
# Identify memory-intensive pods
kubectl top pods -A --sort-by=memory

# Check memory pressure
kubectl describe node <node-name> | grep -A 10 "Conditions"

# Analyze memory requests/limits
kubectl get pods -A -o custom-columns=NAME:.metadata.name,MEMORY_REQ:.spec.containers[*].resources.requests.memory,MEMORY_LIMIT:.spec.containers[*].resources.limits.memory
```

### Network Performance
```bash
# Check network policies impact
kubectl get networkpolicies -A

# Monitor network metrics
kubectl top pods -A | grep -E "(traefik|ingress)"

# Check service endpoints
kubectl get endpoints -A
```

## Recovery Procedures

### Node Recovery
```bash
# Drain node before maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Perform maintenance

# Uncordon node
kubectl uncordon <node-name>
```

### Pod Recovery
```bash
# Restart deployment
kubectl rollout restart deployment <deployment-name> -n <namespace>

# Check rollout status
kubectl rollout status deployment <deployment-name> -n <namespace>

# Rollback if needed
kubectl rollout undo deployment <deployment-name> -n <namespace>
```

### Service Recovery
```bash
# Restart service
kubectl delete pod -l app=<app-label> -n <namespace>

# Verify service endpoints
kubectl get endpoints <service-name> -n <namespace>
kubectl describe endpoints <service-name> -n <namespace>
```

## Monitoring and Alerting

### Health Checks
```bash
# Use cluster manager tool
./cluster-manager health

# Manual health check
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

### Metrics Collection
```bash
# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Log Aggregation
```bash
# Check centralized logging
kubectl get pods -n logging
kubectl logs -n logging -l app=fluentd
```

## Prevention Best Practices

### Regular Maintenance
- Monitor resource usage
- Update system packages
- Backup etcd regularly
- Review and update security policies

### Monitoring Setup
- Configure Prometheus alerts
- Set up log aggregation
- Monitor network performance
- Track resource utilization

### Security Measures
- Regular security updates
- Network policy enforcement
- RBAC configuration
- Secret management

### Backup Strategy
- etcd snapshots
- Persistent volume backups
- Configuration backups
- Disaster recovery plan

-----
### API server/Control Pane is not responding
```bash
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes
E0822 18:24:27.560458   16831 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.101.11:6443/api?timeout=32s\": dial tcp 192.168.101.11:6443: connect: connection refused"
The connection to the server 192.168.101.11:6443 was refused - did you specify the right host or port?
```

### Check status of The Kubernetes Node Agent
sudo journalctl -u kubelet -f
sudo systemctl status containerd kubelet
-----

```
Aug 22 19:22:13 node1 kubelet[34334]: E0822 19:22:13.138596   34334 kubelet.go:3117] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
```
kubelet won’t go Ready until both the CNI binaries and a CNI config are present and sane.

https://stackoverflow.com/questions/43662229/flannel-installation-on-kubernetes

Flannel (or Calico, Weave, etc.) only installs the CNI config file into /etc/cni/net.d (like 10-flannel.conflist).
The CNI binaries (bridge, host-local, portmap, loopback, etc.) are not shipped by Flannel. They must already exist in /opt/cni/bin (or whatever bin_dir is set to in containerd).