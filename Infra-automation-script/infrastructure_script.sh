#!/bin/bash

# Global variables
NAMESPACE="default"
HELM_RELEASE_NAME="keda"
KEDA_CHART_REPO="https://kedacore.github.io/charts"
HELM_VERSION="v3.9.0" # Set Helm version to install

# Helper function to print usage
usage() {
    echo "Usage: $0 [Use the below commands subsequently to connect the cluster and create a deployment with scaling enabled.]"
    echo "Commands:"
    echo "  start-minikube                 - Start the Minikube cluster."
    echo "  connect                        - Connect kubectl to the Minikube cluster, install tools, and verify setup."
    echo "  install-keda                   - Install or upgrade KEDA in the Minikube cluster."
    echo "  create-deployment <args>       - Create a deployment with KEDA scaling. ARGS : <name> <image> <cpu> <memory> <ports> <namespace> <kafka_broker> <kafka_topic>"
    echo "  get-health <deployment> <ns>   - Retrieve health status of a deployment."
}

# Start Minikube
start_minikube() {
    echo "Starting Minikube..."
    minikube start
    if [ $? -eq 0 ]; then
        echo "Minikube started successfully."
    else
        echo "Error starting Minikube."
        exit 1
    fi
}

# Function to install Helm if not already installed
install_helm() {
    if ! command -v helm &>/dev/null; then
        echo "Helm is not installed. Installing Helm..."
        curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm-${HELM_VERSION}-linux-amd64.tar.gz
        tar -xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz
        sudo mv linux-amd64/helm /usr/local/bin/helm
        rm -rf linux-amd64 helm-${HELM_VERSION}-linux-amd64.tar.gz
        echo "Helm installed successfully."
    else
        echo "Helm is already installed."
    fi
}

# Connect kubectl to Minikube and install necessary tools (Helm, KEDA)
connect_and_setup_cluster() {
    echo "Connecting kubectl to Minikube and setting up necessary tools..."

    # Start Minikube if not already running
    minikube status &>/dev/null
    if [ $? -ne 0 ]; then
        start_minikube
    fi

    # Connect kubectl to Minikube
    kubectl config use-context minikube
    if [ $? -eq 0 ]; then
        echo "kubectl connected to Minikube successfully."
    else
        echo "Error connecting kubectl to Minikube."
        exit 1
    fi

    # Install Helm if not already installed
    install_helm

    # Validate tools (kubectl, helm, minikube)
    validate_tools

    # Install or upgrade KEDA
    install_keda

    # Provide summary of the cluster setup
    echo "Cluster setup summary:"
    kubectl cluster-info
    echo "Installed tools:"
    kubectl version --short
    helm version --short
    kubectl get nodes
    kubectl get pods -n keda
}

# Validate tools are installed
validate_tools() {
    echo "Validating tools..."
    for tool in kubectl minikube; do
        if ! command -v $tool &>/dev/null; then
            echo "Error: $tool is not installed. Please install it before proceeding."
            exit 1
        fi
    done
    echo "All tools are installed."
}

# Install or upgrade KEDA and verify the installation
install_keda() {
    echo "Checking if KEDA is already installed..."

    # Check if KEDA is already installed
    helm list -n keda | grep $HELM_RELEASE_NAME
    if [ $? -eq 0 ]; then
        echo "KEDA is already installed. Upgrading KEDA..."
        # Upgrade the KEDA installation using Helm
        helm upgrade $HELM_RELEASE_NAME kedacore/keda --namespace keda
        if [ $? -eq 0 ]; then
            echo "KEDA upgraded successfully."
        else
            echo "Error upgrading KEDA."
            exit 1
        fi
    else
        echo "KEDA is not installed. Installing KEDA..."
        # Install KEDA using Helm
        helm repo add kedacore $KEDA_CHART_REPO
        helm repo update
        helm install $HELM_RELEASE_NAME kedacore/keda --namespace keda --create-namespace
        if [ $? -eq 0 ]; then
            echo "KEDA installed successfully."
        else
            echo "Error installing KEDA."
            exit 1
        fi
    fi

    # Verify if KEDA operator is running
    echo "Verifying KEDA operator status..."
    kubectl get pods -n keda -l app.kubernetes.io/name=keda-operator
    if [ $? -eq 0 ]; then
        echo "KEDA operator is running successfully."
    else
        echo "Error: KEDA operator is not running."
        exit 1
    fi

    # Check if the KEDA deployment is running
    kubectl get deployment keda-operator -n keda
    if [ $? -eq 0 ]; then
        echo "KEDA operator deployment is running."
    else
        echo "Error: KEDA operator deployment is not running."
        exit 1
    fi

    # Ensure that KEDA pods are in a healthy state
    kubectl get pods -n keda
    if kubectl get pods -n keda | grep -q 'keda-operator.*Running'; then
        echo "KEDA operator is running and healthy."
    else
        echo "Error: KEDA operator is not healthy."
        exit 1
    fi
}

create_deployment() {
    if [ $# -lt 8 ]; then
        echo "Usage: $0 create-deployment <name> <image> <cpu> <memory> <ports> <namespace> <kafka_broker> <kafka_topic>"
        exit 1
    fi

    NAME=$1
    IMAGE=$2
    CPU=$3
    MEMORY=$4
    PORTS=$5
    NAMESPACE=$6
    KAFKA_BROKER=$7
    KAFKA_TOPIC=$8

    echo "Creating deployment: $NAME in namespace: $NAMESPACE"

    # Ensure the namespace exists
    kubectl get namespace $NAMESPACE &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Namespace $NAMESPACE does not exist. Creating it..."
        kubectl create namespace $NAMESPACE
        if [ $? -ne 0 ]; then
            echo "Error creating namespace $NAMESPACE."
            exit 1
        fi
    fi

    # Create Deployment YAML with HPA and Kafka scaling
    cat <<EOF >"${NAME}-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $NAME
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $NAME
  template:
    metadata:
      labels:
        app: $NAME
    spec:
      containers:
      - name: $NAME
        image: $IMAGE
        resources:
          requests:
            cpu: $CPU
            memory: $MEMORY
          limits:
            cpu: $CPU
            memory: $MEMORY
        ports:
        - containerPort: $PORTS
---
apiVersion: v1
kind: Service
metadata:
  name: $NAME-service
  namespace: $NAMESPACE
spec:
  selector:
    app: $NAME
  ports:
  - protocol: TCP
    port: $PORTS
    targetPort: $PORTS
  type: ClusterIP
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: $NAME-scaler
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    name: $NAME
  minReplicaCount: 1
  maxReplicaCount: 10
  pollingInterval: 30
  cooldownPeriod: 300
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: $KAFKA_BROKER
      topic: $KAFKA_TOPIC
      consumerGroup: $NAME-consumer-group
      lagThreshold: "10"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $NAME-hpa
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $NAME
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

    # Apply the deployment
    kubectl apply -f "${NAME}-deployment.yaml"
    if [ $? -eq 0 ]; then
        echo "Deployment $NAME created successfully in namespace $NAMESPACE."

        # Fetch deployment details
        echo "Service Endpoint:"
        kubectl get service $NAME-service -n $NAMESPACE -o wide
        echo "Scaling Configuration:"
        kubectl describe scaledobject $NAME-scaler -n $NAMESPACE
        kubectl describe hpa $NAME-hpa -n $NAMESPACE
    else
        echo "Error creating deployment."
        exit 1
    fi
}


get_health_status() {
    if [ $# -lt 2 ]; then
        echo "Usage: $0 get-health <deployment> <namespace>"
        exit 1
    fi

    DEPLOYMENT=$1
    NAMESPACE=$2

    echo "Fetching health status for deployment: $DEPLOYMENT in namespace: $NAMESPACE"

    # Check if the namespace exists
    kubectl get namespace $NAMESPACE &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Namespace $NAMESPACE does not exist."
        exit 1
    fi

    # Fetch deployment details
    echo "Deployment details:"
    kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o wide

    # Fetch pod details
    echo "Pod details:"
    kubectl get pods -l app=$DEPLOYMENT -n $NAMESPACE -o wide

    # Fetch resource usage details
    echo "Resource usage:"
    kubectl top pod -l app=$DEPLOYMENT -n $NAMESPACE 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Metrics server might not be running. Please ensure the metrics server is installed and running."
    fi
}

# Main logic
case "$1" in
start-minikube)
    start_minikube
    ;;
connect)
    connect_and_setup_cluster
    ;;
install-keda)
    install_keda
    ;;
create-deployment)
    shift
    create_deployment "$@"
    ;;
get-health)
    shift
    get_health_status "$@"
    ;;
*)
    usage
    ;;
esac

