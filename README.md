Prerequisites:

Docker
  Client: Version: 27.3.1
  
K8s cluster (Minikube) version : Minikube version: v1.34.0

Kubectl cli 
  Client Version: v1.31.0
  Kustomize Version: v5.4.2
  Server Version: v1.31.0
  
Metric server installed. 
  wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server-components.yaml
  
Helm : version : v3.9.0 → This will be installed if the cluster does not have one. This will be compatible with charts like KEDA.

Here’s a brief overview of the design choices made during the implementation of the script:
1. Modular Design
    The script is organized into modular functions, each addressing a specific task:
      a. start_minikube handles the Minikube initialization.
      b. install_helm ensures Helm is available.
      c. connect_and_setup_cluster integrates multiple setup steps (e.g., connecting kubectl, validating tools, and installing KEDA).
      d. create_deployment creates Kubernetes deployments, including scaling configurations.
      e. get_health_status retrieves the deployment's health and resource usage.
    This approach ensures clarity, reusability, and maintainability.
3. Error Handling and Feedback
    a. Each step includes error handling (if [ $? -ne 0 ] checks) and provides clear feedback to the user.
    b. Exit codes are used to terminate the script in case of critical failures, ensuring subsequent steps are not executed in an invalid state.
4. Tool Installation and Validation
    a. The script checks for the presence of required tools (kubectl, helm, minikube) and installs them if necessary.
    b. The inclusion of validation ensures that the cluster environment is correctly configured before moving forward.
5. Automation with Scalability in Mind
    a. Helm is used for installing and managing KEDA, simplifying deployment and upgrades.
    b. Kubernetes YAML manifests are generated dynamically for deployments, services, and KEDA scaling objects, making the script adaptable to different use cases.
6. User-Friendly Interaction
    a. A usage function provides clear guidance on how to use the script and its commands.
    b. Arguments are validated for functions like create_deployment, ensuring users provide all necessary parameters.
7. Built-in Scaling with KEDA
    KEDA scaling configurations (e.g., Kafka triggers, lag thresholds) are included as part of the deployment process, demonstrating a focus on event-driven scaling for workloads.
8. Detailed Setup Verification
    The script outputs cluster and tool information to help users verify the setup.
    KEDA operator and deployment statuses are checked to ensure successful installation and operation.


