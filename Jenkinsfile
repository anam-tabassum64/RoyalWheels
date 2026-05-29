def runPlatformCommand(String unixCommand, String windowsCommand) {
  if (isUnix()) {
    sh unixCommand
  } else {
    bat windowsCommand
  }
}

def runWindowsPythonCommand(String commandArgs) {
  bat """
    @echo off
    setlocal
    set "PY_CMD="
    where py >nul 2>nul && set "PY_CMD=py -3"
    if not defined PY_CMD where python3 >nul 2>nul && set "PY_CMD=python3"
    if not defined PY_CMD where python >nul 2>nul && set "PY_CMD=python"
    if not defined PY_CMD (
      echo No Python launcher found. Install Python or add it to PATH.
      exit /b 1
    )
    %PY_CMD% ${commandArgs}
  """
}

pipeline {
  agent any

  environment {
    AWS_REGION = "ap-south-1"
    AWS_ACCOUNT_ID = ""
    ECR_REPO_NAME = "royalwheels-web"
    EKS_CLUSTER_NAME = "royalwheels-eks"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install dependencies') {
      steps {
        script {
          if (isUnix()) {
            sh 'python3 -m pip install --upgrade pip'
            sh 'python3 -m pip install -r backend/requirements.txt'
          } else {
            runWindowsPythonCommand('-m pip install --upgrade pip')
            runWindowsPythonCommand('-m pip install -r backend\\requirements.txt')
          }
        }
      }
    }

    stage('Run tests') {
      steps {
        script {
          if (isUnix()) {
            sh 'python3 backend/manage.py test --failfast'
          } else {
            runWindowsPythonCommand('backend\\manage.py test --failfast')
          }
        }
      }
    }

    stage('Build and push Docker image') {
      steps {
        script {
          runPlatformCommand(
            '''
              if [ -z "$AWS_ACCOUNT_ID" ]; then
                echo "AWS_ACCOUNT_ID is required"
                exit 1
              fi
              IMAGE_NAME="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
              aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
              docker build -t "${IMAGE_NAME}:$GIT_COMMIT" -f Dockerfile .
              docker tag "${IMAGE_NAME}:$GIT_COMMIT" "${IMAGE_NAME}:latest"
              docker push "${IMAGE_NAME}:$GIT_COMMIT"
              docker push "${IMAGE_NAME}:latest"
            ''',
            '''
              if "%AWS_ACCOUNT_ID%"=="" (
                echo AWS_ACCOUNT_ID is required
                exit /b 1
              )
              setlocal enabledelayedexpansion
              set "IMAGE_NAME=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO_NAME%"
              powershell -NoProfile -Command "$pass = aws ecr get-login-password --region %AWS_REGION%; $pass | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com"
              docker build -t !IMAGE_NAME!:%GIT_COMMIT% -f Dockerfile .
              docker tag !IMAGE_NAME!:%GIT_COMMIT% !IMAGE_NAME!:latest
              docker push !IMAGE_NAME!:%GIT_COMMIT%
              docker push !IMAGE_NAME!:latest
            '''
          )
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          runPlatformCommand(
            '''
              aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
              kubectl apply -k k8s/base
              kubectl apply -f k8s/monitoring/prometheus.yaml
              kubectl apply -f k8s/monitoring/grafana.yaml
            ''',
            '''
              aws eks update-kubeconfig --region %AWS_REGION% --name %EKS_CLUSTER_NAME%
              kubectl apply -k k8s/base
              kubectl apply -f k8s/monitoring/prometheus.yaml
              kubectl apply -f k8s/monitoring/grafana.yaml
            '''
          )
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
