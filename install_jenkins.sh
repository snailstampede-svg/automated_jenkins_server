#!/bin/bash
# 1. System & Java 25 Setup (Amazon Corretto)
sudo dnf update -y
sudo dnf install -y yum-utils unzip python3 python3-pip
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo dnf install -y java-25-amazon-corretto-devel

# 2. Tooling: Terraform v1.14.7 & AWS CLI v2
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# 3. Jenkins Installation & Directory Preparation
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins

# 4. CRITICAL FIX: Permissions & Systemd Override
# We create directories and set ownership BEFORE starting the service
sudo mkdir -p /var/lib/jenkins/tmp
sudo mkdir -p /var/lib/jenkins/init.groovy.d
sudo chown -R jenkins:jenkins /var/lib/jenkins/
sudo chmod -R 775 /var/lib/jenkins/tmp

sudo mkdir -p /etc/systemd/system/jenkins.service.d/
sudo cat <<EOT > /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_OPTS=-Djava.io.tmpdir=/var/lib/jenkins/tmp -Djenkins.install.runSetupWizard=false"
EOT

# 5. Memory Stability: 2GB Swap Space
sudo dd if=/dev/zero of=/swapfile bs=128M count=16
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# 6. Groovy "Sledgehammer": Automated Plugin Bootstrap
sudo cat <<EOT > /var/lib/jenkins/init.groovy.d/01-devops-setup.groovy
import jenkins.model.*
import hudson.model.*

def instance = Jenkins.getInstance()
def uc = instance.getUpdateCenter()
def pm = instance.getPluginManager()

// Active wait for Update Center to be reachable
int timeout = 15
while(timeout > 0 && uc.getById("default") == null) {
    uc.updateAllSites()
    Thread.sleep(10000)
    timeout--
}

// Full Plugin List (AWS, GCP, Terraform, DevSecOps, Aqua, GitHub, Maven, Publish)
def plugins = [
    "aws-credentials", "pipeline-aws", "ec2", "amazon-ecs", "aws-codedeploy", 
    "aws-lambda", "amazon-s3-credentials", "aws-secrets-manager-secret-source", 
    "aws-codepipeline", "configuration-as-code-aws-ssm", "cloudformation", "aws-sam",
    "terraform", "kubernetes", "google-storage-plugin", "google-kubernetes-engine", 
    "gcp-java-sdk-auth", "pipeline-gcp-steps", "snyk-security-scanner", "sonar",
    "aqua-docker-scanner", "aqua-microscanner", "aqua-security-serverless",
    "github", "github-oauth", "pipeline-github-lib", "pipeline-githubnotify-step",
    "maven-plugin", "pipeline-maven", "publish-over-ssh", "workspace-cleanup"
]

plugins.each { id ->
    if (!pm.getPlugin(id)) {
        def plugin = uc.getById("default")?.getPlugin(id)
        if (plugin) { 
            println "--- Deploying: \${id} ---"
            plugin.deploy() 
        }
    }
}
instance.save()
EOT

# 7. Final Service Initialization
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for background downloads to settle before the final clean reboot
sleep 420
sudo systemctl restart jenkins