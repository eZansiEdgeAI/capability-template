# Troubleshooting Guide

## Overview

This guide provides platform-specific troubleshooting for common issues with eZansiEdgeAI capabilities.

**Platform Markers:**
- 🍓 **ARM64** - Raspberry Pi specific
- 💻 **AMD64** - x86-64 specific  
- 🌐 **Both** - Applies to both platforms

## Quick Diagnostic Commands

### 🌐 Container Status

```bash
# Check if container is running
podman ps

# Check all containers (including stopped)
podman ps -a

# View container logs
podman logs {{CAPABILITY_NAME}}-capability

# Follow logs in real-time
podman logs -f {{CAPABILITY_NAME}}-capability

# Check last 50 lines
podman logs --tail 50 {{CAPABILITY_NAME}}-capability
```

### 🌐 Resource Usage

```bash
# Current resource usage
podman stats --no-stream {{CAPABILITY_NAME}}-capability

# Live monitoring
podman stats {{CAPABILITY_NAME}}-capability

# Container details
podman inspect {{CAPABILITY_NAME}}-capability
```

### 🌐 Network Connectivity

```bash
# Check exposed ports
podman port {{CAPABILITY_NAME}}-capability

# Test health endpoint
curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check network configuration
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].NetworkSettings'
```

### 🌐 System Resources

```bash
# Memory usage
free -h

# CPU usage
top -bn1 | head -n 20

# Disk space
df -h

# I/O stats
iostat -x 1
```

## Common Issues

### Issue: Container Won't Start

**Symptoms:**
- Container exits immediately after starting
- `podman ps` doesn't show the container
- `podman ps -a` shows status "Exited"

**🌐 Diagnosis:**

```bash
# Check container status and exit code
podman ps -a | grep {{CAPABILITY_NAME}}

# View container logs
podman logs {{CAPABILITY_NAME}}-capability

# Inspect container for detailed error
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].State'
```

**🌐 Common Causes:**

1. **Port already in use**
   ```bash
   # Check if port is occupied
   sudo lsof -i :{{PORT}}
   
   # Or using ss
   ss -tulpn | grep {{PORT}}
   ```
   
   **Solution:** Stop the conflicting service or change the port

2. **Insufficient permissions**
   ```bash
   # Check Podman socket permissions
   ls -l /run/podman/podman.sock
   ```
   
   **Solution:** Add user to podman group or run as root

3. **Missing image**
   ```bash
   # Check if image exists
   podman images | grep {{CONTAINER_IMAGE}}
   ```
   
   **Solution:** Pull the image manually
   ```bash
   podman pull {{CONTAINER_IMAGE}}
   ```

4. **Resource limits too low**
   
   **Solution:** Increase memory/CPU limits in compose file

**🍓 ARM64 Specific:**
- Wrong architecture image (amd64 instead of arm64)
  ```bash
  # Check image architecture
  podman inspect {{CONTAINER_IMAGE}} | jq '.[].Architecture'
  ```

**💻 AMD64 Specific:**
- SELinux blocking container
  ```bash
  # Check SELinux status
  getenforce
  
  # Temporarily disable for testing
  sudo setenforce 0
  ```

### Issue: Health Check Fails

**Symptoms:**
- Container running but health check returns errors
- `curl` to health endpoint fails
- Container marked as "unhealthy"

**🌐 Diagnosis:**

```bash
# Test health endpoint manually
curl -v http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check container health status
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].State.Health'

# View health check logs
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].State.Health.Log'
```

**🌐 Common Causes:**

1. **Service not ready yet**
   
   **Solution:** Wait longer (some services take time to initialize)
   ```bash
   # Watch health status
   watch -n 2 'curl -s http://localhost:{{PORT}}{{HEALTH_PATH}}'
   ```

2. **Wrong endpoint path**
   
   **Diagnosis:**
   ```bash
   # Check configured path
   jq '.endpoints.health.path' capability.json
   ```
   
   **Solution:** Update capability.json or compose file

3. **Port not exposed**
   
   **Diagnosis:**
   ```bash
   # Check port mapping
   podman port {{CAPABILITY_NAME}}-capability
   ```
   
   **Solution:** Verify port mapping in compose file

4. **Firewall blocking**
   
   **Diagnosis:**
   ```bash
   # Check firewall rules
   sudo iptables -L -n
   ```
   
   **Solution:** Add firewall rule
   ```bash
   sudo ufw allow {{PORT}}
   ```

**🍓 ARM64 Specific:**
- Service crashed due to OOM (out of memory)
  ```bash
  # Check dmesg for OOM messages
  dmesg | grep -i oom
  ```
  
  **Solution:** Reduce memory usage or increase limits

### Issue: Poor Performance

**Symptoms:**
- Slow response times
- High latency
- Low throughput

**🌐 Diagnosis:**

```bash
# Check resource usage
podman stats --no-stream {{CAPABILITY_NAME}}-capability

# Run performance tests
./tests/test-performance.sh

# Check CPU usage
top -bn1 | grep {{CAPABILITY_NAME}}
```

**🌐 Common Causes:**

1. **Resource limits too restrictive**
   
   **Diagnosis:**
   ```bash
   # Check if hitting limits
   podman stats {{CAPABILITY_NAME}}-capability
   # Look for CPU% near limit or memory at max
   ```
   
   **Solution:** Increase limits in compose file

2. **High concurrent load**
   
   **Solution:** Reduce concurrent requests or scale horizontally

3. **Disk I/O bottleneck**
   
   **Diagnosis:**
   ```bash
   # Monitor I/O
   iostat -x 1
   ```

**🍓 ARM64 Specific Issues:**

1. **Thermal throttling**
   ```bash
   # Check temperature
   vcgencmd measure_temp
   
   # Check throttling status
   vcgencmd get_throttled
   # 0x0 = no throttling
   # 0x50000 = throttling occurred
   ```
   
   **Solution:**
   - Add active cooling (fan)
   - Reduce CPU usage
   - Improve ventilation

2. **SD card I/O bottleneck**
   ```bash
   # Test SD card speed
   sudo hdparm -t /dev/mmcblk0
   ```
   
   **Solution:**
   - Use USB SSD for data volumes
   - Use high-quality SD card (UHS-I, A2 rating)
   - Reduce write operations

3. **Memory swapping**
   ```bash
   # Check swap usage
   free -h
   vmstat 1
   ```
   
   **Solution:**
   - Reduce memory limit
   - Disable swap: `sudo swapoff -a`
   - Use smaller models

**💻 AMD64 Specific Issues:**

1. **CPU governor in power-save mode**
   ```bash
   # Check governor
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```
   
   **Solution:**
   ```bash
   # Set to performance
   echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

2. **NUMA issues (multi-socket systems)**
   ```bash
   # Check NUMA configuration
   numactl --hardware
   ```
   
   **Solution:** Pin container to specific NUMA node

### Issue: Container Crashes or Restarts

**Symptoms:**
- Container repeatedly restarting
- Unexpected crashes
- Exit code not 0

**🌐 Diagnosis:**

```bash
# Check restart count
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].RestartCount'

# View exit code
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].State.ExitCode'

# Check logs for errors
podman logs {{CAPABILITY_NAME}}-capability | tail -n 100
```

**🌐 Common Causes:**

1. **Out of Memory (OOM)**
   
   **Diagnosis:**
   ```bash
   # Check for OOM in logs
   podman logs {{CAPABILITY_NAME}}-capability | grep -i "out of memory"
   
   # System logs
   dmesg | grep -i oom
   ```
   
   **Solution:** Increase memory limit or reduce usage

2. **Segmentation fault**
   
   **Diagnosis:**
   ```bash
   # Check logs for segfault
   podman logs {{CAPABILITY_NAME}}-capability | grep -i "segmentation fault"
   ```
   
   **Solution:** Report bug to capability maintainer

3. **Dependency missing**
   
   **Diagnosis:** Check logs for library errors
   
   **Solution:** Rebuild container with dependencies

4. **Configuration error**
   
   **Solution:** Validate configuration files

**🍓 ARM64 Specific:**
- Wrong architecture binary
  ```bash
  # Check if trying to run amd64 binary
  podman logs {{CAPABILITY_NAME}}-capability | grep -i "exec format error"
  ```

### Issue: Network Connectivity Problems

**Symptoms:**
- Can't connect to container from host
- Container can't connect to external services
- DNS resolution fails

**🌐 Diagnosis:**

```bash
# Test connectivity from host
curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check port binding
podman port {{CAPABILITY_NAME}}-capability

# Test from within container
podman exec {{CAPABILITY_NAME}}-capability curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check DNS
podman exec {{CAPABILITY_NAME}}-capability nslookup google.com
```

**🌐 Common Causes:**

1. **Port not exposed**
   
   **Solution:** Add port mapping in compose file
   ```yaml
   ports:
     - "{{PORT}}:{{PORT}}"
   ```

2. **Firewall blocking**
   
   **Solution:**
   ```bash
   # Allow port
   sudo ufw allow {{PORT}}
   
   # Or disable firewall for testing
   sudo ufw disable
   ```

3. **Wrong network mode**
   
   **Solution:** Try host networking
   ```yaml
   network_mode: host
   ```

4. **DNS not configured**
   
   **Solution:** Add DNS servers in compose file
   ```yaml
   dns:
     - 8.8.8.8
     - 8.8.4.4
   ```

### Issue: Volume/Storage Problems

**Symptoms:**
- Data not persisting
- "No space left on device" errors
- Permission denied errors

**🌐 Diagnosis:**

```bash
# Check volumes
podman volume ls

# Inspect volume
podman volume inspect {{CAPABILITY_NAME}}-data

# Check disk space
df -h

# Check volume mount
podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].Mounts'
```

**🌐 Common Causes:**

1. **Disk full**
   
   **Diagnosis:**
   ```bash
   df -h
   ```
   
   **Solution:** Free up space or expand disk

2. **Volume permissions**
   
   **Solution:**
   ```bash
   # Check volume location
   podman volume inspect {{CAPABILITY_NAME}}-data | jq '.[].Mountpoint'
   
   # Fix permissions
   sudo chown -R 1000:1000 /path/to/volume
   ```

3. **Volume not mounted**
   
   **Solution:** Verify volumes section in compose file

**🍓 ARM64 Specific:**
- SD card corruption
  ```bash
  # Check filesystem
  sudo fsck /dev/mmcblk0p2
  ```
  
  **Solution:** Use high-quality SD card, consider USB SSD

### Issue: High Resource Usage

**Symptoms:**
- Container using more resources than expected
- System becoming unresponsive
- Other services affected

**🌐 Diagnosis:**

```bash
# Monitor resources
podman stats {{CAPABILITY_NAME}}-capability

# Check system load
uptime

# Process tree
pstree -p $(podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].State.Pid')
```

**🌐 Solutions:**

1. **Set resource limits**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 4g
         cpus: '2'
   ```

2. **Identify resource leak**
   - Check application logs
   - Monitor over time
   - Profile application

3. **Reduce workload**
   - Limit concurrent requests
   - Use smaller models
   - Optimize code

## Platform-Specific Issues

### 🍓 ARM64 (Raspberry Pi) Issues

#### Power Supply Problems

**Symptoms:**
- Random crashes
- "Under-voltage detected" warnings
- USB devices disconnecting

**Diagnosis:**
```bash
# Check for under-voltage
vcgencmd get_throttled
# 0x50000 or 0x50005 = under-voltage occurred
```

**Solution:**
- Use official Raspberry Pi power supply (5V 3A minimum)
- For Pi 5, use official 27W USB-C power supply

#### SD Card Issues

**Symptoms:**
- Slow I/O
- Corruption errors
- Read-only filesystem

**Diagnosis:**
```bash
# Check SD card
sudo dmesg | grep mmc

# Test speed
sudo hdparm -t /dev/mmcblk0
```

**Solutions:**
- Use high-quality SD card (SanDisk Extreme, Samsung EVO)
- Use USB SSD for data
- Regular backups

#### Temperature Issues

**Symptoms:**
- Thermal throttling warnings
- Performance degradation
- System instability

**Diagnosis:**
```bash
# Monitor temperature
watch -n 1 vcgencmd measure_temp

# Check throttling
vcgencmd get_throttled
```

**Solutions:**
- Add heatsink
- Add fan (5V PWM fan)
- Improve case ventilation
- Reduce CPU usage

### 💻 AMD64 Issues

#### SELinux Blocking

**Symptoms:**
- Permission denied errors
- Container can't access volumes
- "Permission denied" in logs

**Diagnosis:**
```bash
# Check SELinux status
getenforce

# View denials
sudo ausearch -m avc -ts recent
```

**Solutions:**
```bash
# Temporarily disable
sudo setenforce 0

# Fix volume labels
sudo chcon -Rt svirt_sandbox_file_t /path/to/volume

# Or disable permanently (not recommended)
sudo setenforce 0
# Edit /etc/selinux/config: SELINUX=permissive
```

#### NVIDIA GPU Issues (if using GPU)

**Diagnosis:**
```bash
# Check NVIDIA driver
nvidia-smi

# Check container runtime
podman run --rm nvidia/cuda:11.0-base nvidia-smi
```

**Solutions:**
- Install nvidia-container-toolkit
- Configure Podman for GPU access
- See capability-specific GPU documentation

## Debugging Techniques

### 🌐 Enable Debug Logging

**Container logs:**
```bash
# Increase log level (if supported)
podman exec {{CAPABILITY_NAME}}-capability \
  kill -USR1 $(pidof capability-process)
```

**Podman debug mode:**
```bash
# Run with debug logging
podman --log-level=debug ps
```

### 🌐 Interactive Debugging

**Get shell in container:**
```bash
# Bash shell
podman exec -it {{CAPABILITY_NAME}}-capability /bin/bash

# Or sh if bash not available
podman exec -it {{CAPABILITY_NAME}}-capability /bin/sh
```

**Run commands in container:**
```bash
# Check process
podman exec {{CAPABILITY_NAME}}-capability ps aux

# Check network
podman exec {{CAPABILITY_NAME}}-capability netstat -tulpn

# Check files
podman exec {{CAPABILITY_NAME}}-capability ls -la /data
```

### 🌐 Network Debugging

**Test connectivity:**
```bash
# From host to container
curl -v http://localhost:{{PORT}}{{HEALTH_PATH}}

# From container to external
podman exec {{CAPABILITY_NAME}}-capability curl -v https://google.com

# DNS resolution
podman exec {{CAPABILITY_NAME}}-capability nslookup google.com
```

### 🌐 Performance Profiling

**CPU profiling:**
```bash
# Sample CPU usage
perf record -p $(podman inspect {{CAPABILITY_NAME}}-capability | jq '.[].State.Pid')
perf report
```

**Memory profiling:**
```bash
# Watch memory over time
watch -n 1 'podman stats --no-stream {{CAPABILITY_NAME}}-capability'
```

## Recovery Procedures

### 🌐 Restart Container

```bash
# Graceful restart
podman restart {{CAPABILITY_NAME}}-capability

# Force restart
podman kill {{CAPABILITY_NAME}}-capability
podman start {{CAPABILITY_NAME}}-capability
```

### 🌐 Rebuild Container

```bash
# Stop and remove
podman stop {{CAPABILITY_NAME}}-capability
podman rm {{CAPABILITY_NAME}}-capability

# Pull latest image
podman pull {{CONTAINER_IMAGE}}

# Redeploy
./scripts/deploy.sh
```

### 🌐 Reset to Clean State

```bash
# Stop and remove container
podman stop {{CAPABILITY_NAME}}-capability
podman rm {{CAPABILITY_NAME}}-capability

# Remove volume (WARNING: deletes data)
podman volume rm {{CAPABILITY_NAME}}-data

# Redeploy
./scripts/deploy.sh
```

### 🌐 Emergency Cleanup

```bash
# Stop all containers
podman stop -a

# Remove all containers
podman rm -a

# Remove unused volumes
podman volume prune

# Remove unused images
podman image prune
```

## Getting Help

### 🌐 Collect Diagnostic Information

```bash
# System info
uname -a
cat /etc/os-release

# Podman version
podman --version

# Container status
podman ps -a

# Container logs
podman logs {{CAPABILITY_NAME}}-capability > capability.log

# Container config
podman inspect {{CAPABILITY_NAME}}-capability > container-inspect.json

# Resource usage
podman stats --no-stream {{CAPABILITY_NAME}}-capability > stats.txt

# System resources
free -h > system-memory.txt
df -h > system-disk.txt
```

### 🌐 Report Issues

Include in bug reports:
1. Platform (ARM64 or AMD64)
2. OS version
3. Podman version
4. Container logs
5. Configuration files
6. Steps to reproduce

## Summary

Most issues can be resolved by:
1. **Checking logs** - `podman logs {{CAPABILITY_NAME}}-capability`
2. **Verifying resources** - `podman stats`
3. **Testing connectivity** - `curl` health endpoint
4. **Reviewing configuration** - capability.json and compose files
5. **Platform-specific checks** - Temperature (ARM64), SELinux (AMD64)

Use this guide systematically to diagnose and resolve issues.

---

**See Also:**
- [Performance Tuning](performance-tuning.md)
- [Deployment Guide](deployment-guide.md)
- [Architecture Overview](architecture.md)
