pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'eu-central-1'
    }

    stages {
        stage('Checkout') {
            steps {
                // Assuming you've set up a GitHub SCM in Jenkins
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // Initialize Terraform
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                    credentialsId: 'aws-secret'
                ]]) {
                    script {
                        // Apply Terraform configuration
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Outputs') {
            steps {
                script {
                    // Output the IP of the Ghost server
                    def ghostIP = sh(script: 'terraform output ghost_server_ip', returnStdout: true).trim()
                    echo "Ghost server IP: ${ghostIP}"
                }
            }
        }
    }

    post {
        always {
            echo "This pipeline has finished."
        }
    }
}
