**Prerequisites:**

1.Docker Client Version: 27.3.1
  
2.K8s cluster (Minikube) version : Minikube version: v1.34.0

3.Kubectl cli 
    Client Version: v1.31.0
    Kustomize Version: v5.4.2
    Server Version: v1.31.0
  
4.Metric server installed. 
    [metric-server-manifest](wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server-components.yaml)
  
5.Helm Version : v3.9.0 
    This will be installed if the cluster does not have one. This will be compatible with charts like KEDA.

**Here’s a brief overview of the design choices made during the implementation of the script:**
**1. Modular Design**
    The script is organized into modular functions, each addressing a specific task:
      a. **_start_minikube_** handles the Minikube initialization.
      b. **_install_helm_** ensures Helm is available.
      c. **_connect_and_setup_cluster_** integrates multiple setup steps (e.g., connecting kubectl, validating tools, and installing KEDA).
      d. **_create_deployment_** creates Kubernetes deployments, including scaling configurations.
      e. **_get_health_status_** retrieves the deployment's health and resource usage.
    This approach ensures clarity, reusability, and maintainability.
**2. Error Handling and Feedback**
    a. Each step includes error handling **_(if [ $? -ne 0 ] checks)_** and provides clear feedback to the user.
    b. Exit codes are used to terminate the script in case of critical failures, ensuring subsequent steps are not executed in an invalid state.
**3. Tool Installation and Validation**
    a. The script checks for the presence of required tools **_(kubectl, helm, minikube)_** and installs them if necessary.
    b. The inclusion of validation ensures that the cluster environment is correctly configured before moving forward.
**4. Automation with Scalability in Mind**
    a. Helm is used for installing and managing KEDA, simplifying deployment and upgrades.
    b. Kubernetes YAML manifests are generated dynamically for deployments, services, and KEDA scaling objects, making the script adaptable to different use cases.
**5. User-Friendly Interaction**
    a. A usage function provides clear guidance on how to use the script and its commands.
    b. Arguments are validated for functions like **_create_deployment_**, ensuring users provide all necessary parameters.
**6. Built-in Scaling with KEDA**
    a. KEDA scaling configurations (e.g., Kafka triggers, lag thresholds) are included as part of the deployment process, demonstrating a focus on event-driven scaling for workloads.
**7. Detailed Setup Verification**
    a. The script outputs cluster and tool information to help users verify the setup.
    b. KEDA operator and deployment statuses are checked to ensure successful installation and operation.


