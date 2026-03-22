#!/bin/bash
# 1. System & Java 25 Setup
sudo dnf update -y
sudo dnf install -y yum-utils unzip python3 python3-pip
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo dnf install -y java-25-amazon-corretto-devel

# 2. Terraform & AWS CLI
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# 3. Jenkins & Storage Redirection
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins

sudo mkdir -p /var/lib/jenkins/tmp
sudo mkdir -p /etc/systemd/system/jenkins.service.d/
sudo cat <<EOT > /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_OPTS=-Djava.io.tmpdir=/var/lib/jenkins/tmp -Djenkins.install.runSetupWizard=false"
EOT

# 4. Memory Safety: 2GB Swap Space
sudo dd if=/dev/zero of=/swapfile bs=128M count=16
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# 5. Groovy Script: Automated Plugin Bootstrap (131 Plugins)
sudo mkdir -p /var/lib/jenkins/init.groovy.d
sudo cat <<EOT > /var/lib/jenkins/init.groovy.d/01-devops-setup.groovy
import jenkins.model.*
import hudson.model.*
import hudson.node_monitors.*

def instance = Jenkins.getInstance()
def uc = instance.getUpdateCenter()
def pm = instance.getPluginManager()

int timeout = 12
while(timeout > 0 && uc.getById("default") == null) {
    uc.updateAllSites()
    Thread.sleep(10000)
    timeout--
}

def plugins = ["aws-credentials", "pipeline-aws", "ec2", "terraform", "kubernetes", "aqua-security-scanner", "aqua-microscanner", "workspace-cleanup", "python", "github", "maven-plugin", "pipeline-maven"]
plugins.each { id ->
    if (!pm.getPlugin(id)) {
        def plugin = uc.getById("default")?.getPlugin(id)
        if (plugin) { plugin.deploy() }
    }
}
instance.save()
EOT



# 6. Final Initialization
sudo chown -R jenkins:jenkins /var/lib/jenkins/
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

sleep 180
sudo systemctl restart jenkins