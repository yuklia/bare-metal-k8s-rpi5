                Kubernetes Cluster
         ┌───────────────────────────────────┐
         │  --service-cidr=10.96.0.0/12     │
         │  (virtual IPs for Services)      │
         │                                   │
         │  Service: my-api → 10.96.5.3      │
         │           (stable ClusterIP)      │
         │                 │                 │
         │           kube-proxy routes       │
         │                 │                 │
         │   ┌───────────────────────────┐   │
         │   │        Node A             │   │
         │   │  Pod subnet: 10.244.1.0/24│   │
         │   │  Pod A: 10.244.1.10       │   │
         │   │  Pod B: 10.244.1.11       │   │
         │   └───────────────────────────┘   │
         │   ┌───────────────────────────┐   │
         │   │        Node B             │   │
         │   │  Pod subnet: 10.244.2.0/24│   │
         │   │  Pod C: 10.244.2.15       │   │
         │   │  Pod D: 10.244.2.16       │   │
         │   └───────────────────────────┘   │
         │                                   │
         │   (All Pod subnets live inside    │
         │    --pod-network-cidr=10.244.0.0/16)
         └───────────────────────────────────┘

	•	Pod IPs (10.244.x.y) are real addresses on the CNI overlay; they change with reschedules.
	•	Service IPs (10.96.x.y) are virtual; stable for the Service lifetime and load-balance to Pod IPs.