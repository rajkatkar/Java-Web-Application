# Jenkins Setup Guide

Complete guide for setting up Jenkins to deploy the Java Web Application to AWS EC2.

## Quick Start

1. Install Jenkins
2. Configure tools and plugins
3. Add credentials
4. Create pipeline job
5. Run deployment

## Prerequisites

- Jenkins server (2.4+ recommended)
- Java 17 installed on Jenkins server
- Maven 3.6+ installed on Jenkins server
- Access to EC2 instance
- Git repository access

## Step 1: Jenkins Installation

### On Ubuntu/Debian

```bash
# Install Java
sudo apt update
sudo apt install openjdk-17-jdk -y

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins
```

### On Amazon Linux 2

```bash
# Install Java
sudo amazon-linux-extras install java-openjdk17 -y

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo yum install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### Access Jenkins

1. Open browser: `http://your-jenkins-server:8080`
2. Get initial password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
3. Complete setup wizard
4. Install suggested plugins
5. Create admin user

## Step 2: Install Required Plugins

Navigate to: `Manage Jenkins` > `Manage Plugins` > `Available`

### Essential Plugins

- **Maven Integration Plugin** - Maven project builds
- **Pipeline Plugin** - Pipeline support
- **Git Plugin** - Git repository integration
- **SSH Agent Plugin** - SSH operations
- **Credentials Binding Plugin** - Credential management
- **Email Extension Plugin** - Email notifications
- **JUnit Plugin** - Test result publishing
- **Workspace Cleanup Plugin** - Clean workspace

### Optional But Recommended

- **Blue Ocean** - Modern UI
- **Build Timeout Plugin** - Prevent hanging builds
- **Timestamper Plugin** - Add timestamps to logs
- **Pipeline Stage View Plugin** - Better pipeline visualization
- **GitHub Integration Plugin** - If using GitHub

Install plugins and restart Jenkins:
```bash
sudo systemctl restart jenkins
```

## Step 3: Configure Global Tools

Navigate to: `Manage Jenkins` > `Global Tool Configuration`

### Configure JDK

1. Click "Add JDK"
2. **Name**: `JDK17`
3. Uncheck "Install automatically" (if already installed)
4. **JAVA_HOME**: `/usr/lib/jvm/java-17-openjdk-amd64` (Ubuntu)
   - For Amazon Linux: `/usr/lib/jvm/java-17-amazon-corretto`
5. Or check "Install automatically" and select:
   - Install from adoptium.net
   - Version: jdk-17 (LTS)

### Configure Maven

1. Click "Add Maven"
2. **Name**: `Maven3`
3. Check "Install automatically"
4. **Version**: Select latest 3.9.x
5. Or if already installed:
   - Uncheck "Install automatically"
   - **MAVEN_HOME**: `/usr/share/maven`

### Configure Git

Usually auto-detected, but if needed:
1. **Name**: `Default`
2. **Path**: `/usr/bin/git`

Save configuration.

## Step 4: Configure Credentials

Navigate to: `Manage Jenkins` > `Manage Credentials` > `(global)` > `Add Credentials`

### 1. EC2 SSH Key

- **Kind**: SSH Username with private key
- **Scope**: Global
- **ID**: `ec2-ssh-key`
- **Description**: `EC2 Instance SSH Key`
- **Username**: `ubuntu` (for Ubuntu) or `ec2-user` (for Amazon Linux)
- **Private Key**:
  - Select "Enter directly"
  - Paste your EC2 `.pem` key content
- Click "Create"

### 2. EC2 Host

- **Kind**: Secret text
- **Scope**: Global
- **ID**: `ec2-host`
- **Description**: `EC2 Instance Public IP`
- **Secret**: Your EC2 public IP or Elastic IP (e.g., `54.123.45.67`)
- Click "Create"

### 3. EC2 User

- **Kind**: Secret text
- **Scope**: Global
- **ID**: `ec2-user`
- **Description**: `EC2 SSH Username`
- **Secret**: `ubuntu` or `ec2-user`
- Click "Create"

### 4. Database URL

- **Kind**: Secret text
- **Scope**: Global
- **ID**: `database-url`
- **Description**: `Database JDBC URL`
- **Secret**: `jdbc:postgresql://your-db-host.supabase.co:5432/postgres`
- Click "Create"

### 5. Database Username

- **Kind**: Secret text
- **Scope**: Global
- **ID**: `database-username`
- **Description**: `Database Username`
- **Secret**: Your database username (e.g., `postgres`)
- Click "Create"

### 6. Database Password

- **Kind**: Secret text
- **Scope**: Global
- **ID**: `database-password`
- **Description**: `Database Password`
- **Secret**: Your database password
- Click "Create"

### 7. Git Credentials (if private repository)

- **Kind**: Username with password
- **Scope**: Global
- **ID**: `git-credentials`
- **Username**: Your Git username
- **Password**: Your Git password or access token
- Click "Create"

## Step 5: Create Pipeline Job

### Create New Job

1. Click "New Item"
2. **Enter name**: `webapp-deployment`
3. **Select**: Pipeline
4. Click "OK"

### Configure Job

#### General Section

- **Description**: `Java Web Application CI/CD Pipeline for EC2 Deployment`
- **Discard old builds**: Check
  - **Days to keep**: 7
  - **Max # of builds**: 10

#### GitHub Project (if using GitHub)

- Check "GitHub project"
- **Project url**: `https://github.com/your-username/your-repo`

#### Build Triggers

Select one or more:

**Option 1: Poll SCM** (Check periodically)
- Check "Poll SCM"
- **Schedule**: `H/5 * * * *` (every 5 minutes)

**Option 2: GitHub Webhook** (Recommended)
- Check "GitHub hook trigger for GITScm polling"
- Configure webhook in GitHub repository:
  - Go to repository Settings > Webhooks > Add webhook
  - **Payload URL**: `http://your-jenkins-server:8080/github-webhook/`
  - **Content type**: application/json
  - **Events**: Just the push event

**Option 3: Scheduled Build**
- Check "Build periodically"
- **Schedule**: `H 2 * * *` (daily at 2 AM)

#### Pipeline Section

- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: Your Git repository URL
  - Example: `https://github.com/your-username/your-repo.git`
- **Credentials**: Select git-credentials (if private repo)
- **Branches to build**: `*/main` or `*/master`
- **Script Path**: `Jenkinsfile`
- **Lightweight checkout**: Check (optional, faster)

#### Advanced Options (Optional)

- **Pipeline speed/durability override**: Performance-optimized

### Save Configuration

Click "Save"

## Step 6: Test Pipeline

### Manual Test

1. Click "Build Now"
2. Watch build progress in "Build History"
3. Click on build number (e.g., #1)
4. Click "Console Output" to see logs

### Verify Each Stage

The pipeline should execute these stages:
1. Checkout ✓
2. Build ✓
3. Test ✓
4. Code Quality Analysis ✓
5. Package ✓
6. Archive Artifacts ✓
7. Deploy to EC2 ✓
8. Health Check ✓

## Step 7: Verify Deployment

### Check Application on EC2

```bash
# SSH to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check application status
cd /opt/webapp
./status.sh

# View logs
tail -f application.log
```

### Test API Endpoints

```bash
# Health check
curl http://your-ec2-ip:8080/api/health

# Welcome endpoint
curl http://your-ec2-ip:8080/api
```

## Troubleshooting

### Build Fails: Maven Not Found

**Error**: `mvn: command not found`

**Solution**:
```bash
# On Jenkins server
sudo apt install maven -y
# Or configure Maven in Global Tool Configuration
```

### Build Fails: SSH Connection

**Error**: `Permission denied (publickey)`

**Solutions**:
1. Verify SSH key credential is correct
2. Check key permissions on Jenkins server
3. Test manual SSH connection:
```bash
ssh -i /path/to/key ubuntu@ec2-ip
```
4. Verify EC2 security group allows SSH from Jenkins IP

### Build Fails: Git Authentication

**Error**: `Authentication failed`

**Solutions**:
1. Add Git credentials in Jenkins
2. Use SSH URL instead of HTTPS
3. Generate personal access token (for GitHub/GitLab)

### Build Succeeds But Application Not Running

**Check**:
```bash
# On EC2
cd /opt/webapp
tail -n 100 application.log

# Check if Java is running
ps aux | grep java

# Check port
sudo netstat -tuln | grep 8080
```

### Pipeline Hangs

**Solutions**:
1. Install "Build Timeout Plugin"
2. Add timeout to Jenkinsfile:
```groovy
options {
    timeout(time: 30, unit: 'MINUTES')
}
```

## Email Notifications

### Configure Email

1. Go to `Manage Jenkins` > `Configure System`
2. Scroll to "Extended E-mail Notification"
3. Configure SMTP server:
   - **SMTP server**: smtp.gmail.com
   - **SMTP Port**: 465
   - **Credentials**: Add Gmail app password
   - **Use SSL**: Check
4. Default recipients: your-team@example.com
5. Save

### Update Jenkinsfile

Change email addresses in post section:
```groovy
post {
    success {
        emailext(
            subject: "SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
            body: "Build successful!",
            to: 'your-team@example.com'
        )
    }
}
```

## Security Best Practices

1. **Enable CSRF Protection**
   - Manage Jenkins > Configure Global Security
   - Check "Prevent Cross Site Request Forgery exploits"

2. **Configure User Authentication**
   - Use Jenkins' own user database or LDAP
   - Don't allow anonymous read access

3. **Use Role-Based Access**
   - Install "Role-based Authorization Strategy" plugin
   - Define roles: admin, developer, viewer

4. **Secure Credentials**
   - Never log credentials in console output
   - Use Credentials Binding Plugin
   - Regularly rotate secrets

5. **Enable HTTPS**
```bash
# Generate self-signed certificate
sudo keytool -genkey -keyalg RSA -alias jenkins \
  -keystore /var/lib/jenkins/jenkins.jks \
  -storepass changeit -keysize 2048

# Configure Jenkins to use HTTPS
sudo nano /etc/default/jenkins
# Add: JENKINS_ARGS="--httpPort=-1 --httpsPort=8443 --httpsKeyStore=/var/lib/jenkins/jenkins.jks --httpsKeyStorePassword=changeit"

sudo systemctl restart jenkins
```

## Maintenance

### Backup Jenkins Configuration

```bash
# Backup Jenkins home
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/jenkins/

# Backup specific job
sudo tar -czf webapp-job-backup.tar.gz \
  /var/lib/jenkins/jobs/webapp-deployment/
```

### Update Jenkins

```bash
# Ubuntu
sudo apt update
sudo apt install jenkins

# Amazon Linux
sudo yum update jenkins
```

### Monitor Disk Space

```bash
# Check Jenkins disk usage
du -sh /var/lib/jenkins/

# Clean old builds
# Set in job configuration: Discard old builds
```

## Advanced Configuration

### Parallel Builds

Enable in job configuration:
- Check "Execute concurrent builds if necessary"

### Build Parameters

Add parameters to make pipeline flexible:
```groovy
parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'])
    string(name: 'BRANCH_NAME', defaultValue: 'main')
}
```

### Pipeline Library

Create shared library for reusable pipeline code:
1. Create repository: jenkins-shared-library
2. Configure in Manage Jenkins > Configure System
3. Use in Jenkinsfile: `@Library('my-library')`

## Monitoring and Logging

### View Build History

- Dashboard > Build History
- Filter by status: Success, Failed, Unstable

### Pipeline Analytics

Install "Build Metrics Plugin" for:
- Build duration trends
- Success/failure rates
- Mean time to recovery

### Integration with CloudWatch

Send logs to CloudWatch:
```bash
# Install CloudWatch Logs plugin
# Configure in job: Post-build Actions > Send build log to CloudWatch
```

## Support Resources

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Plugin Index](https://plugins.jenkins.io/)
- [Jenkins Community](https://www.jenkins.io/participate/)

## Next Steps

1. ✓ Jenkins installed and configured
2. ✓ Pipeline created and tested
3. ✓ Application deployed to EC2
4. → Setup monitoring and alerts
5. → Configure staging environment
6. → Implement automated testing
7. → Setup blue-green deployment
