#!/bin/bash

# Fix Worker Nodes Join Issue
# This script fixes worker nodes that have admin.conf files and can't join the cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}🔧 Fixing Worker Nodes Join Issue...${NC}"

# Check if inventory file exists
if [ ! -f "$PROJECT_DIR/inventory.ini" ]; then
    echo -e "${RED}❌ Inventory file not found at $PROJECT_DIR/inventory.ini${NC}"
    echo "Please copy inventory.example to inventory.ini and configure it first."
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR"

# Run the fix playbook
echo -e "${YELLOW}📋 Running fix_join_nodes playbook...${NC}"
ansible-playbook -i inventory.ini ansible/playbooks/fix_join_nodes.yml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Worker nodes join issue fixed successfully!${NC}"
    echo -e "${YELLOW}🔍 Verifying cluster status...${NC}"
    
    # Verify cluster status
    ssh yuklia@192.168.101.11 "kubectl get nodes"
    
    echo -e "${GREEN}🎉 All done! Your worker nodes should now be properly joined to the cluster.${NC}"
else
    echo -e "${RED}❌ Failed to fix worker nodes join issue. Please check the logs above.${NC}"
    exit 1
fi
