def runPlatformCommand(String unixCommand, String windowsCommand) {
  if (isUnix()) {
    sh unixCommand
  } else {
    bat windowsCommand
  }
}

def requireWindowsTool(String toolName) {
  bat """
    @echo off
    where ${toolName} >nul 2>nul
    if errorlevel 1 (
      echo Required tool '${toolName}' is not available on this Jenkins agent.
      exit /b 1
    )
  """
}

def resolveAwsAccountId() {
  if (isUnix()) {
    return sh(returnStdout: true, script: 'aws sts get-caller-identity --query Account --output text').trim()
  }

  return powershell(returnStdout: true, script: '$acct = aws sts get-caller-identity --query Account --output text; $acct.Trim()').trim()
}

pipeline {
  agent any

  parameters {
    string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'Optional AWS account ID check for the ECR registry')
    string(name: 'AWS_CREDENTIALS_ID', defaultValue: '', description: 'Jenkins credentials ID containing AWS access key ID and secret access key')
  }

  environment {
    AWS_REGION = "ap-south-1"
    ECR_REPO_NAME = "royalwheels-web"
    EKS_CLUSTER_NAME = "royalwheels-eks"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Validate environment') {
      steps {
        script {
          if (isUnix()) {
            sh 'python3 --version'
            sh 'docker --version'
            sh 'aws --version'
            sh 'kubectl version --client --short'
          } else {
            requireWindowsTool('docker')
            requireWindowsTool('aws')
            requireWindowsTool('kubectl')
            bat '@echo off && docker version'
          }

          if (!params.AWS_CREDENTIALS_ID?.trim()) {
            error("AWS_CREDENTIALS_ID parameter is required. Set it to a Jenkins credential ID that contains AWS access keys.")
          }
        }
      }
    }

    stage('Install dependencies') {
      steps {
        script {
          if (isUnix()) {
            sh '''
              rm -rf .deps
              docker run --rm -v "$PWD:/code" -w /code python:3.14-slim sh -lc "python -m pip install --upgrade pip && python -m pip install --target /code/.deps -r backend/requirements.txt"
            '''
          } else {
            bat """
              @echo off
              if exist .deps rmdir /s /q .deps
              docker run --rm -v "%CD%:/code" -w /code python:3.14-slim sh -lc "python -m pip install --upgrade pip && python -m pip install --target /code/.deps -r backend/requirements.txt"
            """
          }
        }
      }
    }

    stage('Run tests') {
      steps {
        script {
          if (isUnix()) {
            sh 'PYTHONPATH="$PWD/.deps" python3 backend/manage.py test --failfast'
          } else {
            bat """
              @echo off
              docker run --rm -v "%CD%:/code" -w /code -e PYTHONPATH=/code/.deps python:3.14-slim sh -lc "python backend/manage.py test --failfast"
            """
          }
        }
      }
    }

    stage('Build and push Docker image') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: params.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
            withEnv(["AWS_DEFAULT_REGION=${env.AWS_REGION}"]) {
              def resolvedAccountId = resolveAwsAccountId()
              if (params.AWS_ACCOUNT_ID?.trim() && params.AWS_ACCOUNT_ID.trim() != resolvedAccountId) {
                error("AWS_ACCOUNT_ID (${params.AWS_ACCOUNT_ID.trim()}) does not match the AWS account for the supplied Jenkins credential (${resolvedAccountId}). Update the parameter or use matching AWS credentials.")
              }

              env.AWS_ACCOUNT_ID = resolvedAccountId
              def registry = "${resolvedAccountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
              def imageName = "${registry}/${env.ECR_REPO_NAME}"

              if (isUnix()) {
                sh """
                  aws sts get-caller-identity
                  aws ecr describe-repositories --repository-names "${env.ECR_REPO_NAME}" --region "$AWS_REGION"
                  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${registry}"
                  docker build -t "${imageName}:$GIT_COMMIT" -f Dockerfile .
                  docker tag "${imageName}:$GIT_COMMIT" "${imageName}:latest"
                  docker push "${imageName}:$GIT_COMMIT"
                  docker push "${imageName}:latest"
                """
              } else {
                powershell """
                  \$ErrorActionPreference = 'Stop'
                  \$registry = '${registry}'
                  aws sts get-caller-identity | Out-Host
                  aws ecr describe-repositories --repository-names '${env.ECR_REPO_NAME}' --region '${env.AWS_REGION}' | Out-Host
                  \$password = aws ecr get-login-password --region '${env.AWS_REGION}'
                  if (-not \$password) { throw 'Failed to fetch ECR authorization token.' }
                  \$password | docker login --username AWS --password-stdin \$registry
                  docker build -t '${imageName}:$GIT_COMMIT' -f Dockerfile .
                  docker tag '${imageName}:$GIT_COMMIT' '${imageName}:latest'
                  docker push '${imageName}:$GIT_COMMIT'
                  docker push '${imageName}:latest'
                """
              }
            }
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: params.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
            withEnv(["AWS_DEFAULT_REGION=${env.AWS_REGION}"]) {
              def resolvedAccountId = env.AWS_ACCOUNT_ID?.trim() ? env.AWS_ACCOUNT_ID.trim() : resolveAwsAccountId()
              def imageName = "${resolvedAccountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO_NAME}"

              if (isUnix()) {
                sh """
                  aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
                  kubectl apply -k k8s/base
                  kubectl set image deployment/royalwheels royalwheels="${imageName}:$GIT_COMMIT" -n royalwheels
                  kubectl rollout status deployment/royalwheels -n royalwheels --timeout=180s
                  kubectl apply -f k8s/monitoring/prometheus.yaml
                  kubectl apply -f k8s/monitoring/grafana.yaml
                """
              } else {
                bat """
                  @echo off
                  aws eks update-kubeconfig --region %AWS_REGION% --name %EKS_CLUSTER_NAME%
                  kubectl apply -k k8s/base
                  kubectl set image deployment/royalwheels royalwheels="${imageName}:$GIT_COMMIT" -n royalwheels
                  kubectl rollout status deployment/royalwheels -n royalwheels --timeout=180s
                  kubectl apply -f k8s/monitoring/prometheus.yaml
                  kubectl apply -f k8s/monitoring/grafana.yaml
                """
              }
            }
          }
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
