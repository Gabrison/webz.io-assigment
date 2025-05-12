# webz.io-assigment

## Overview
This project sets up a high-availability cluster and Jenkins CI environment using Docker Compose. It includes:
- 3 Ubuntu 18.04 containers as cluster nodes (webz-001, webz-002, webz-003) with Pacemaker, Corosync, and Apache2
- 1 Jenkins container (webz-004) with SSH and persistent storage

## Prerequisites
- Docker
- Docker Compose

## Setup Instructions

### 1. Build and Start the Environment
```sh
docker-compose up --build -d
```

### 2. Persistent Jenkins Data
Jenkins data is stored in `./jenkins` on your host. If you have permission issues, run:
```sh
sudo chown -R 1000:1000 ./jenkins
sudo chmod -R 755 ./jenkins
```

### 3. Access Jenkins
- URL: [http://localhost:8080](http://localhost:8080)
- To get the initial admin password:
  1. SSH into the Jenkins container:
     ```sh
     ssh devops@localhost -p 2204
     # password: devops
     ```
  2. Run:
     ```sh
     sudo cat /var/jenkins_home/secrets/initialAdminPassword
     ```

### 4. SSH Access to Containers
- webz-001: `ssh devops@localhost -p 2201`
- webz-002: `ssh devops@localhost -p 2202`
- webz-003: `ssh devops@localhost -p 2203`
- webz-004 (Jenkins): `ssh devops@localhost -p 2204`
- Password for all: `devops`

#### If you see a host key warning:
```sh
ssh-keygen -R '[localhost]:2204'  # or the relevant port
```
