## Kubernetes Troubleshooting Cheatsheet (Control Plane, Kubelet, Proxy, Networking)

Use these quick commands to assess cluster and node health. Replace placeholders like <node> as needed.

### Cluster quick health
```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get events --sort-by=.lastTimestamp | tail -n 50
```

### API server (kube-apiserver)
```bash
# From laptop
kubectl get --raw /healthz; echo
kubectl get --raw /readyz?verbose | head

# On control-plane node (containerd static pod)
sudo crictl ps | grep kube-apiserver
sudo crictl logs $(sudo crictl ps --name kube-apiserver -q) | tail -n 200

# Port listening (on control-plane node)
sudo ss -ltnp | egrep ':6443|kube-apiserver'
```

### Controller manager and scheduler
```bash
# Check static pods on control-plane
kubectl get pods -n kube-system -o wide | egrep 'controller-manager|scheduler'
sudo crictl ps | egrep 'kube-controller-manager|kube-scheduler'
sudo crictl logs $(sudo crictl ps --name kube-controller-manager -q) | tail -n 200
sudo crictl logs $(sudo crictl ps --name kube-scheduler -q) | tail -n 200
```

### etcd (if self-hosted on control-plane)
```bash
kubectl get pods -n kube-system -o wide | grep etcd
sudo crictl ps | grep etcd
sudo crictl logs $(sudo crictl ps --name etcd -q) | tail -n 200
# Health
export ETCDCTL_API=3
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key endpoint health
```

### Kubelet (on every node)
```bash
kubectl get nodes -o wide
ssh yuklia@<node> 'sudo systemctl status kubelet --no-pager'
ssh yuklia@<node> 'sudo journalctl -u kubelet -n 200 --no-pager'
ssh yuklia@<node> 'sudo crictl info && sudo crictl ps -a | head'
```

### Kube-proxy
```bash
kubectl -n kube-system get ds/kube-proxy -o wide
kubectl -n kube-system get pods -l k8s-app=kube-proxy -o wide
kubectl -n kube-system logs -l k8s-app=kube-proxy --tail=200 --all-containers=true
```

### Networking / CNI (Flannel here)
```bash
kubectl -n kube-flannel get ds,po -o wide
kubectl -n kube-flannel logs -l app=flannel --tail=200

# Cross-node pod ping test
kubectl -n kube-system run netshoot --image=nicolaka/netshoot -it --rm -- bash -lc 'ip a; ping -c3 <pod-ip>'

# Node routes and interfaces (on node)
ssh yuklia@<node> 'ip addr && ip route'
```

### DNS (CoreDNS)
```bash
kubectl -n kube-system get deploy coredns -o wide
kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=200

# DNS resolution test from a pod
kubectl -n default run dnsutils --image=ghcr.io/kubernetes-sigs/e2e-test-images/agnhost:2.45 -it --rm -- nslookup kubernetes.default
```

### Ingress (Traefik) and Service load-balancing
```bash
kubectl -n traefik get deploy,svc,ingress -o wide
kubectl -n traefik logs -l app=traefik --tail=200

# Check MetalLB
kubectl -n metallb-system get pods,svc
kubectl -n metallb-system get ipaddresspools
```

### Services and kube-proxy dataplane check
```bash
# ClusterIP reachability from a pod
kubectl -n default run tmpcurl --image=ghcr.io/curl/curl:8.9.1 -it --rm -- curl -sS http://<clusterip>:<port>/healthz || true

# Node iptables/ipvs mode
ssh yuklia@<node> 'sudo iptables -t nat -S | head -n 30'
ssh yuklia@<node> 'sudo ipvsadm -Ln'  # if using IPVS
```

### Certificates and auth
```bash
kubectl -n kube-system get cm kube-root-ca.crt -o yaml | head
kubectl get csr
kubectl auth can-i get pods --all-namespaces --as system:anonymous
```

### Resource pressure (common root cause)
```bash
kubectl top nodes || true
kubectl top pods -A || true
ssh yuklia@<node> 'free -h && df -h && sudo dmesg -T | tail -n 50'
```

### Event- and condition-driven debugging
```bash
kubectl describe node <node>
kubectl -n <ns> describe pod <pod>
kubectl -n <ns> get events --sort-by=.lastTimestamp | tail -n 100
```

### Common ports (sanity)
```bash
# On control-plane node
sudo ss -ltnp | egrep ':6443|:10250|:10257|:10259'

# On all nodes (kubelet 10250; CNI may vary)
sudo ss -ltnp | egrep ':10250|containerd'
```

### Quick triage flow
- Check nodes Ready and system pods Running
- Look at recent Events
- Inspect the failing component logs (api-server, controller-manager, scheduler, kubelet, kube-proxy, CNI)
- Validate DNS, Services, and Ingress paths
- Check resource pressure and node conditions


