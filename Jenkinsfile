  pipeline {
      agent any

      environment {
          AWS_DEFAULT_REGION = 'ap-south-1'
          ECR_REGISTRY = "897545289989.dkr.ecr.ap-south-1.amazonaws.com"
          IMAGE = "${ECR_REGISTRY}/octabyte-assignment-ecr-repo:${env.GIT_COMMIT.take(7)}"
      }

      stages {
          stage('unittest') {
              steps {
                  sh 'which jq; whoami; echo $PATH'
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
                  sh 'cd app && DB_HOST=localhost DB_PORT=5430 DB_NAME=octabyte_db DB_USER=octabyte_user DB_PASSWORD=octabyte_password python3 -c "from src.main import init_db; init_db()"'
                  sh 'cd app && DB_HOST=localhost DB_PORT=5430 DB_NAME=octabyte_db DB_USER=octabyte_user DB_PASSWORD=octabyte_password python3 -m pytest -m integration'
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
                  sh 'trivy image --severity CRITICAL,HIGH --exit-code 1 $IMAGE || true'
              }
          }

          stage('Push docker image to ECR') {
              steps {
                  withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable:'AWS_SECRET_ACCESS_KEY')]) {
                      sh 'aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_REGISTRY'
                      sh 'docker push $IMAGE'
                  }
              }
          }

          stage('deploy to staging') {
              when {
                    expression { env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main' }
                }    
              steps {
                  withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable:'AWS_SECRET_ACCESS_KEY')]) {
                      sh 'bash ./scripts/deploy.sh staging $IMAGE'
                  }
              }
          }

          stage('Approve Production') {
              when {
                    expression { env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main' }
                }
              steps {
                  input message: 'Approve deployment to production?', ok: 'Deploy'
              }
          }

          stage('deploy to production') {
              when {
                    expression { env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main' }
                }
              steps {
                  withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable:
  'AWS_SECRET_ACCESS_KEY')]) {
                      sh 'bash ./scripts/deploy.sh production $IMAGE'
                  }
              }
          }
      }
post {
      success {
          withCredentials([string(credentialsId: 'slack-webhook-url', variable: 'SLACK_URL')]) {
              sh 'curl -s -X POST -H "Content-type: application/json" --data "{\\"text\\":\\"Build Successful: ${JOB_NAME}
  #${BUILD_NUMBER}\\"}" $SLACK_URL'
          }
      }
      failure {
          withCredentials([string(credentialsId: 'slack-webhook-url', variable: 'SLACK_URL')]) {
              sh 'curl -s -X POST -H "Content-type: application/json" --data "{\\"text\\":\\"Build Failed: ${JOB_NAME}
  #${BUILD_NUMBER}\\"}" $SLACK_URL'
          }
      }
  }
  }
