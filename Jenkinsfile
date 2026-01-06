pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ashok367/hello-java-k8:latest"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ashok367/hello-java-k8.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('sonar-token')
            }
            steps {
                sh """
                mvn sonar:sonar \
                -Dsonar.projectKey=hello-java-k8 \
                -Dsonar.projectName=hello-java-k8 \
                -Dsonar.login=$SONAR_TOKEN
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push $DOCKER_IMAGE
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
    steps {
        sh '''
        echo "Deploying to Minikube..."

        minikube kubectl -- set image deployment/hello-java-deployment \
        hello-java=ashok367/hello-java-k8:latest

        minikube kubectl -- rollout status deployment/hello-java-deployment
        '''
    }
}



    }

    post {
        success {
            echo "✅ CI/CD Pipeline completed successfully"
        }
        failure {
            echo "❌ CI/CD Pipeline failed"
        }
    }
}

