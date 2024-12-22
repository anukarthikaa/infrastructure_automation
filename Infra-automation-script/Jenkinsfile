pipeline {
    agent any

    environment {
        SCRIPT_PATH = './infrastructure_script.sh' // Update with the actual path to the script
    }

    parameters {
        string(name: 'DEPLOYMENT_NAME', defaultValue: '', description: 'Name of the deployment')
        string(name: 'IMAGE', defaultValue: '', description: 'Docker image to use for the deployment')
        string(name: 'CPU', defaultValue: '100m', description: 'CPU resource request and limit')
        string(name: 'MEMORY', defaultValue: '128Mi', description: 'Memory resource request and limit')
        string(name: 'PORTS', defaultValue: '8080', description: 'Port to expose')
        string(name: 'NAMESPACE', defaultValue: 'default', description: 'Namespace for the deployment')
        string(name: 'KAFKA_BROKER', defaultValue: '', description: 'Kafka broker address')
        string(name: 'KAFKA_TOPIC', defaultValue: '', description: 'Kafka topic for scaling')
    }
    stages {
        stage('Preparation') {
            steps {
                script {
                    if (!fileExists(SCRIPT_PATH)) {
                        error "Script file not found at: ${SCRIPT_PATH}"
                    }
                }
            }
        }

        stage('Validate Parameters') {
            steps {
                script {
                    // Check if any parameter is missing
                    def mandatoryParams = [
                        'DEPLOYMENT_NAME': params.DEPLOYMENT_NAME,
                        'IMAGE': params.IMAGE,
                        'CPU': params.CPU,
                        'MEMORY': params.MEMORY,
                        'PORTS': params.PORTS,
                        'NAMESPACE': params.NAMESPACE,
                        'KAFKA_BROKER': params.KAFKA_BROKER,
                        'KAFKA_TOPIC': params.KAFKA_TOPIC
                    ]

                    mandatoryParams.each { param, value ->
                        if (!value?.trim()) {
                            error "Parameter '${param}' is required but was not provided. Please provide a value and retry."
                        }
                    }

                    echo "All mandatory parameters are provided."
                }
            }
        }

        stage('Start Minikube') {
            steps {
                script {
                    sh './infrastructure_script.sh start-minikube'
                }
            }
        }
        stage('Connect to Cluster and Setup') {
            steps {
                script {
                    sh './infrastructure_script.sh connect'
                }
            }
        }
        stage('Install KEDA') {
            steps {
                script {
                    sh './infrastructure_script.sh install-keda'
                }
            }
        }
        stage('Create Deployment') {
            steps {
                script {
                    if (!params.DEPLOYMENT_NAME || !params.IMAGE || !params.CPU || !params.MEMORY || !params.PORTS || !params.NAMESPACE || !params.KAFKA_BROKER || !params.KAFKA_TOPIC) {
                        error("Missing required parameters for 'Create Deployment' stage. Ensure all required parameters are provided.")
                    }
                    def deploymentArgs = "${params.DEPLOYMENT_NAME} ${params.IMAGE} ${params.CPU} ${params.MEMORY} ${params.PORTS} ${params.NAMESPACE} ${params.KAFKA_BROKER} ${params.KAFKA_TOPIC}"
                    sh "./infrastructure_script.sh create-deployment ${deploymentArgs}"
                }
            }
        }
        stage('Check Deployment Health') {
            steps {
                script {
                    if (!params.DEPLOYMENT_NAME || !params.NAMESPACE) {
                        error("Missing required parameters for 'Check Deployment Health' stage. Ensure DEPLOYMENT_NAME and NAMESPACE are provided.")
                    }
                    echo "Checking health for deployment ${params.DEPLOYMENT_NAME} in namespace ${params.NAMESPACE}..."
                    sh "./infrastructure_script.sh get-health ${params.DEPLOYMENT_NAME} ${params.NAMESPACE}"
                }
            }
        }
    }
    post {
        success {
            echo "Pipeline executed successfully. Deployment is healthy."
        }
        failure {
            echo "Pipeline execution failed."
        }
    }
}
