pipeline {
    agent any

    tools {
        maven 'maven3'
        jdk 'JDK21'
    }

    environment {
        APP_NAME = 'webapp'
        EC2_HOST = credentials('ec2-host')
        EC2_USER = credentials('ec2-user')
        SSH_KEY = credentials('ec2-ssh-key')
        DATABASE_URL = credentials('database-url')
        DATABASE_USERNAME = credentials('database-username')
        DATABASE_PASSWORD = credentials('database-password')
        DEPLOY_DIR = '/opt/webapp'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building application with Maven...'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                echo 'Running unit tests...'
                sh 'mvn test'
            }


        stage('Code Quality Analysis') {
            steps {
                echo 'Running code quality checks...'
                sh 'mvn verify'
            }
        }

        stage('Package') {
            steps {
                echo 'Packaging application...'
                sh 'mvn package -DskipTests'
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Archiving build artifacts...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo 'Deploying application to EC2...'
                script {
                    sshagent(credentials: ['ec2-ssh-key']) {
                        // Create deployment directory if it doesn't exist
                        sh """
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                sudo mkdir -p ${DEPLOY_DIR}
                                sudo chown ${EC2_USER}:${EC2_USER} ${DEPLOY_DIR}
                            '
                        """

                        // Copy JAR file to EC2
                        sh """
                            scp -o StrictHostKeyChecking=no target/${APP_NAME}.jar ${EC2_USER}@${EC2_HOST}:${DEPLOY_DIR}/
                        """

                        // Copy deployment scripts to EC2
                        sh """
                            scp -o StrictHostKeyChecking=no scripts/start.sh ${EC2_USER}@${EC2_HOST}:${DEPLOY_DIR}/
                            scp -o StrictHostKeyChecking=no scripts/stop.sh ${EC2_USER}@${EC2_HOST}:${DEPLOY_DIR}/
                        """

                        // Set environment variables and restart application
                        sh """
                            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                cd ${DEPLOY_DIR}

                                # Create environment file
                                echo "DATABASE_URL=${DATABASE_URL}" > .env
                                echo "DATABASE_USERNAME=${DATABASE_USERNAME}" >> .env
                                echo "DATABASE_PASSWORD=${DATABASE_PASSWORD}" >> .env
                                echo "SPRING_PROFILES_ACTIVE=prod" >> .env

                                # Make scripts executable
                                chmod +x start.sh stop.sh

                                # Stop existing application
                                ./stop.sh || true

                                # Start new application
                                ./start.sh
                            '
                        """
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    sleep(time: 15, unit: 'SECONDS')
                    sh """
                        curl -f http://${EC2_HOST}:8080/api/health || exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            emailext(
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Good news! The build ${env.BUILD_NUMBER} was successful.",
                to: 'team@example.com'
            )
        }
        failure {
            echo 'Pipeline failed!'
            emailext(
                subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Build ${env.BUILD_NUMBER} failed. Please check the console output.",
                to: 'team@example.com'
            )
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
