# Jenkins and AWS Setup for RoyalWheels

Use this checklist to get the `RoyalWheels` Jenkins pipeline past the AWS/ECR stage.

## 1. Create the Jenkins credential

In Jenkins:

1. Go to `Manage Jenkins`.
2. Open `Credentials`.
3. Choose `System`.
4. Open `Global credentials (unrestricted)`.
5. Click `Add Credentials`.
6. Set:
   - `Kind`: `Username with password`
   - `Username`: your AWS Access Key ID
   - `Password`: your AWS Secret Access Key
   - `ID`: `aws-jenkins-creds`
   - `Description`: `AWS credentials for RoyalWheels`
7. Click `Create`.

## 2. Configure the Jenkins job

In the `RoyalWheels` job:

1. Click `Configure`.
2. Enable `This project is parameterized`.
3. Add a `String Parameter`:
   - `Name`: `AWS_ACCOUNT_ID`
   - `Default Value`: `148274106014`
4. Add another `String Parameter`:
   - `Name`: `AWS_CREDENTIALS_ID`
   - `Default Value`: `aws-jenkins-creds`
5. Save the job.
6. Click `Build with Parameters`.
7. Confirm the same values and start the build.

## 3. Create or verify the ECR repository

Make sure this repository exists in AWS:

- Region: `ap-south-1`
- Repository name: `royalwheels-web`

If it does not exist, create it in the same AWS account used by the Jenkins credential.

## 4. Attach IAM permissions to the AWS user

Attach the following policy to the IAM user whose access key is stored in Jenkins.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:PutImage",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages"
      ],
      "Resource": "*"
    }
  ]
}
```

If you want Jenkins to deploy to EKS too, add:

```json
{
  "Effect": "Allow",
  "Action": [
    "eks:DescribeCluster"
  ],
  "Resource": "*"
}
```

## 5. Quick validation

If everything is wired correctly, the pipeline should show:

- `aws sts get-caller-identity`
- `aws ecr describe-repositories`
- successful Docker login to ECR
- image build and push

## 6. Common mistakes

- Using the wrong `AWS_ACCOUNT_ID`
- Credential ID mismatch between Jenkins and the job parameter
- AWS keys without ECR permissions
- ECR repository missing in `ap-south-1`
- AWS credentials belonging to a different AWS account
