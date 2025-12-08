# Deployment Guide

This guide provides step-by-step instructions for deploying the Java Web Application to AWS EC2 using Jenkins.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS EC2 Setup](#aws-ec2-setup)
3. [Jenkins Server Setup](#jenkins-server-setup)
4. [Application Deployment](#application-deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting, ensure you have:

- AWS account with EC2 access
- Git repository for the application code
- Database instance (Supabase or PostgreSQL)
- Jenkins server (can be installed on separate EC2 or use existing)

## AWS EC2 Setup

### 1. Launch EC2 Instance

1. Login to AWS Console
2. Navigate to EC2 Dashboard
3. Click "Launch Instance"
4. Configure instance:
   - **Name**: webapp-production
   - **AMI**: Ubuntu Server 22.04 LTS or Amazon Linux 2
   - **Instance Type**: t2.micro (or larger for production)
   - **Key Pair**: Create new or select existing
   - **Network**: Default VPC
   - **Storage**: 20 GB gp3

### 2. Configure Security Group

Add the following inbound rules:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | Your IP | SSH access |
| Custom TCP | 8080 | 0.0.0.0/0 | Application port |
| HTTP | 80 | 0.0.0.0/0 | Optional: HTTP |
| HTTPS | 443 | 0.0.0.0/0 | Optional: HTTPS |

### 3. Connect and Setup EC2

```bash
# Connect to EC2
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 17
sudo apt install openjdk-17-jdk -y

# Verify Java installation
java -version

# Create application directory
sudo mkdir -p /opt/webapp
sudo chown $USER:$USER /opt/webapp

# Create logs directory
mkdir -p /opt/webapp/logs
```

### 4. Configure Elastic IP (Recommended)

1. Go to EC2 Dashboard > Elastic IPs
2. Allocate new Elastic IP
3. Associate with your EC2 instance
4. Update DNS records to point to Elastic IP

## Jenkins Server Setup

### 1. Install Jenkins

**Option A: On separate EC2 instance**

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

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Option B: Using Docker**

```bash
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  jenkins/jenkins:lts
```

### 2. Initial Jenkins Configuration

1. Access Jenkins at `http://jenkins-server:8080`
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Configure Jenkins URL

### 3. Install Required Plugins

Go to `Manage Jenkins` > `Manage Plugins` > `Available`

Install:
- Maven Integration Plugin
- SSH Agent Plugin
- Email Extension Plugin
- Pipeline Plugin
- Git Plugin

### 4. Configure Global Tools

Go to `Manage Jenkins` > `Global Tool Configuration`

**Configure JDK:**
- Name: `JDK17`
- JAVA_HOME: `/usr/lib/jvm/java-17-openjdk-amd64` (Ubuntu)
- Or install automatically from adoptium.net

**Configure Maven:**
- Name: `Maven3`
- Version: 3.9.x (latest)
- Install automatically from Apache

### 5. Configure Credentials

Go to `Manage Jenkins` > `Manage Credentials` > `(global)` > `Add Credentials`

**Add EC2 SSH Key:**
- Kind: SSH Username with private key
- ID: `ec2-ssh-key`
- Username: `ubuntu` (or `ec2-user` for Amazon Linux)
- Private Key: Paste your EC2 key pair content

**Add EC2 Host:**
- Kind: Secret text
- ID: `ec2-host`
- Secret: Your EC2 public IP or Elastic IP

**Add EC2 User:**
- Kind: Secret text
- ID: `ec2-user`
- Secret: `ubuntu` (or `ec2-user`)

**Add Database Credentials:**
- Kind: Secret text
- ID: `database-url`
- Secret: `jdbc:postgresql://your-db-host:5432/postgres`

- Kind: Secret text
- ID: `database-username`
- Secret: Your database username

- Kind: Secret text
- ID: `database-password`
- Secret: Your database password

## Application Deployment

### 1. Create Jenkins Pipeline Job

1. Click "New Item"
2. Enter name: `webapp-deployment`
3. Select "Pipeline"
4. Click "OK"

### 2. Configure Pipeline

**General:**
- Description: "Java Web Application Deployment Pipeline"
- Check "GitHub project" (if using GitHub)
- Project URL: Your repository URL

**Build Triggers:**
- Check "Poll SCM" or "GitHub hook trigger for GITScm polling"
- Schedule: `H/5 * * * *` (every 5 minutes)

**Pipeline:**
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: Your Git repository URL
- Credentials: Add Git credentials if private repo
- Branch: `*/main` or `*/master`
- Script Path: `Jenkinsfile`

### 3. Test SSH Connection

Before running the pipeline, test SSH connection:

```bash
# On Jenkins server
ssh -i /path/to/key ubuntu@your-ec2-ip
```

### 4. Run Pipeline

1. Save the pipeline configuration
2. Click "Build Now"
3. Monitor console output

### 5. Pipeline Stages

The Jenkinsfile includes these stages:

1. **Checkout** - Clone code from Git
2. **Build** - Compile with Maven
3. **Test** - Run unit tests
4. **Code Quality Analysis** - Run verification
5. **Package** - Create JAR file
6. **Archive Artifacts** - Save build artifacts
7. **Deploy to EC2** - Copy and deploy to EC2
8. **Health Check** - Verify deployment

## Verification

### 1. Check Application Status

```bash
# On EC2 instance
cd /opt/webapp
./status.sh
```

### 2. Test API Endpoints

```bash
# Health check
curl http://your-ec2-ip:8080/api/health

# Welcome endpoint
curl http://your-ec2-ip:8080/api

# Create a task
curl -X POST http://your-ec2-ip:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing deployment","completed":false}'

# Get all tasks
curl http://your-ec2-ip:8080/api/tasks
```

### 3. View Application Logs

```bash
# Real-time logs
tail -f /opt/webapp/application.log

# Last 100 lines
tail -n 100 /opt/webapp/application.log

# Search for errors
grep -i error /opt/webapp/application.log
```

## Troubleshooting

### Pipeline Fails at Checkout

**Problem:** Git authentication fails

**Solution:**
- Add Git credentials in Jenkins
- For private repos, add SSH key or access token
- Check repository URL is correct

### Pipeline Fails at Build

**Problem:** Maven build errors

**Solution:**
```bash
# Verify Maven is configured
mvn -version

# Check Java version
java -version

# Clean and rebuild
mvn clean install
```

### Pipeline Fails at Deploy

**Problem:** SSH connection fails

**Solution:**
- Verify EC2 security group allows SSH from Jenkins IP
- Check SSH key permissions (should be 600)
- Test manual SSH connection
- Verify EC2_HOST credential is correct

### Application Won't Start

**Problem:** Application fails to start on EC2

**Solution:**
```bash
# Check Java is installed
java -version

# Check if port is in use
sudo netstat -tuln | grep 8080

# Check application logs
tail -f /opt/webapp/application.log

# Verify database connection
ping your-database-host

# Check environment variables
cat /opt/webapp/.env
```

### Database Connection Fails

**Problem:** Cannot connect to database

**Solution:**
- Verify database credentials
- Check database server is running
- Verify security group allows connection from EC2
- Test connection manually:
```bash
psql -h your-db-host -U your-username -d postgres
```

### Port 8080 Already in Use

**Problem:** Another process using port 8080

**Solution:**
```bash
# Find process using port
sudo lsof -i :8080

# Kill the process
sudo kill -9 <PID>

# Or change application port in application.properties
server.port=8081
```

## Post-Deployment Tasks

### 1. Setup System Service (Optional)

Create systemd service for automatic startup:

```bash
sudo nano /etc/systemd/system/webapp.service
```

Add:
```ini
[Unit]
Description=Java Web Application
After=network.target

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/opt/webapp
ExecStart=/opt/webapp/start.sh
ExecStop=/opt/webapp/stop.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable webapp
sudo systemctl start webapp
```

### 2. Setup Nginx Reverse Proxy (Optional)

```bash
sudo apt install nginx -y

sudo nano /etc/nginx/sites-available/webapp
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable:
```bash
sudo ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 3. Setup SSL with Let's Encrypt (Optional)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

### 4. Configure Monitoring

Setup CloudWatch agent:
```bash
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
```

Configure log streaming:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

## Rollback Procedure

If deployment fails, rollback to previous version:

```bash
# On EC2
cd /opt/webapp

# Stop current version
./stop.sh

# Restore previous JAR (keep backups)
cp webapp.jar.backup webapp.jar

# Start application
./start.sh
```

## Continuous Improvement

1. **Add automated tests** in pipeline
2. **Setup staging environment** before production
3. **Implement blue-green deployment**
4. **Add performance monitoring**
5. **Setup automated backups**
6. **Configure auto-scaling** for high availability

## Support

For issues or questions:
- Check application logs: `/opt/webapp/application.log`
- Review Jenkins console output
- Check AWS CloudWatch logs
- Contact DevOps team

## Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Maven Documentation](https://maven.apache.org/guides/)
