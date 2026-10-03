pipeline {
    agent any
    environment {
        IMAGE = "${ECR_REPO}:${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('unittest') {
            steps {
                sh 'echo "Running unit tests..."'
                sh 'cd app && python3 -m pip install -r requirements.txt'
                sh 'cd app && python3 -m pytest -m unit'
                sh 'python3 -m pip install pip_audit && python3 -m pip_audit -r app/requirements.txt || true'

            }
        }
        
        stage('Integration Test') {
            steps {
                sh 'docker compose up -d db'
                sh 'sleep 10'
                sh 'cd app && DB_HOST=localhost python3 -m pytest -m integration'
            }
            post {
                always {
                    sh 'docker compose down -v'
                }
            }
        }   
        
        stage('Build and scan docker image') {
            steps {
                sh 'docker build -t $IMAGE app'
                sh 'trivy image --severity CRITICAL,HIGH --exit-code 1 $IMAGE'
            }
        }
        
        stage('Push docker image to ECR') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO'
                    sh 'docker push $IMAGE'
                }
            }
        }
        
        stage('deploy to staging') {
            when {
                branch 'main'
            }
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                    sh './scripts/deploy.sh staging $IMAGE'
                }
            }

        }
        
        stage('Approve Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Approve deployment to production?', ok: 'Deploy'
            }
        }
        
        stage('deploy to production') {
            when {
                branch 'main'
            }
            steps {
                withAWS(credentials: 'aws-creds', region: 'ap-south-1') {
                    sh './scripts/deploy.sh production $IMAGE'
                }
            }
        }
    }

post {
    success {
        slackSend channel: '#jenkins', color: 'good', message: "Build Successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
    }
    failure {
        slackSend channel: '#jenkins', color: 'danger', message: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
    }
}

}