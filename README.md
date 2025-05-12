# webz.io-assigment

## Overview
This project sets up a high-availability cluster and Jenkins CI environment using Docker Compose. It includes:
- 3 Ubuntu 18.04 containers as cluster nodes (webz-001, webz-002, webz-003) with Pacemaker, Corosync, and Apache2
- 1 Jenkins container (webz-004) with SSH and persistent storage

## Prerequisites
- Docker
- Docker Compose

## Setup Instructions

### 1. Generate the Corosync Authkey (Required for Cluster Nodes)
This key is used for secure communication between cluster nodes. Generate it once using Docker:
```sh
docker run --rm -v "$(pwd)/corosync-node":/corosync-node ubuntu:18.04 bash -c "\
  apt-get update && \
  apt-get install -y corosync && \
  corosync-keygen && \
  cp /etc/corosync/authkey /corosync-node/authkey"
```
This will create `corosync-node/authkey` in your project directory.

### 2. Build and Start the Environment
```sh
docker-compose up --build -d
```

### 3. Persistent Jenkins Data
Jenkins data is stored in `./jenkins` on your host. If you have permission issues, run:
```sh
sudo chown -R 1000:1000 ./jenkins
sudo chmod -R 755 ./jenkins
```

### 4. Cluster Node Services & Automation
All required services (sshd, corosync, pacemaker, apache2) are installed automatically in the cluster node image via the Dockerfile. The entrypoint script (`corosync-node/entrypoint.sh`) starts all services and ensures the Apache homepage displays the required message.

### 5. Access Jenkins
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

### 6. SSH Access to Containers
- webz-001: `ssh devops@localhost -p 2201`
- webz-002: `ssh devops@localhost -p 2202`
- webz-003: `ssh devops@localhost -p 2203`
- webz-004 (Jenkins): `ssh devops@localhost -p 2204`
- Password for all: `devops`

#### If you see a host key warning:
```sh
ssh-keygen -R '[localhost]:2204'  # or the relevant port
```

### 7. Checking Service Status in a Node
To check if services are running inside a cluster node, exec into the container:
```sh
docker exec -it webz-001 bash
```
Then run:
```sh
service ssh status
service corosync status
service pacemaker status
service apache2 status
```
Or check all at once:
```sh
ps aux | grep -E 'sshd|corosync|pacemakerd|apache2'
```

### 8. Test Apache Homepage
If you expose port 80 in your Compose file, you can test from your host:
```sh
curl http://localhost:PORT/
```
You should see:
```
Junior DevOps Engineer - Home Task
```

### 9. Cluster Resource Management, Failover Order, and Quorum
- The cluster is configured with explicit resource location constraints so the floating IP always prefers webz-001, then webz-002, then webz-003.
- To see which node is currently "active" (holding the floating IP), run:
  ```sh
  docker exec -it webz-001 crm status | cat
  ```
  or on any node. Look for the node listed after `Started` for the `ClusterIP` resource.
- To simulate failover, stop corosync on the active node:
  ```sh
  docker exec -it webz-001 service corosync stop
  ```
  The floating IP will move to the next preferred node. Repeat for webz-002 to see it move to webz-003.
- If only one node is online, the cluster will lose quorum and all resources will be stopped (this is a safety feature). Bring at least one more node back online to restore quorum and resource availability.
- To check the floating IP on the active node:
  ```sh
  docker exec -it webz-001 ip addr show
  ```
  Look for `172.28.1.100` assigned to eth0.