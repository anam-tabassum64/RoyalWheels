# RoyalWheels 🚗🏍️

RoyalWheels is a comprehensive vehicle rental management platform (Cars & Bikes) built with **Django** on the backend and modern vanilla HTML/CSS/JS for the frontend.

## Key Features
- **Customer Portal**: Book vehicles, manage profiles, multi-login support (Google Sign-In + OTP Email verification).
- **Beautiful UI/UX**: Custom glassmorphism popups, stunning vehicle cards, dynamic search.
- **Admin & Partner Portals**: Rental agencies can manage their own fleet, handle bookings, track revenue, and update vehicle status.
- **Payment Gateway**: Integrated with Razorpay for secure checkout flows.
- **Cloud Storage**: Cloudinary integration for scalable vehicle image storage.

## DevOps & Cloud Infrastructure
This project is fully containerized and includes a comprehensive DevOps scaffold for enterprise-grade deployment:
- **Docker**: Ready-to-go `docker-compose.yml` and `Dockerfile`.
- **Kubernetes**: Standard manifests in `k8s/` for Deployments, Services, Ingress, and HPAs.
- **Terraform**: AWS infrastructure as code in `terraform/` (EKS, RDS, VPC, ECR).
- **Jenkins**: CI/CD pipeline defined in `Jenkinsfile`.
- **Observability**: Prometheus metrics endpoint (`/metrics`), `/healthz/` endpoint, and Grafana dashboards available via Kubernetes deployment.

### AWS deployment with Terraform + EKS
- `terraform/` now includes EKS, VPC, RDS, and ECR infrastructure.
- `k8s/base/` contains the RoyalWheels Kubernetes deployment manifest and service definitions.
- `k8s/monitoring/` contains Prometheus and Grafana manifests for cluster monitoring.
- `Jenkinsfile` builds the Docker image, pushes it to ECR, and deploys the cluster.

Use these files to deploy in your AWS account:

```bash
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars
```

Then configure your Kubernetes context and deploy the manifests:

```bash
aws eks update-kubeconfig --region ap-south-1 --name royalwheels-eks
kubectl apply -k k8s/base
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml
```

## Running Locally

To spin up the entire application along with PostgreSQL and Prometheus:

```bash
docker compose up --build
```
This maps the application to `http://localhost:8000`.

To seed the demo data:
```bash
docker compose exec web python manage.py seed_demo --flush
```

Demo Credentials:
- **Admin**: admin / admin123
- **Customer**: mukundkhandelwal463@gmail.com / Demo@123
- **Partner**: royalwheels_admin / Royal@123

## Environment Variables

For full functionality, ensure the following environment variables are set (either in a `.env` file or in your platform secrets manager):

- `DJANGO_SECRET_KEY`
- `DATABASE_URL`
- `GOOGLE_CLIENT_ID`
- `RAZORPAY_KEY_ID` & `RAZORPAY_KEY_SECRET`
- `EMAIL_HOST_USER` & `EMAIL_HOST_PASSWORD` (for OTP)
- `CLOUDINARY_URL` (for image uploads)

*(See `backend/.env.example` for placeholders).*
