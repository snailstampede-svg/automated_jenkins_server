# ☁️ Automated Jenkins DevOps Master
### Fully Scripted Infrastructure as Code (IaC) Deployment

This repository contains a professional-grade, zero-touch deployment of a Jenkins Master server on **Amazon Linux 2023**. It is engineered to bypass common cloud bottlenecks and provides a "ready-to-work" environment for Cloud Computing and DevOps labs.

---

## 🚀 Key Features
* **Infrastructure as Code:** Managed entirely via Terraform with dynamic AMI lookups.
* **Modern Tech Stack:** * **Java 25 (LTS):** Running on the latest Amazon Corretto distribution.
    * **Terraform v1.14.7:** Pre-installed for nested IaC workflows.
    * **AWS CLI v2:** Latest version for cloud resource management.
    * **Python 3.14:** High-performance runtime for automation.
* **Automated "Setup Wizard" Bypass:** Jenkins is configured to skip the initial setup screen and go straight to the login.
* **131 Plugins Pre-installed:** Uses Groovy initialization hooks to force-install a full DevOps suite (AWS, Terraform, Kubernetes, Python, GitHub, etc.) on first boot.
* **Storage Optimization:** * **30GB GP3 Volume** with automated `/tmp` redirection to avoid disk pressure errors.
    * **2GB Swap Space** for memory stability on `t3.small` instances.

---

## 📂 Project Structure
* `main.tf`: The Terraform configuration for AWS resources (EC2, Security Groups, Outputs).
* `install_jenkins.sh`: The external bash script that handles OS-level installation and Jenkins orchestration.

---

## 🛠️ Quick Start

### 1. Prepare the Environment
Ensure you have Terraform installed and your AWS credentials configured. Place `main.tf` and `install_jenkins.sh` in the same directory.

### 2. Deploy
```bash
terraform init
terraform apply -auto-approve

*Note: This readme was created with the assistance of ChatGPT
