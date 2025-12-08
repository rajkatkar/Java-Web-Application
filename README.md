# Java-Web-Application

Java Web Application with Jenkins CI/CD

A production-ready Spring Boot web application with automated CI/CD pipeline for AWS EC2 deployment using Jenkins.

## Features

- RESTful API built with Spring Boot 3.2.0
- Task management system with CRUD operations
- PostgreSQL database integration (Supabase compatible)
- Automated CI/CD pipeline with Jenkins
- Health check endpoints
- Comprehensive unit tests
- Production-ready deployment scripts

## Technology Stack

- Java 17
- Spring Boot 3.2.0
- Maven 3
- PostgreSQL
- Jenkins
- AWS EC2

## Project Structure

```
.
├── src/
│   ├── main/
│   │   ├── java/com/example/webapp/
│   │   │   ├── WebApplication.java          # Main application class
│   │   │   ├── controller/                  # REST controllers
│   │   │   │   ├── HomeController.java
│   │   │   │   └── TaskController.java
│   │   │   ├── model/                       # Entity models
│   │   │   │   └── Task.java
│   │   │   ├── repository/                  # Data repositories
│   │   │   │   └── TaskRepository.java
│   │   │   └── service/                     # Business logic
│   │   │       └── TaskService.java
│   │   └── resources/
│   │       ├── application.properties       # Default configuration
│   │       └── application-prod.properties  # Production configuration
│   └── test/                                # Unit tests
├── scripts/                                 # Deployment scripts
│   ├── start.sh
│   ├── stop.sh
│   ├── restart.sh
│   └── status.sh
├── Jenkinsfile                              # Jenkins pipeline configuration
└── pom.xml                                  # Maven configuration
```

## API Endpoints

### General Endpoints

- `GET /api` - Welcome message and application info
- `GET /api/health` - Health check endpoint

### Task Management Endpoints

- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/{id}` - Get task by ID
- `GET /api/tasks/status/{completed}` - Get tasks by completion status
- `GET /api/tasks/search?keyword={keyword}` - Search tasks by title
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update task
- `PATCH /api/tasks/{id}/toggle` - Toggle task completion status
- `DELETE /api/tasks/{id}` - Delete task

## Local Development

### Prerequisites

- Java 17 or higher
- Maven 3.6 or higher
- PostgreSQL database

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd project
```

2. Configure database connection in `src/main/resources/application.properties`:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/webapp
spring.datasource.username=your_username
spring.datasource.password=your_password
```

3. Build the application:
```bash
mvn clean install
```

4. Run the application:
```bash
mvn spring-boot:run
```

5. Access the application at `http://localhost:8080`

### Running Tests

```bash
mvn test
```

## Jenkins Setup

### Prerequisites

1. Jenkins server installed and running
2. Java 17 and Maven 3 configured in Jenkins
3. SSH access to EC2 instance
4. Required Jenkins plugins:
   - Maven Integration
   - SSH Agent
   - Email Extension
   - JUnit

### Jenkins Configuration

1. **Install Required Tools in Jenkins:**
   - Go to `Manage Jenkins` > `Global Tool Configuration`
   - Add JDK 17 (name: `JDK17`)
   - Add Maven 3 (name: `Maven3`)

2. **Configure Credentials:**

   Add the following credentials in Jenkins:

   - **EC2 SSH Key** (ID: `ec2-ssh-key`)
     - Kind: SSH Username with private key
     - Username: ubuntu (or ec2-user)
     - Private key: Your EC2 key pair

   - **EC2 Host** (ID: `ec2-host`)
     - Kind: Secret text
     - Secret: Your EC2 public IP or hostname

   - **EC2 User** (ID: `ec2-user`)
     - Kind: Secret text
     - Secret: ubuntu (or ec2-user)

   - **Database URL** (ID: `database-url`)
     - Kind: Secret text
     - Secret: jdbc:postgresql://your-db-host:5432/postgres

   - **Database Username** (ID: `database-username`)
     - Kind: Secret text
     - Secret: Your database username

   - **Database Password** (ID: `database-password`)
     - Kind: Secret text
     - Secret: Your database password

3. **Create Jenkins Pipeline Job:**
   - New Item > Pipeline
   - Pipeline Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your Git repository URL
   - Script Path: Jenkinsfile

## EC2 Instance Setup

### Prerequisites

1. EC2 instance running Amazon Linux 2 or Ubuntu
2. Security group allowing inbound traffic on port 8080
3. Java 17 installed on EC2

### EC2 Setup Steps

1. **Connect to EC2 instance:**
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

2. **Install Java 17:**

For Amazon Linux 2:
```bash
sudo yum install java-17-amazon-corretto -y
```

For Ubuntu:
```bash
sudo apt update
sudo apt install openjdk-17-jdk -y
```

3. **Verify Java installation:**
```bash
java -version
```

4. **Create deployment directory:**
```bash
sudo mkdir -p /opt/webapp
sudo chown $USER:$USER /opt/webapp
```

5. **Configure security group:**
   - Allow inbound traffic on port 8080 (application)
   - Allow inbound traffic on port 22 (SSH for Jenkins)

## Deployment

### Manual Deployment

1. Build the application:
```bash
mvn clean package
```

2. Copy JAR file to EC2:
```bash
scp target/webapp.jar ubuntu@your-ec2-ip:/opt/webapp/
```

3. Copy deployment scripts:
```bash
scp scripts/*.sh ubuntu@your-ec2-ip:/opt/webapp/
```

4. SSH to EC2 and start application:
```bash
ssh ubuntu@your-ec2-ip
cd /opt/webapp
chmod +x *.sh
./start.sh
```

### Automated Deployment with Jenkins

1. Push code to Git repository
2. Jenkins pipeline will automatically:
   - Checkout code
   - Build application
   - Run tests
   - Package JAR file
   - Deploy to EC2
   - Perform health check

### Deployment Scripts

The following scripts are available on the EC2 instance:

- `./start.sh` - Start the application
- `./stop.sh` - Stop the application
- `./restart.sh` - Restart the application
- `./status.sh` - Check application status

## Monitoring and Logs

### Application Logs

Logs are stored at `/opt/webapp/application.log` on the EC2 instance.

```bash
# View logs in real-time
tail -f /opt/webapp/application.log

# View last 100 lines
tail -n 100 /opt/webapp/application.log
```

### Health Check

Check application health:
```bash
curl http://your-ec2-ip:8080/api/health
```

### Application Status

Check if application is running:
```bash
cd /opt/webapp
./status.sh
```

## Environment Variables

Configure the following environment variables on EC2:

```bash
DATABASE_URL=jdbc:postgresql://your-db-host:5432/postgres
DATABASE_USERNAME=your_username
DATABASE_PASSWORD=your_password
SPRING_PROFILES_ACTIVE=prod
```

These are automatically set by the Jenkins pipeline.

## Database Setup

### Using Supabase

1. Create a Supabase project
2. Get the database connection details from Supabase dashboard
3. Update the credentials in Jenkins
4. The application will automatically create the required tables

### Manual PostgreSQL Setup

```sql
CREATE DATABASE webapp;

-- The application will auto-create tables using JPA
```

## Troubleshooting

### Application won't start

1. Check logs: `tail -f /opt/webapp/application.log`
2. Verify Java version: `java -version`
3. Check if port 8080 is available: `netstat -tuln | grep 8080`
4. Verify database connection settings

### Jenkins pipeline fails

1. Check Jenkins console output
2. Verify all credentials are configured correctly
3. Ensure EC2 instance is accessible via SSH
4. Check EC2 security group settings

### Database connection errors

1. Verify database credentials
2. Check if database server is running
3. Ensure EC2 instance can reach the database
4. Verify security group allows database port

## Production Considerations

1. **Security:**
   - Use HTTPS with SSL certificates
   - Configure proper security groups
   - Use AWS Secrets Manager for sensitive data
   - Enable Spring Security for authentication

2. **Performance:**
   - Configure connection pooling
   - Add caching layer (Redis)
   - Use load balancer for multiple instances

3. **Monitoring:**
   - Set up CloudWatch for logs and metrics
   - Configure application monitoring (New Relic, Datadog)
   - Set up alerts for critical errors

4. **Backup:**
   - Regular database backups
   - Version control for configuration
   - Disaster recovery plan

## License

This project is licensed under the MIT License.
<<<<<<< HEAD
=======
>>>>>>> 5cae7a2 (Adding projects files)
>>>>>>> 6099840 (removed some files)
