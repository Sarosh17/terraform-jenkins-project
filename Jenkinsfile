pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-credentials')
        AWS_SECRET_ACCESS_KEY = credentials('aws-credentials')
        AWS_DEFAULT_REGION    = 'ap-south-1'
    }
    
    stages {
        stage("Clone repo") {
            steps {
                git 'https://github.com/Sarosh17/terraform-jenkins-project.git'
            }
        }
        
        stage("Build Docker Image") {
            steps {
                sh 'docker build -t my-node-app .'
            }
        }
        
        stage("Terraform Init") {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage("Terraform Apply") {
            steps {
                dir('terraform') {
                    sh 'terraform apply --auto-approve'
                }
            }
        }
        
        stage('Get EC2 IP') {
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "cd terraform && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()
                    echo "EC2 Instance IP: ${env.EC2_IP}"
                }
            }
        }
        
        stage('Wait for EC2') {
            steps {
                script {
                    // Wait for SSH to be available
                    sh '''
                        echo "Waiting for EC2 instance to be ready..."
                        for i in {1..30}; do
                            if timeout 5 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i /tmp/ec2-key ec2-user@${EC2_IP} "echo 'SSH ready'" 2>/dev/null; then
                                echo "EC2 instance is ready!"
                                break
                            fi
                            echo "Attempt $i: Not ready yet. Waiting..."
                            sleep 10
                        done
                    '''
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-key',
                    keyFileVariable: 'SSH_KEY_FILE'
                )]) {
                    sh '''
                        # Copy the SSH key to a known location
                        cp $SSH_KEY_FILE /tmp/ec2-key
                        chmod 600 /tmp/ec2-key
                        
                        # First, install Docker on EC2
                        echo "Installing Docker on EC2..."
                        ssh -i /tmp/ec2-key -o StrictHostKeyChecking=no ec2-user@${EC2_IP} << 'INSTALL_DOCKER'
                            if ! command -v docker &> /dev/null; then
                                sudo yum update -y
                                sudo yum install -y docker
                                sudo service docker start
                                sudo chkconfig docker on
                                sudo usermod -aG docker ec2-user
                                echo "Docker installed successfully"
                            else
                                echo "Docker already installed"
                            fi
                            docker --version
INSTALL_DOCKER
                        
                        # Now transfer the Docker image
                        echo "Transferring Docker image to EC2..."
                        docker save my-node-app | ssh -i /tmp/ec2-key -o StrictHostKeyChecking=no ec2-user@${EC2_IP} 'sudo docker load'
                        
                        # Deploy the container
                        echo "Deploying container..."
                        ssh -i /tmp/ec2-key -o StrictHostKeyChecking=no ec2-user@${EC2_IP} << 'DEPLOY'
                            # Stop and remove existing container
                            sudo docker stop myapp 2>/dev/null || true
                            sudo docker rm myapp 2>/dev/null || true
                            
                            # Run the new container
                            sudo docker run -d \
                                --name myapp \
                                --restart unless-stopped \
                                -p 3000:3000 \
                                my-node-app
                            
                            echo ""
                            echo "Container status:"
                            sudo docker ps --filter "name=myapp"
                            echo ""
                            echo "Application deployed successfully!"
                            echo "Access it at: http://${EC2_IP}:3000"
DEPLOY
                        
                        # Clean up
                        rm -f /tmp/ec2-key
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "Waiting for application to start..."
                    sleep 15
                    
                    if curl -s -o /dev/null -w "%{http_code}" http://${EC2_IP}:3000 | grep -q "200"; then
                        echo "✅ Application is running!"
                        echo "🌐 http://${EC2_IP}:3000"
                    else
                        echo "⚠️ Application may still be starting..."
                        echo "Check manually at: http://${EC2_IP}:3000"
                    fi
                '''
            }
        }
        stage('Terraform destroy'){
            steps{
                dir('terraform'){
                sh 'terraform destroy --auto-approve'
                }
            }
        }
    }
}
