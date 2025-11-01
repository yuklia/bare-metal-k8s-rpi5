#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building Kubernetes Cluster Manager...${NC}"

# Build the Go binary
go build -o cluster-manager main.go

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}"
    echo "Binary created: cluster-manager"
    echo ""
    echo "Usage:"
    echo "  ./cluster-manager info                    - Show cluster information"
    echo "  ./cluster-manager health                  - Check cluster health"
    echo "  ./cluster-manager scale <ns> <name> <n>  - Scale deployment"
    echo "  ./cluster-manager restart <ns> <name>    - Restart deployment"
    echo "  ./cluster-manager backup                  - Create etcd backup"
    echo "  ./cluster-manager logs <ns> <pod> [n]    - Show pod logs"
    echo "  ./cluster-manager help                    - Show help message"
else
    echo "Build failed!"
    exit 1
fi
