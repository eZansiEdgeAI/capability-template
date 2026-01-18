# AMD64 Deployment Guide

## Overview

This guide provides comprehensive deployment instructions specifically for AMD64 (x86-64) systems running eZansiEdgeAI capabilities. AMD64 platforms offer higher performance and more resources compared to ARM64, making them ideal for development, testing, and high-throughput production deployments.

**Platform Markers:**
- 💻 **AMD64** - x86-64 specific content
- 🌐 **General** - Applies to all platforms

## AMD64 Platform Overview

### Hardware Characteristics

**Advantages:**
- High single-thread and multi-thread performance
- Large memory capacity (16GB to 128GB+)
- Fast NVMe/SSD storage
- Multiple PCIe slots for expansion
- Better thermal headroom
- Higher network bandwidth

**Typical Use Cases:**
- Development workstations
- Build and CI/CD servers
- High-throughput production services
- Model training and fine-tuning
- Multi-capability orchestration
- Testing and validation

### Performance Expectations

| Workload Type | Expected Performance |
|---------------|---------------------|
| **Health Check Response** | 10-50ms |
| **LLM Inference (7B model)** | 300ms-1.5s |
| **LLM Inference (13B model)** | 1-3s |
| **STT (1min audio)** | 2-5s |
| **Vision Inference** | 100-500ms |
| **Concurrent Requests** | 10-20+ |
| **Container Startup** | 10-20s |

## Prerequisites

### Supported Operating Systems

#### Ubuntu/Debian (Recommended)

**Ubuntu 22.04 LTS or later:**
```bash
# Check version
lsb_release -a

# Expected: Ubuntu 22.04 LTS or 24.04 LTS
```

**Debian 11 or later:**
```bash
# Check version
cat /etc/debian_version

# Expected: 11 (bullseye) or 12 (bookworm)
```

#### Fedora

**Fedora 38 or later:**
```bash
# Check version
cat /etc/fedora-release

# Expected: Fedora release 38 or later
```

#### Red Hat Enterprise Linux (RHEL)

**RHEL 8 or 9:**
```bash
# Check version
cat /etc/redhat-release

# Expected: Red Hat Enterprise Linux release 8.x or 9.x
```

### Hardware Requirements

#### Minimum Requirements

- **CPU:** 4 cores (Intel Core i5/AMD Ryzen 5 or better)
- **RAM:** 16GB
- **Storage:** 50GB available (SSD recommended)
- **Network:** 100Mbps Ethernet

#### Recommended for Development

- **CPU:** 6-8 cores (Intel Core i7/AMD Ryzen 7)
- **RAM:** 24-32GB
- **Storage:** 100GB NVMe SSD
- **Network:** 1Gbps Ethernet

#### Recommended for Production

- **CPU:** 8-16 cores (Intel Xeon/AMD EPYC)
- **RAM:** 32-64GB (or more for large models)
- **Storage:** 250GB+ NVMe SSD (enterprise grade)
- **Network:** 10Gbps Ethernet
- **Redundancy:** RAID for storage, dual power supplies

### Software Prerequisites

#### Check Existing Installation

```bash
# Check if Podman is installed
podman --version

# Check if podman-compose is installed
podman-compose --version

# Check required utilities
curl --version
jq --version
```

## Installation Steps

### Ubuntu/Debian Installation

#### 1. Update System

```bash
# Update package lists
sudo apt update

# Upgrade existing packages
sudo apt upgrade -y

# Reboot if kernel was updated
sudo reboot  # if needed
```

#### 2. Install Podman

**Ubuntu 22.04+:**
```bash
# Install Podman from Ubuntu repositories
sudo apt install -y podman

# Verify installation
podman --version

# Expected: podman version 3.4.4 or later
```

**Ubuntu 20.04 (requires PPA):**
```bash
# Add Podman PPA
sudo add-apt-repository -y ppa:projectatomic/ppa
sudo apt update

# Install Podman
sudo apt install -y podman

# Verify
podman --version
```

**Debian:**
```bash
# Install from Debian repositories
sudo apt install -y podman

# Verify
podman --version
```

#### 3. Install podman-compose

```bash
# Install pip if not present
sudo apt install -y python3-pip

# Install podman-compose
pip3 install podman-compose

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
podman-compose --version
```

#### 4. Install Utilities

```bash
# Install required tools
sudo apt install -y curl jq git

# Optional but recommended
sudo apt install -y htop iotop nethogs

# Verify installations
curl --version
jq --version
git --version
```

#### 5. Configure Podman (Optional but Recommended)

```bash
# Enable lingering for rootless Podman
loginctl enable-linger $USER

# Configure storage
sudo mkdir -p /etc/containers
sudo tee /etc/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
additionalimagestores = []

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF

# Set up registry configuration
sudo tee /etc/containers/registries.conf <<EOF
[registries.search]
registries = ['docker.io', 'quay.io', 'ghcr.io']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF
```

### Fedora Installation

#### 1. Update System

```bash
# Update all packages
sudo dnf update -y

# Reboot if needed
sudo reboot  # if kernel updated
```

#### 2. Install Podman

```bash
# Podman is included in Fedora repositories
sudo dnf install -y podman

# Verify installation
podman --version

# Expected: podman version 4.0 or later
```

#### 3. Install podman-compose

```bash
# Install pip
sudo dnf install -y python3-pip

# Install podman-compose
pip3 install podman-compose

# Verify
podman-compose --version
```

#### 4. Install Utilities

```bash
# Install utilities
sudo dnf install -y curl jq git htop iotop

# Verify
curl --version
jq --version
```

#### 5. Configure Firewall

```bash
# Allow capability port (adjust as needed)
sudo firewall-cmd --permanent --add-port={{PORT}}/tcp
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

### RHEL Installation

#### 1. Enable Required Repositories

```bash
# Enable RHEL repositories
sudo subscription-manager repos --enable rhel-8-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable rhel-8-for-x86_64-appstream-rpms

# For RHEL 9
sudo subscription-manager repos --enable rhel-9-for-x86_64-baseos-rpms
sudo subscription-manager repos --enable rhel-9-for-x86_64-appstream-rpms

# Update system
sudo dnf update -y
```

#### 2. Install Podman

```bash
# Install Podman (included in RHEL)
sudo dnf install -y podman

# Verify
podman --version
```

#### 3. Install Additional Tools

```bash
# Install container tools module
sudo dnf module install -y container-tools

# Install utilities
sudo dnf install -y curl jq git

# Install podman-compose
sudo dnf install -y python3-pip
pip3 install podman-compose
```

#### 4. Configure SELinux (Important for RHEL)

```bash
# Check SELinux status
getenforce
# Expected: Enforcing

# Install SELinux tools
sudo dnf install -y policycoreutils-python-utils

# Allow container ports
sudo semanage port -a -t http_port_t -p tcp {{PORT}}

# Set proper contexts for volumes
sudo semanage fcontext -a -t container_file_t "/opt/{{CAPABILITY_NAME}}/data(/.*)?"
sudo restorecon -Rv /opt/{{CAPABILITY_NAME}}/data
```

## AMD64-Specific Configurations

### System Configuration Files

#### 1. Podman Configuration

Create `/etc/containers/containers.conf`:

```bash
sudo mkdir -p /etc/containers
sudo tee /etc/containers/containers.conf <<EOF
[containers]
# Maximum number of processes per container
pids_limit = 2048

# Default ulimits
default_ulimits = [
  "nofile=65535:65535",
]

# Network configuration
dns_servers = ["8.8.8.8", "8.8.4.4"]

# Resource management
default_sysctls = [
  "net.ipv4.ping_group_range=0 2147483647",
]

[engine]
# Number of pulls to perform in parallel
num_locks = 2048

# Container runtime
runtime = "crun"

# Event logging
events_logger = "journald"
EOF
```

#### 2. Resource Limits Configuration

Create `/etc/security/limits.d/podman.conf`:

```bash
sudo tee /etc/security/limits.d/podman.conf <<EOF
# Podman resource limits for AMD64

# Maximum number of open files
*    soft    nofile    65535
*    hard    nofile    65535

# Maximum number of processes
*    soft    nproc     4096
*    hard    nproc     4096

# Maximum locked memory (for performance)
*    soft    memlock   unlimited
*    hard    memlock   unlimited
EOF
```

### Network Configuration

#### 1. Optimize Network Stack

**For high-throughput deployments:**

```bash
sudo tee /etc/sysctl.d/99-podman-network.conf <<EOF
# Network optimizations for AMD64 containers

# Increase network buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432
net.core.optmem_max = 33554432

# TCP buffer sizes
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Increase max connections
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Disable TCP timestamps for better performance
net.ipv4.tcp_timestamps = 0

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3

# Increase local port range
net.ipv4.ip_local_port_range = 10000 65535

# Enable TCP reuse
net.ipv4.tcp_tw_reuse = 1
EOF

# Apply settings
sudo sysctl -p /etc/sysctl.d/99-podman-network.conf
```

#### 2. Configure Container Network

**Create custom network for capabilities:**

```bash
# Create dedicated network
podman network create \
  --driver bridge \
  --subnet 10.89.0.0/24 \
  --gateway 10.89.0.1 \
  ezansi-capabilities

# Verify
podman network ls
podman network inspect ezansi-capabilities
```

**Update podman-compose.yml to use custom network:**

```yaml
version: '3.8'

services:
  {{CAPABILITY_NAME}}:
    image: {{CONTAINER_IMAGE}}
    networks:
      - ezansi-capabilities

networks:
  ezansi-capabilities:
    external: true
```

### Storage Configuration

#### 1. NVMe/SSD Optimization

**Check current storage:**

```bash
# List storage devices
lsblk

# Check NVMe devices
ls /dev/nvme*

# Check disk performance
sudo hdparm -tT /dev/nvme0n1
```

**Optimize filesystem for containers:**

```bash
# For ext4 (most common)
sudo tune2fs -O fast_commit /dev/nvme0n1p1

# Enable TRIM
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Verify TRIM
sudo fstrim -v /
```

#### 2. Configure Container Storage

**Set up dedicated storage location:**

```bash
# Create storage directory on NVMe
sudo mkdir -p /mnt/nvme/containers

# Update Podman storage configuration
sudo tee /etc/containers/storage.conf <<EOF
[storage]
driver = "overlay"
graphroot = "/mnt/nvme/containers/storage"

[storage.options.overlay]
# Enable metacopy for better performance
mountopt = "nodev,metacopy=on"
mount_program = "/usr/bin/fuse-overlayfs"
EOF

# Restart Podman
podman system reset --force  # WARNING: Removes all containers/images
```

#### 3. Configure Volume Storage

**Create volume directory with optimal settings:**

```bash
# Create volume directory
sudo mkdir -p /opt/{{CAPABILITY_NAME}}/data

# Set permissions
sudo chown -R $USER:$USER /opt/{{CAPABILITY_NAME}}

# Set optimal permissions
chmod 755 /opt/{{CAPABILITY_NAME}}
chmod 755 /opt/{{CAPABILITY_NAME}}/data
```

**Use bind mount in podman-compose.yml:**

```yaml
volumes:
  - /opt/{{CAPABILITY_NAME}}/data:/data:z
```

## AMD64-Specific Optimizations

### CPU Optimization

#### 1. Set CPU Governor to Performance

```bash
# Check current governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set to performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make persistent
sudo tee /etc/systemd/system/cpu-performance.service <<EOF
[Unit]
Description=Set CPU governor to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cpu-performance.service
sudo systemctl start cpu-performance.service
```

#### 2. Disable CPU Power Saving

**Intel processors:**
```bash
# Edit GRUB configuration
sudo vim /etc/default/grub

# Add to GRUB_CMDLINE_LINUX:
# intel_pstate=disable intel_idle.max_cstate=0 processor.max_cstate=0

# Example:
GRUB_CMDLINE_LINUX="intel_pstate=disable intel_idle.max_cstate=0 processor.max_cstate=0"

# Update GRUB
sudo update-grub  # Ubuntu/Debian
sudo grub2-mkconfig -o /boot/grub2/grub.cfg  # Fedora/RHEL

# Reboot
sudo reboot
```

**AMD processors:**
```bash
# Edit GRUB configuration
sudo vim /etc/default/grub

# Add to GRUB_CMDLINE_LINUX:
GRUB_CMDLINE_LINUX="amd_pstate=disable"

# Update and reboot
sudo update-grub
sudo reboot
```

#### 3. CPU Pinning (Advanced)

**For maximum performance, pin container to specific CPUs:**

```yaml
# In podman-compose.yml
services:
  {{CAPABILITY_NAME}}:
    cpuset: "0-7"  # Use CPUs 0-7
    deploy:
      resources:
        limits:
          cpus: '8'
```

### Memory Optimization

#### 1. Configure Huge Pages

```bash
# Check current huge pages
cat /proc/meminfo | grep Huge

# Enable transparent huge pages
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Make persistent
sudo tee /etc/sysctl.d/99-hugepages.conf <<EOF
# Transparent Huge Pages
vm.nr_hugepages = 2048
EOF

sudo sysctl -p /etc/sysctl.d/99-hugepages.conf
```

#### 2. Optimize Memory Allocation

```bash
# Memory settings for high-performance workloads
sudo tee /etc/sysctl.d/99-memory.conf <<EOF
# Reduce swappiness (prefer RAM)
vm.swappiness = 10

# Increase dirty ratio for better write performance
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Increase max map count for container workloads
vm.max_map_count = 262144
EOF

sudo sysctl -p /etc/sysctl.d/99-memory.conf
```

#### 3. NUMA Optimization (Multi-Socket Systems)

```bash
# Check NUMA configuration
numactl --hardware

# For multi-socket systems, bind container to single NUMA node
# In podman-compose.yml:
```

```yaml
services:
  {{CAPABILITY_NAME}}:
    cpuset: "0-7"
    cpuset_mems: "0"  # Use memory from NUMA node 0
```

### I/O Optimization

#### 1. I/O Scheduler Configuration

```bash
# Check current scheduler
cat /sys/block/nvme0n1/queue/scheduler

# Set to none for NVMe (best performance)
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# Make persistent
sudo tee /etc/udev/rules.d/60-ioschedulers.rules <<EOF
# Set none scheduler for NVMe devices
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF
```

#### 2. Increase Queue Depth

```bash
# Check current queue depth
cat /sys/block/nvme0n1/queue/nr_requests

# Increase for better throughput
echo 1024 | sudo tee /sys/block/nvme0n1/queue/nr_requests

# Make persistent
sudo tee /etc/udev/rules.d/60-nvme-queue.rules <<EOF
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1024"
EOF
```

### Container Runtime Optimization

#### 1. Use crun Instead of runc

```bash
# Install crun (faster, lower overhead)
sudo apt install -y crun  # Ubuntu/Debian
sudo dnf install -y crun  # Fedora/RHEL

# Configure Podman to use crun
sudo tee -a /etc/containers/containers.conf <<EOF
[engine]
runtime = "crun"
EOF

# Verify
podman info | grep -i runtime
```

#### 2. Optimize Container Startup

```bash
# Disable unnecessary features for performance
# In podman-compose.yml:
```

```yaml
services:
  {{CAPABILITY_NAME}}:
    security_opt:
      - label=disable  # Disable SELinux labeling if not needed
    tmpfs:
      - /tmp:size=2G,mode=1777  # Fast tmpfs for temporary files
```

## Deployment Configurations

### Development Configuration (24GB RAM)

```yaml
version: '3.8'

services:
  {{CAPABILITY_NAME}}:
    image: {{CONTAINER_IMAGE}}
    container_name: {{CAPABILITY_NAME}}-capability
    ports:
      - "{{PORT}}:{{PORT}}"
    volumes:
      - {{CAPABILITY_NAME}}-data:/data
      - ./logs:/logs
    deploy:
      resources:
        limits:
          memory: 18g
          cpus: '6'
        reservations:
          memory: 12g
          cpus: '4'
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{PORT}}{{HEALTH_PATH}}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    environment:
      - LOG_LEVEL=debug
      - MAX_WORKERS=4
      - NUMA_NODE=0
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  {{CAPABILITY_NAME}}-data:
    driver: local
```

### Production Configuration (32GB+ RAM)

```yaml
version: '3.8'

services:
  {{CAPABILITY_NAME}}:
    image: {{CONTAINER_IMAGE}}
    container_name: {{CAPABILITY_NAME}}-capability
    ports:
      - "{{PORT}}:{{PORT}}"
    volumes:
      - {{CAPABILITY_NAME}}-data:/data:z
      - /opt/{{CAPABILITY_NAME}}/models:/models:ro,z
    deploy:
      resources:
        limits:
          memory: 28g
          cpus: '12'
        reservations:
          memory: 20g
          cpus: '8'
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{PORT}}{{HEALTH_PATH}}"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    environment:
      - LOG_LEVEL=info
      - MAX_WORKERS=8
      - WORKER_TIMEOUT=300
      - ENABLE_METRICS=true
      - NUMA_NODE=0
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    logging:
      driver: journald
      options:
        tag: "{{CAPABILITY_NAME}}"
    ulimits:
      nofile:
        soft: 65535
        hard: 65535
      nproc:
        soft: 4096
        hard: 4096

volumes:
  {{CAPABILITY_NAME}}-data:
    driver: local
    driver_opts:
      type: none
      device: /opt/{{CAPABILITY_NAME}}/data
      o: bind
```

### High-Performance Configuration (64GB+ RAM)

```yaml
version: '3.8'

services:
  {{CAPABILITY_NAME}}:
    image: {{CONTAINER_IMAGE}}
    container_name: {{CAPABILITY_NAME}}-capability
    network_mode: host  # Better performance, less isolation
    volumes:
      - /opt/{{CAPABILITY_NAME}}/data:/data:z
      - /mnt/nvme/models:/models:ro,z
      - /dev/shm:/dev/shm  # Shared memory for IPC
    deploy:
      resources:
        limits:
          memory: 56g
          cpus: '20'
        reservations:
          memory: 48g
          cpus: '16'
    cpuset: "0-19"  # Pin to specific CPUs
    cpuset_mems: "0"  # Pin to NUMA node 0
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{PORT}}{{HEALTH_PATH}}"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 90s
    environment:
      - LOG_LEVEL=warning
      - MAX_WORKERS=16
      - WORKER_TIMEOUT=600
      - ENABLE_METRICS=true
      - PROMETHEUS_PORT=9090
      - NUMA_NODE=0
      - OMP_NUM_THREADS=20
      - MALLOC_CONF=background_thread:true
    security_opt:
      - no-new-privileges:true
      - label=disable
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
      - IPC_LOCK
    tmpfs:
      - /tmp:size=4G,mode=1777,noexec,nosuid
    shm_size: 8g
    logging:
      driver: journald
      options:
        tag: "{{CAPABILITY_NAME}}"
        labels: "production,high-perf"
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
      nproc:
        soft: 8192
        hard: 8192
      memlock:
        soft: -1
        hard: -1

volumes:
  {{CAPABILITY_NAME}}-data:
```

## Deployment Process

### 1. Pre-Deployment Checklist

```bash
# System requirements
echo "=== System Check ==="
echo "CPU cores: $(nproc)"
echo "Total RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Available disk: $(df -h / | awk 'NR==2 {print $4}')"
echo "Architecture: $(uname -m)"
echo ""

# Software versions
echo "=== Software Versions ==="
echo "Podman: $(podman --version)"
echo "podman-compose: $(podman-compose --version)"
echo "Kernel: $(uname -r)"
echo ""

# Performance settings
echo "=== Performance Settings ==="
echo "CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "Transparent huge pages: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
```

### 2. Deploy Capability

```bash
# Create deployment directory
sudo mkdir -p /opt/{{CAPABILITY_NAME}}
cd /opt/{{CAPABILITY_NAME}}

# Clone or download configuration
git clone https://github.com/your-org/{{CAPABILITY_NAME}}.git .

# Select appropriate configuration
cp config/amd64-32gb.yml podman-compose.yml

# Customize if needed
vim podman-compose.yml

# Pull image
podman pull {{CONTAINER_IMAGE}}

# Deploy
podman-compose up -d

# Wait for startup
sleep 30

# Verify
podman ps | grep {{CAPABILITY_NAME}}
curl http://localhost:{{PORT}}{{HEALTH_PATH}}
```

### 3. Post-Deployment Validation

```bash
# Run validation script
./scripts/validate-deployment.sh

# Check resource usage
podman stats --no-stream {{CAPABILITY_NAME}}-capability

# Check logs
podman logs --tail 50 {{CAPABILITY_NAME}}-capability

# Run performance tests
./tests/test-performance.sh

# Monitor for 5 minutes
podman stats {{CAPABILITY_NAME}}-capability
```

## Monitoring and Maintenance

### System Monitoring

#### 1. Set Up Prometheus Metrics (Optional)

```bash
# Install Prometheus
sudo apt install -y prometheus  # Ubuntu
sudo dnf install -y prometheus  # Fedora

# Configure Prometheus to scrape capability metrics
sudo tee -a /etc/prometheus/prometheus.yml <<EOF
scrape_configs:
  - job_name: '{{CAPABILITY_NAME}}'
    static_configs:
      - targets: ['localhost:{{PORT}}']
EOF

sudo systemctl restart prometheus
```

#### 2. Set Up Grafana Dashboards (Optional)

```bash
# Install Grafana
sudo apt install -y grafana  # Ubuntu
sudo dnf install -y grafana  # Fedora

sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Access Grafana at http://localhost:3000
# Default credentials: admin/admin
```

#### 3. Real-Time Monitoring

```bash
# Monitor container stats
watch -n 2 'podman stats --no-stream {{CAPABILITY_NAME}}-capability'

# Monitor system resources
htop

# Monitor I/O
iotop

# Monitor network
nethogs

# Monitor logs
journalctl -u podman-compose@{{CAPABILITY_NAME}} -f
```

### Log Management

#### 1. Configure Log Rotation

```bash
# Using journald (recommended for RHEL/Fedora)
sudo tee /etc/systemd/journald.conf.d/{{CAPABILITY_NAME}}.conf <<EOF
[Journal]
SystemMaxUse=500M
SystemKeepFree=1G
MaxRetentionSec=7day
EOF

sudo systemctl restart systemd-journald
```

#### 2. Export Logs to File

```bash
# Export last 24 hours
journalctl -u podman-compose@{{CAPABILITY_NAME}} \
  --since "24 hours ago" > /var/log/{{CAPABILITY_NAME}}.log

# Set up automatic export
cat > /usr/local/bin/export-capability-logs.sh <<'EOF'
#!/bin/bash
journalctl -u podman-compose@{{CAPABILITY_NAME}} \
  --since "24 hours ago" \
  > /var/log/{{CAPABILITY_NAME}}-$(date +%Y%m%d).log
find /var/log/{{CAPABILITY_NAME}}-*.log -mtime +7 -delete
EOF

chmod +x /usr/local/bin/export-capability-logs.sh

# Add to crontab
echo "0 0 * * * /usr/local/bin/export-capability-logs.sh" | crontab -
```

### Backup and Recovery

#### 1. Backup Data Volumes

```bash
# Backup script
cat > /usr/local/bin/backup-{{CAPABILITY_NAME}}.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/{{CAPABILITY_NAME}}"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup volume
podman volume export {{CAPABILITY_NAME}}-data \
  > $BACKUP_DIR/data-${DATE}.tar

# Backup configuration
tar -czf $BACKUP_DIR/config-${DATE}.tar.gz \
  /opt/{{CAPABILITY_NAME}}/capability.json \
  /opt/{{CAPABILITY_NAME}}/podman-compose.yml

# Remove old backups (keep 30 days)
find $BACKUP_DIR -name "*.tar*" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/backup-{{CAPABILITY_NAME}}.sh

# Schedule daily backups
echo "0 2 * * * /usr/local/bin/backup-{{CAPABILITY_NAME}}.sh" | crontab -
```

#### 2. Restore from Backup

```bash
# Stop container
podman-compose down

# Restore volume
podman volume rm {{CAPABILITY_NAME}}-data
podman volume create {{CAPABILITY_NAME}}-data
podman volume import {{CAPABILITY_NAME}}-data \
  < /opt/backups/{{CAPABILITY_NAME}}/data-YYYYMMDD-HHMMSS.tar

# Restore configuration
tar -xzf /opt/backups/{{CAPABILITY_NAME}}/config-YYYYMMDD-HHMMSS.tar.gz -C /

# Restart
podman-compose up -d
```

## Firewall Configuration

### Ubuntu/Debian (UFW)

```bash
# Enable UFW
sudo ufw enable

# Allow capability port
sudo ufw allow {{PORT}}/tcp

# Allow SSH (important!)
sudo ufw allow 22/tcp

# Check status
sudo ufw status verbose
```

### Fedora/RHEL (firewalld)

```bash
# Start firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

# Allow capability port
sudo firewall-cmd --permanent --add-port={{PORT}}/tcp

# Reload
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

### Advanced Firewall Rules

```bash
# Allow only from specific network
sudo firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="{{PORT}}" protocol="tcp" accept'

# Rate limiting
sudo firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" port port="{{PORT}}" protocol="tcp" limit value="100/s" accept'

# Reload
sudo firewall-cmd --reload
```

## SELinux Configuration (RHEL/Fedora/CentOS)

### Basic SELinux Setup

```bash
# Check SELinux status
getenforce

# Install SELinux tools
sudo dnf install -y policycoreutils-python-utils

# Allow container ports
sudo semanage port -a -t http_port_t -p tcp {{PORT}}

# Check port context
sudo semanage port -l | grep {{PORT}}
```

### Configure SELinux for Volumes

```bash
# Set context for data directory
sudo semanage fcontext -a -t container_file_t \
  "/opt/{{CAPABILITY_NAME}}/data(/.*)?"

# Apply context
sudo restorecon -Rv /opt/{{CAPABILITY_NAME}}/data

# Verify
ls -lZ /opt/{{CAPABILITY_NAME}}/data
```

### SELinux Troubleshooting

```bash
# Check for SELinux denials
sudo ausearch -m avc -ts recent

# Generate policy module if needed
sudo ausearch -m avc -ts recent | audit2allow -M my-{{CAPABILITY_NAME}}

# Install policy module
sudo semodule -i my-{{CAPABILITY_NAME}}.pp
```

## Performance Tuning

### Benchmark and Baseline

```bash
# Run initial benchmark
./tests/test-performance.sh > baseline-performance.txt

# Monitor during load
./tests/test-performance.sh &
PID=$!
watch -n 1 'podman stats --no-stream {{CAPABILITY_NAME}}-capability'
wait $PID
```

### Tune Based on Workload

**CPU-bound workloads:**
```yaml
deploy:
  resources:
    limits:
      cpus: '16'  # Increase CPU allocation
      memory: 20g
```

**Memory-bound workloads:**
```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 48g  # Increase memory allocation
shm_size: 8g  # Increase shared memory
```

**I/O-bound workloads:**
```yaml
volumes:
  - /mnt/nvme/data:/data  # Use fastest storage
tmpfs:
  - /tmp:size=8G  # Large tmpfs for temporary files
```

## Common AMD64 Deployment Scenarios

### Scenario 1: Development Workstation

**Hardware:** 24GB RAM, 8 cores, NVMe SSD

```bash
# Use development configuration
cp config/amd64-24gb.yml podman-compose.yml

# Enable development features
# - Debug logging
# - Volume mounts for live code reload
# - Exposed metrics

podman-compose up -d
```

### Scenario 2: Production Server

**Hardware:** 64GB RAM, 16 cores, NVMe RAID

```bash
# Use high-performance configuration
cp config/amd64-64gb.yml podman-compose.yml

# Production optimizations
# - Performance CPU governor
# - NUMA pinning
# - Large huge pages
# - Firewall configured
# - SELinux enforcing
# - Automated backups

./scripts/deploy.sh
```

### Scenario 3: CI/CD Build Server

**Hardware:** 32GB RAM, 12 cores, SSD

```bash
# Optimized for parallel builds
# - Multiple capability instances
# - Shared cache volumes
# - Registry caching

podman-compose --scale {{CAPABILITY_NAME}}=3 up -d
```

## Troubleshooting

### High CPU Usage

```bash
# Check CPU usage
podman stats {{CAPABILITY_NAME}}-capability

# Profile CPU usage
sudo perf top -p $(podman inspect {{CAPABILITY_NAME}}-capability --format '{{.State.Pid}}')

# Increase CPU limit if needed
# Edit podman-compose.yml, increase cpus value
podman-compose up -d
```

### Memory Issues

```bash
# Check memory usage
podman stats {{CAPABILITY_NAME}}-capability

# Check for memory leaks
podman exec {{CAPABILITY_NAME}}-capability ps aux

# Increase memory limit
# Edit podman-compose.yml, increase memory value
podman-compose up -d
```

### Storage Performance

```bash
# Check I/O performance
iotop -o

# Test disk speed
sudo hdparm -tT /dev/nvme0n1

# Check container I/O
podman stats {{CAPABILITY_NAME}}-capability | grep -i block
```

### Network Issues

```bash
# Test network connectivity
curl -v http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check firewall
sudo firewall-cmd --list-all

# Check SELinux
sudo ausearch -m avc -ts recent | grep {{PORT}}

# Test network performance
iperf3 -s  # On server
iperf3 -c server-ip  # On client
```

## Summary

AMD64 deployment offers:
- ✅ High performance and throughput
- ✅ Large memory capacity
- ✅ Fast NVMe storage
- ✅ Extensive tuning options
- ✅ Production-ready platform

Key considerations:
- Choose appropriate resource configuration (24GB, 32GB, 64GB+)
- Optimize CPU governor and power settings
- Configure NVMe/SSD for best performance
- Set up monitoring and logging
- Configure firewall and SELinux properly
- Implement regular backups

---

**See Also:**
- [Deployment Guide](deployment-guide.md) - General deployment strategies
- [Performance Tuning](performance-tuning.md) - Detailed optimization guide
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [Architecture Overview](architecture.md) - eZansiEdgeAI architecture
