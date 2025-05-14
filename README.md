# webz.io-assignment

## Overview
This project sets up a high-availability cluster and Jenkins CI environment using Docker Compose. It includes:
- 3 Ubuntu 18.04 containers as cluster nodes (webz-001, webz-002, webz-003) with Pacemaker, Corosync, and Apache2
- 1 Jenkins container (webz-004) with SSH and persistent storage

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

> **Note:** For ease of testing, the `authkey` file is already included in this repository.

### 2. Build and Start the Environment
```sh
docker-compose up --build -d
```

### 3. Cluster Node Services & Automation
All required services (sshd, corosync, pacemaker, apache2) are installed automatically in the cluster node image via the Dockerfile. The entrypoint script (`corosync-node/entrypoint.sh`) starts all services and ensures the Apache homepage displays the required message.

### Floating IP Assignment
- **Action:** The floating IP (`172.28.1.100`) was assigned to the cluster using Pacemaker and IPaddr2. This was configured automatically on container startup by the `corosync-node/entrypoint.sh` script.
- **Configuration:**
  - The entrypoint script on `webz-001` runs the following Pacemaker commands to create the floating IP resource and set location constraints:
    ```sh
    crm configure property stonith-enabled=false
    crm configure primitive ClusterIP ocf:heartbeat:IPaddr2 \
      params ip=172.28.1.100 cidr_netmask=24 \
      op monitor interval=30s
    crm configure rsc_defaults resource-stickiness=100
    crm configure location prefer-webz-001 ClusterIP 100: webz-001
    crm configure location prefer-webz-002 ClusterIP 50: webz-002
    crm configure location prefer-webz-003 ClusterIP 0: webz-003
    ```
  - This ensures the floating IP always prefers `webz-001`, then `webz-002`, then `webz-003`.

### 4. SSH Access to Containers
- webz-num: `ssh devops@localhost -p (assigned port)`
- Password for all: `devops`

#### If you see a host key warning:
```sh
ssh-keygen -R '[localhost]:2204'  # or the relevant port
```

### 5. Test Apache Homepage
If you expose port 80 in your Compose file, you can test from your host:
```sh
curl http://localhost:PORT/
```
You should see:
```
Junior DevOps Engineer - Home Task
```

### 6. Access Jenkins
- URL: [http://localhost:8080](http://localhost:8080)
- **Username:** `admin`
- **Password:** `Aa123456`

### 7. Persistent Jenkins Data
Jenkins data is stored in `./jenkins` on your host. If you have permission issues, run:
```sh
sudo chown -R 1000:1000 ./jenkins
sudo chmod -R 755 ./jenkins
```

## Jenkins Pipeline Job

A Jenkins pipeline job runs every 5 minutes to monitor the cluster. It checks which node is currently active (holding the floating IP) and logs the response from the Apache homepage. The results are appended to a log file (`./logs/webz-004/active_node_ssh_log.txt`).

## Log Volumes and Monitoring Logs
- Jenkins container (`webz-004`) mounts the log volume:
  - Host: `./logs/webz-004`
  - Container: `/var/log/webz`


## Tests Performed

### Simulating Node Failure and Floating IP Failover
To verify that the floating IP transfers to the next active server in the cluster, we performed the following test:
- **Action:** Checked which server was currently holding the floating IP using the cluster status command:
  ```sh
  docker exec -it webz-001 crm status | cat
  ```
- **Action:** Stopped the server running the floating IP by executing:
  ```sh
  docker stop webz-001
  ```
- **Result:** The floating IP automatically transferred to the next preferred server in the cluster (webz-002).
- **Verification:** Confirmed the floating IP assignment by checking the cluster status on the next node using the commands:
  ```sh
  docker exec -it webz-002 crm status | cat
  docker exec -it webz-002 ip addr show
  ```

> **Note:** If only one node is online, the cluster loses quorum and all resources (including the floating IP) are stopped. Bringing another node back online restores resource availability.

### Automatic vs. Manual Failover
- **Investigation:** Explored whether the floating IP transition required manual intervention or was automatic.
- **Result:** The transition is fully automatic due to Pacemaker's configuration. No manual command is needed for failover.
- **Configuration:** This automation is set up in the `corosync-node/entrypoint.sh` script, which configures Pacemaker with resource stickiness and location constraints to ensure the floating IP always prefers webz-001, then webz-002, then webz-003. (See the [Floating IP Assignment](#floating-ip-assignment) section for details.)

### Manual Management of the Floating IP
If needed, you can manually move the floating IP to a specific node with:
```sh
crm resource move ClusterIP webz-002
```
To return to automatic failover, clear the manual constraint with:
```sh
crm resource clear ClusterIP
```

### Jenkins Job Monitoring
- **Action:** Verified that the Jenkins job runs every 5 minutes, sending a cURL request to the floating IP and logging the response, runtime, and active container name.
- **Verification:** Checked the log file at `./logs/webz-004/jenkins-job.log` to ensure new records are appended for each run, and that the container name matches the current active node both before and after simulating failover and confirmed that new log entries in the Jenkins log file reflect the new active node.

## Suggestions for Improvement

1. **Resource Grouping:**
   - Group the floating IP and Apache resources in Pacemaker to ensure they always move together during failover, improving service reliability.

2. **Monitoring and Alerts:**
   - Integrate monitoring tools and set up alerts for node/resource failures and failover events to enable monitoring using Prometheus and Grafana.
   - **Other tools:**
     - Use the `ocf:heartbeat:apache` agent's parameters to check if Apache is actually serving HTTP.

3. **Centralized Logging:**
   - Forward Jenkins and cluster logs to a centralized logging system (e.g., ELK Stack) for easier troubleshooting, auditing, and long-term analysis.

4. **Enable STONITH (Fencing):**
   - enable and configure STONITH to ensure that failed or partitioned nodes are safely powered off or isolated. This prevents split-brain scenarios and data corruption, making the cluster much more reliable.


