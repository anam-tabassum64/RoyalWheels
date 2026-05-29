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
    setlocal EnableExtensions
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

pipeline {
  agent any

  parameters {
    string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'AWS account ID used for the ECR registry')
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
            runWindowsPythonCommand('--version')
            requireWindowsTool('docker')
            requireWindowsTool('aws')
            requireWindowsTool('kubectl')
          }

          if (!params.AWS_ACCOUNT_ID?.trim()) {
            error("AWS_ACCOUNT_ID parameter is required. Set it in the Jenkins job before running the pipeline.")
          }
        }
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
          def imageName = "${params.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO_NAME}"

          if (isUnix()) {
            sh """
              aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${params.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
              docker build -t "${imageName}:$GIT_COMMIT" -f Dockerfile .
              docker tag "${imageName}:$GIT_COMMIT" "${imageName}:latest"
              docker push "${imageName}:$GIT_COMMIT"
              docker push "${imageName}:latest"
            """
          } else {
            bat """
              @echo off
              setlocal EnableExtensions EnableDelayedExpansion
              set "IMAGE_NAME=${imageName}"
              for /f "delims=" %%I in ('aws ecr get-login-password --region %AWS_REGION%') do set "ECR_PASSWORD=%%I"
              echo !ECR_PASSWORD! | docker login --username AWS --password-stdin ${params.AWS_ACCOUNT_ID}.dkr.ecr.%AWS_REGION%.amazonaws.com
              docker build -t !IMAGE_NAME!:%GIT_COMMIT% -f Dockerfile .
              docker tag !IMAGE_NAME!:%GIT_COMMIT% !IMAGE_NAME!:latest
              docker push !IMAGE_NAME!:%GIT_COMMIT%
              docker push !IMAGE_NAME!:latest
            """
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          if (isUnix()) {
            sh """
              aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
              kubectl apply -k k8s/base
              kubectl apply -f k8s/monitoring/prometheus.yaml
              kubectl apply -f k8s/monitoring/grafana.yaml
            """
          } else {
            bat """
              @echo off
              aws eks update-kubeconfig --region %AWS_REGION% --name %EKS_CLUSTER_NAME%
              kubectl apply -k k8s/base
              kubectl apply -f k8s/monitoring/prometheus.yaml
              kubectl apply -f k8s/monitoring/grafana.yaml
            """
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
