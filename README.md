# Kubernetes Automation Script

This script automates the setup and configuration of a Kubernetes cluster, including deployment scaling using KEDA. Below are the prerequisites and a detailed explanation of the design choices made for the script implementation.

## Prerequisites

Ensure the following tools and versions are installed before running the script:

1. **Docker Client**
   - Version: `27.3.1`

2. **Kubernetes Cluster (Minikube)**
   - Minikube Version: `v1.34.0`

3. **Kubectl CLI**
   - Client Version: `v1.31.0`
   - Kustomize Version: `v5.4.2`
   - Server Version: `v1.31.0`

4. **Metric Server**
   - Installed using the following manifest:
     ```bash
     wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server-components.yaml
     ```

5. **Helm**
   - Version: `v3.9.0` 
   - If Helm is not installed, the script will install it. Compatible with charts like KEDA.

---

## Design Overview

### 1. Modular Design
The script is organized into modular functions for better clarity, reusability, and maintainability:
- **`start_minikube`**: Initializes Minikube.
- **`install_helm`**: Ensures Helm is available.
- **`connect_and_setup_cluster`**: Integrates multiple setup steps (e.g., connecting kubectl, validating tools, and installing KEDA).
- **`create_deployment`**: Creates Kubernetes deployments, including scaling configurations.
- **`get_health_status`**: Retrieves the deployment's health and resource usage.

---

### 2. Error Handling and Feedback
- Critical steps include error handling with `if [ $? -ne 0 ]` checks to ensure proper execution.
- The script terminates with appropriate exit codes on critical failures, preventing subsequent steps from running in an invalid state.

---

### 3. Tool Installation and Validation
- Checks for required tools (`kubectl`, `helm`, `minikube`) and installs them if not found.
- Validates the cluster environment before proceeding.

---

### 4. Automation with Scalability in Mind
- Uses Helm for installing and managing KEDA, simplifying deployment and upgrades.
- Dynamically generates Kubernetes YAML manifests for deployments, services, and KEDA scaling objects, making it adaptable to various use cases.

---

### 5. User-Friendly Interaction
- Includes a usage function to guide users on script commands.
- Validates arguments for functions like `create_deployment`, ensuring all necessary parameters are provided.

---

### 6. Built-In Scaling with KEDA
- Incorporates KEDA scaling configurations (e.g., Kafka triggers, lag thresholds) as part of the deployment process.
- Focuses on event-driven scaling for workloads.

---

### 7. Detailed Setup Verification
- Outputs cluster and tool information for verification.
- Checks the status of the KEDA operator and deployments to ensure successful installation and operation.

---

## Usage

1. Clone this repository.
2. Execute the script with appropriate arguments.
3. Follow the user feedback provided by the script to complete the setup.
