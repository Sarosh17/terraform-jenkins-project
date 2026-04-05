## 🔄 CI/CD Pipeline (Jenkins)

This project includes a fully automated Jenkins pipeline:

### Pipeline Stages:

1. Clone GitHub repository
2. Build Docker image
3. Provision infrastructure using Terraform
4. Fetch EC2 public IP dynamically
5. Wait for EC2 readiness (SSH retry logic)
6. Install Docker on EC2
7. Transfer Docker image via SSH
8. Deploy containerized application
9. Verify deployment using HTTP health check
10. Destroy infrastructure for cleanup

### Key Features:

* Zero-touch deployment
* Dynamic infrastructure handling
* Secure SSH-based deployment
* Automated health verification
* Infrastructure lifecycle management
