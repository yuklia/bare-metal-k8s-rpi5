# Traefik Ingress Controller

This directory contains Kustomize configurations for deploying Traefik v3.0 as an ingress controller on the homelab Kubernetes cluster.

## Architecture Overview

Traefik is deployed as a LoadBalancer service with MetalLB, providing:
- HTTP/HTTPS ingress routing
- Automatic SSL certificate management
- Web dashboard for monitoring
- Load balancing across services

## File Structure

### Core Configuration Files

#### `namespace.yaml`
- **Purpose**: Creates the `traefik` namespace
- **Contains**: Namespace definition with labels
- **Why needed**: Isolates Traefik resources from other applications

#### `rbac.yaml`
- **Purpose**: Defines RBAC permissions for Traefik
- **Contains**:
  - ServiceAccount for Traefik pod
  - ClusterRole with permissions to read services, endpoints, secrets, ingresses
  - ClusterRoleBinding linking ServiceAccount to ClusterRole
- **Why needed**: Traefik needs permissions to watch Kubernetes resources for automatic service discovery

#### `configmap.yaml`
- **Purpose**: Contains Traefik's main configuration
- **Key Settings**:
  - Entry points: HTTP (80) and HTTPS (443) with automatic redirect
  - Dashboard enabled on port 8080
  - Let's Encrypt ACME configuration for SSL certificates
  - Kubernetes provider configuration
  - Logging configuration
- **Why needed**: Centralizes Traefik configuration without rebuilding images

#### `deployment.yaml`
- **Purpose**: Defines the Traefik pod deployment
- **Contains**:
  - Single replica deployment
  - Resource limits (128Mi RAM, 200m CPU)
  - Health checks (liveness/readiness probes)
  - Volume mounts for config, data, and logs
- **Why needed**: Manages the Traefik pod lifecycle and resource usage

#### `service.yaml`
- **Purpose**: Exposes Traefik services
- **Contains**:
  - LoadBalancer service for external access (192.168.1.240)
  - ClusterIP service for dashboard access
- **Why needed**: Provides network access to Traefik from outside the cluster

#### `ingressroute.yaml`
- **Purpose**: Configures Traefik dashboard access
- **Contains**:
  - HTTP and HTTPS routes for dashboard
  - Host matching for `traefik.192.168.101.11.nip.io` and `traefik.local`
  - TLS configuration
- **Why needed**: Makes Traefik dashboard accessible via browser

#### `kustomization.yaml`
- **Purpose**: Kustomize configuration file
- **Contains**:
  - Resource list
  - Common labels
  - Image tag specification
- **Why needed**: Defines how Kustomize builds the final manifests

## Deployment Instructions

### Prerequisites
- Kubernetes cluster running
- MetalLB configured with IP range 192.168.1.240-192.168.1.250
- kubectl configured and connected to cluster

### Deploy Traefik

1. **Deploy to cluster**:
   ```bash
   kubectl apply -k kustomize/traefik/
   ```

2. **Verify deployment**:
   ```bash
   # Check pods are running
   kubectl get pods -n traefik
   
   # Check services
   kubectl get svc -n traefik
   
   # Check external IP assignment
   kubectl get svc traefik -n traefik
   ```

3. **Access dashboard**:
   - Open browser to: `http://traefik.192.168.101.11.nip.io`
   - Or: `http://traefik.local` (if DNS configured)
   - Dashboard should show active routes and services

### Verify Installation

```bash
# Check Traefik is running
kubectl get pods -n traefik

# Check LoadBalancer IP assignment
kubectl get svc traefik -n traefik

# Test dashboard access
curl -H "Host: traefik.192.168.101.11.nip.io" http://192.168.1.240/dashboard/

# Check logs
kubectl logs -n traefik -l app=traefik
```

## Update Without Downtime

### Rolling Update Process

1. **Update image tag in kustomization.yaml**:
   ```yaml
   images:
     - name: traefik
       newTag: v3.1  # Update to new version
   ```

2. **Apply changes**:
   ```bash
   kubectl apply -k kustomize/traefik/
   ```

3. **Monitor rollout**:
   ```bash
   # Watch deployment status
   kubectl rollout status deployment/traefik -n traefik
   
   # Check pod readiness
   kubectl get pods -n traefik -w
   ```

4. **Verify update**:
   ```bash
   # Check new image is running
   kubectl describe pod -n traefik -l app=traefik
   
   # Test dashboard still accessible
   curl -H "Host: traefik.192.168.101.11.nip.io" http://192.168.1.240/dashboard/
   ```

### Configuration Updates

1. **Modify configmap.yaml**:
   ```bash
   # Edit configuration
   nano kustomize/traefik/configmap.yaml
   ```

2. **Apply changes**:
   ```bash
   kubectl apply -k kustomize/traefik/
   ```

3. **Restart Traefik** (if needed):
   ```bash
   kubectl rollout restart deployment/traefik -n traefik
   ```

## Destruction Instructions

### Complete Removal

1. **Delete Traefik resources**:
   ```bash
   kubectl delete -k kustomize/traefik/
   ```

2. **Verify removal**:
   ```bash
   # Check namespace is gone
   kubectl get ns traefik
   
   # Check no Traefik pods
   kubectl get pods -A | grep traefik
   
   # Check no Traefik services
   kubectl get svc -A | grep traefik
   ```

3. **Clean up persistent data** (optional):
   ```bash
   # Remove any persistent volumes
   kubectl get pv | grep traefik
   kubectl delete pv <traefik-pv-name>
   ```

### Partial Removal

If you want to keep the namespace but remove Traefik:

```bash
# Delete specific resources
kubectl delete deployment traefik -n traefik
kubectl delete svc traefik traefik-dashboard -n traefik
kubectl delete ingressroute traefik-dashboard traefik-dashboard-http -n traefik
kubectl delete configmap traefik-config -n traefik
kubectl delete serviceaccount traefik -n traefik
kubectl delete clusterrole traefik
kubectl delete clusterrolebinding traefik
```

## Troubleshooting

### Common Issues

1. **Traefik pod not starting**:
   ```bash
   kubectl describe pod -n traefik -l app=traefik
   kubectl logs -n traefik -l app=traefik
   ```

2. **LoadBalancer IP not assigned**:
   ```bash
   # Check MetalLB status
   kubectl get pods -n metallb-system
   kubectl get ipaddresspools -n metallb-system
   ```

3. **Dashboard not accessible**:
   ```bash
   # Check service endpoints
   kubectl get endpoints -n traefik
   
   # Test internal connectivity
   kubectl exec -n traefik -l app=traefik -- curl localhost:8080/dashboard/
   ```

4. **SSL certificate issues**:
   ```bash
   # Check certificate status
   kubectl get certificates -n traefik
   kubectl describe certificate traefik-dashboard-tls -n traefik
   ```

### Debug Commands

```bash
# Check all Traefik resources
kubectl get all -n traefik

# Check events
kubectl get events -n traefik --sort-by='.lastTimestamp'

# Check Traefik configuration
kubectl exec -n traefik -l app=traefik -- cat /config/traefik.yaml

# Check logs
kubectl logs -n traefik -l app=traefik --tail=100 -f
```

## Security Considerations

- Traefik dashboard is exposed via IngressRoute (consider adding authentication)
- SSL certificates are managed automatically via Let's Encrypt
- RBAC permissions are minimal and follow least privilege principle
- Consider network policies for additional security

## Monitoring

- Dashboard available at: `http://traefik.192.168.101.11.nip.io`
- Logs available via: `kubectl logs -n traefik -l app=traefik`
- Metrics available on port 8080 (if enabled in config)

## Next Steps

After successful deployment:
1. Configure DNS for `traefik.local` in your local hosts file
2. Set up SSL certificates for production domains
3. Configure additional IngressRoutes for your applications
4. Set up monitoring and alerting
5. Consider adding authentication to the dashboard
