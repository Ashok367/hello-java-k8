This project demonstrates an end-to-end CI/CD pipeline for a Java web application using:

GitHub – Source Code Management

Jenkins – CI/CD automation

SonarQube – Code quality analysis

Docker – Application containerization

Docker Hub – Image registry

Kubernetes (Minikube) – Container orchestration

The pipeline automatically:

Builds the Java application

Performs static code analysis

Builds and pushes a Docker image

Deploys the updated image to Kubernetes (Minikube)

🧱 Architecture Flow
Developer → GitHub
          → Jenkins
          → Maven Build
          → SonarQube Scan
          → Docker Build
          → Docker Hub
          → Minikube (Kubernetes)
          → Application Access (Browser)

🖥️ Environment Details

OS: Ubuntu (AWS EC2)

Java: 17

Tomcat: 9

Kubernetes: Minikube (Docker driver)

Docker Hub Repo: ashok367/hello-java-k8

GitHub Repo: hello-java-k8

📁 Project Structure
hello-java-k8/
├── src/
│   └── main/
│       ├── java/
│       └── webapp/
│           └── WEB-INF/
│               └── web.xml
├── Dockerfile
├── Jenkinsfile
├── deployment.yaml
├── service.yaml
├── pom.xml
└── README.md

🔧 STEP 1: Launch EC2 & Connect
ssh -i key_value_devops.pem ubuntu@<EC2_PUBLIC_IP>

🔧 STEP 2: Install Required Tools
Update system
sudo apt update && sudo apt upgrade -y

Install Java
sudo apt install openjdk-17-jdk -y

Install Maven
sudo apt install maven -y

Install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu


Re-login after this step.

🔧 STEP 3: Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins


Access Jenkins:

http://<EC2_PUBLIC_IP>:8080


Get initial password:

sudo cat /var/lib/jenkins/secrets/initialAdminPassword

🔧 STEP 4: Install SonarQube (Docker)
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts


Access:

http://<EC2_PUBLIC_IP>:9000


Login:

admin / admin


Create a SonarQube token.

🔧 STEP 5: Install Minikube & kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/


Start Minikube:

minikube start --driver=docker


Verify:

minikube status
kubectl get nodes

🔧 STEP 6: Kubernetes Manifests
deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-java-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-java
  template:
    metadata:
      labels:
        app: hello-java
    spec:
      containers:
      - name: hello-java
        image: ashok367/hello-java-k8:latest
        ports:
        - containerPort: 8080

service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-java-service
spec:
  type: NodePort
  selector:
    app: hello-java
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30007


Apply:

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

🔧 STEP 7: Dockerfile
FROM tomcat:9.0-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/hello-java-k8.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

🔧 STEP 8: Jenkins Credentials

Add in Jenkins → Manage Jenkins → Credentials

SonarQube Token

ID: sonar-token

Type: Secret Text

Docker Hub

ID: dockerhub-creds

Type: Username & Password

Username: ashok367

🔧 STEP 9: Jenkinsfile (Final)
pipeline {
    agent any

    environment {
        IMAGE = "ashok367/hello-java-k8:latest"
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/ashok367/hello-java-k8.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('sonar-token')
            }
            steps {
                sh '''
                mvn sonar:sonar \
                -Dsonar.projectKey=hello-java-k8 \
                -Dsonar.projectName=hello-java-k8 \
                -Dsonar.login=$SONAR_TOKEN
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t $IMAGE .'
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push $IMAGE
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                minikube kubectl -- set image deployment/hello-java-deployment \
                hello-java=ashok367/hello-java-k8:latest

                minikube kubectl -- rollout status deployment/hello-java-deployment
                '''
            }
        }
    }
}

🌐 STEP 10: Access the Application
Port Forward
kubectl port-forward service/hello-java-service 8085:8080

Browser
http://localhost:8085/hello

From Laptop (SSH Tunnel)
ssh -i key_value_devops.pem -L 8085:localhost:8085 ubuntu@<EC2_PUBLIC_IP>


Then open:

http://localhost:8085/hello
