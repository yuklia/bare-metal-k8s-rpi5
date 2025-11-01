package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type ClusterManager struct {
	kubeconfig string
}

func NewClusterManager() (*ClusterManager, error) {
	var kubeconfig string
	if home := os.Getenv("HOME"); home != "" {
		kubeconfig = filepath.Join(home, ".kube", "config")
	}

	// Check if kubeconfig exists
	if _, err := os.Stat(kubeconfig); os.IsNotExist(err) {
		return nil, fmt.Errorf("kubeconfig not found at %s", kubeconfig)
	}

	return &ClusterManager{
		kubeconfig: kubeconfig,
	}, nil
}

func (cm *ClusterManager) GetClusterInfo() error {
	fmt.Println("=== Kubernetes Cluster Information ===")

	// Get nodes
	fmt.Println("\nNodes:")
	cmd := exec.Command("kubectl", "get", "nodes", "-o", "wide")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to get nodes: %v", err)
	}
	fmt.Println(string(output))

	// Get pods
	fmt.Println("\nPods:")
	cmd = exec.Command("kubectl", "get", "pods", "-A")
	output, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to get pods: %v", err)
	}
	fmt.Println(string(output))

	// Get services
	fmt.Println("\nServices:")
	cmd = exec.Command("kubectl", "get", "svc", "-A")
	output, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to get services: %v", err)
	}
	fmt.Println(string(output))

	return nil
}

func (cm *ClusterManager) CheckClusterHealth() error {
	fmt.Println("=== Cluster Health Check ===")

	// Check node readiness
	fmt.Println("\nNode Health:")
	cmd := exec.Command("kubectl", "get", "nodes", "--no-headers")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to get nodes: %v", err)
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	healthyNodes := 0
	totalNodes := len(lines)

	for _, line := range lines {
		if strings.Contains(line, "Ready") {
			healthyNodes++
		}
	}

	fmt.Printf("Node Health: %d/%d nodes ready\n", healthyNodes, totalNodes)

	// Check pod readiness
	fmt.Println("\nPod Health:")
	cmd = exec.Command("kubectl", "get", "pods", "-A", "--no-headers")
	output, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to get pods: %v", err)
	}

	lines = strings.Split(strings.TrimSpace(string(output)), "\n")
	runningPods := 0
	totalPods := len(lines)

	for _, line := range lines {
		if strings.Contains(line, "Running") {
			runningPods++
		}
	}

	fmt.Printf("Pod Health: %d/%d pods running\n", runningPods, totalPods)

	// Check critical namespaces
	criticalNamespaces := []string{"kube-system", "metallb-system", "traefik"}
	for _, ns := range criticalNamespaces {
		cmd = exec.Command("kubectl", "get", "pods", "-n", ns, "--no-headers")
		output, err = cmd.CombinedOutput()
		if err != nil {
			fmt.Printf("Warning: Could not check namespace %s: %v\n", ns, err)
			continue
		}

		lines = strings.Split(strings.TrimSpace(string(output)), "\n")
		readyPods := 0
		for _, line := range lines {
			if strings.Contains(line, "Running") {
				readyPods++
			}
		}

		fmt.Printf("Namespace %s: %d/%d pods ready\n", ns, readyPods, len(lines))
	}

	return nil
}

func (cm *ClusterManager) ScaleDeployment(namespace, name string, replicas int) error {
	fmt.Printf("Scaling deployment %s/%s to %d replicas\n", namespace, name, replicas)

	cmd := exec.Command("kubectl", "scale", "deployment", name, "-n", namespace, "--replicas", fmt.Sprintf("%d", replicas))
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to scale deployment: %v, output: %s", err, string(output))
	}

	fmt.Printf("Successfully scaled deployment %s/%s to %d replicas\n", namespace, name, replicas)
	return nil
}

func (cm *ClusterManager) RestartDeployment(namespace, name string) error {
	fmt.Printf("Restarting deployment %s/%s\n", namespace, name)

	cmd := exec.Command("kubectl", "rollout", "restart", "deployment", name, "-n", namespace)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to restart deployment: %v, output: %s", err, string(output))
	}

	fmt.Printf("Successfully restarted deployment %s/%s\n", namespace, name)
	return nil
}

func (cm *ClusterManager) BackupEtcd() error {
	fmt.Println("Creating etcd backup...")

	// Find etcd pod
	cmd := exec.Command("kubectl", "get", "pods", "-n", "kube-system", "-l", "component=etcd", "-o", "jsonpath={.items[0].metadata.name}")
	etcdPod, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to find etcd pod: %v", err)
	}

	if len(etcdPod) == 0 {
		return fmt.Errorf("no etcd pods found")
	}

	// Create backup
	backupCmd := exec.Command("kubectl", "exec", "-n", "kube-system", string(etcdPod), "--", "etcdctl", "snapshot", "save", "/tmp/backup.db")
	output, err := backupCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to create etcd backup: %v, output: %s", err, string(output))
	}

	fmt.Printf("Etcd backup created successfully: %s", string(output))
	return nil
}

func (cm *ClusterManager) ShowLogs(namespace, podName string, lines int) error {
	fmt.Printf("Showing last %d lines of logs for %s/%s\n", lines, namespace, podName)

	cmd := exec.Command("kubectl", "logs", "-n", namespace, podName, "--tail", fmt.Sprintf("%d", lines))
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to get logs: %v", err)
	}

	fmt.Println(string(output))
	return nil
}

func printUsage() {
	fmt.Println("Kubernetes Cluster Manager")
	fmt.Println("Usage:")
	fmt.Println("  cluster-manager [command] [options]")
	fmt.Println("")
	fmt.Println("Commands:")
	fmt.Println("  info                    - Show cluster information")
	fmt.Println("  health                  - Check cluster health")
	fmt.Println("  scale <ns> <name> <n>  - Scale deployment")
	fmt.Println("  restart <ns> <name>    - Restart deployment")
	fmt.Println("  backup                  - Create etcd backup")
	fmt.Println("  logs <ns> <pod> [n]    - Show pod logs (default: 100 lines)")
	fmt.Println("  help                    - Show this help message")
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	cm, err := NewClusterManager()
	if err != nil {
		log.Fatalf("Failed to create cluster manager: %v", err)
	}

	command := os.Args[1]
	switch command {
	case "info":
		if err := cm.GetClusterInfo(); err != nil {
			log.Fatalf("Failed to get cluster info: %v", err)
		}
	case "health":
		if err := cm.CheckClusterHealth(); err != nil {
			log.Fatalf("Failed to check cluster health: %v", err)
		}
	case "scale":
		if len(os.Args) != 5 {
			fmt.Println("Usage: scale <namespace> <deployment> <replicas>")
			os.Exit(1)
		}
		replicas := 0
		fmt.Sscanf(os.Args[4], "%d", &replicas)
		if err := cm.ScaleDeployment(os.Args[2], os.Args[3], replicas); err != nil {
			log.Fatalf("Failed to scale deployment: %v", err)
		}
	case "restart":
		if len(os.Args) != 4 {
			fmt.Println("Usage: restart <namespace> <deployment>")
			os.Exit(1)
		}
		if err := cm.RestartDeployment(os.Args[2], os.Args[3]); err != nil {
			log.Fatalf("Failed to restart deployment: %v", err)
		}
	case "backup":
		if err := cm.BackupEtcd(); err != nil {
			log.Fatalf("Failed to create backup: %v", err)
		}
	case "logs":
		if len(os.Args) < 4 {
			fmt.Println("Usage: logs <namespace> <pod> [lines]")
			os.Exit(1)
		}
		lines := 100
		if len(os.Args) == 5 {
			fmt.Sscanf(os.Args[4], "%d", &lines)
		}
		if err := cm.ShowLogs(os.Args[2], os.Args[3], lines); err != nil {
			log.Fatalf("Failed to show logs: %v", err)
		}
	case "help":
		printUsage()
	default:
		fmt.Printf("Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}
