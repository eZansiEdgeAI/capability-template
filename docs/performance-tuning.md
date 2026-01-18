# Performance Tuning Guide

## Overview

This guide covers performance optimization strategies for eZansiEdgeAI capabilities across ARM64 (Raspberry Pi) and AMD64 (x86-64) platforms.

## Platform Performance Characteristics

### 🍓 ARM64 (Raspberry Pi)

**Strengths:**
- Excellent power efficiency (5-15W)
- Consistent performance (no thermal throttling on Pi 5)
- Good for sustained workloads
- Lower cost

**Limitations:**
- Lower single-thread performance
- Limited RAM (4-16GB)
- SD card I/O bottlenecks
- Network limited to 1Gbps (Gigabit Ethernet)

**Best For:**
- Edge deployment
- Always-on services
- Moderate workloads
- Cost-sensitive deployments

### 💻 AMD64 (x86-64)

**Strengths:**
- High single-thread performance
- More RAM available (16-128GB+)
- Fast NVMe storage
- High-speed networking

**Limitations:**
- Higher power consumption (50-300W+)
- More expensive hardware
- Larger physical footprint
- May require active cooling

**Best For:**
- Development workstations
- High-throughput production
- Large models
- Heavy concurrent load

## Resource Allocation Strategies

### Memory Allocation

#### General Principles

1. **Leave headroom** - Reserve 10-25% for OS and system processes
2. **Monitor swap** - Avoid swapping; increase limits if it occurs
3. **Use reservations** - Set both limits and reservations
4. **Test under load** - Validate allocations with realistic workloads

#### Platform-Specific Recommendations

**🍓 Raspberry Pi 4 (8GB)**
```yaml
deploy:
  resources:
    limits:
      memory: 5g      # 62.5% of total
    reservations:
      memory: 3g      # 37.5% of total
```
- Conservative allocation
- Leaves 3GB for OS
- Safe for most workloads

**🍓 Raspberry Pi 5 (16GB)**
```yaml
deploy:
  resources:
    limits:
      memory: 12g     # 75% of total
    reservations:
      memory: 8g      # 50% of total
```
- More aggressive allocation
- Leaves 4GB for OS
- Good for production workloads

**💻 AMD64 (24GB)**
```yaml
deploy:
  resources:
    limits:
      memory: 18g     # 75% of total
    reservations:
      memory: 12g     # 50% of total
```
- Balanced allocation
- Leaves 6GB for OS
- Suitable for most capabilities

**💻 AMD64 (32GB+)**
```yaml
deploy:
  resources:
    limits:
      memory: 28g     # 87.5% of total (for 32GB)
    reservations:
      memory: 20g     # 62.5% of total
```
- Aggressive allocation
- Optimized for heavy workloads
- Monitor actual usage

### CPU Allocation

#### General Principles

1. **Start conservative** - Begin with 50% of cores
2. **Monitor utilization** - Use `podman stats` to track actual usage
3. **Avoid overcommit** - Don't exceed physical cores
4. **Consider workload** - I/O-bound vs CPU-bound

#### Platform-Specific Recommendations

**🍓 ARM64 (4 cores)**
```yaml
deploy:
  resources:
    limits:
      cpus: '4'       # Use all available cores
```
- Limited cores available
- Allocate all for production
- Consider 2-3 for development

**💻 AMD64 (6-8 cores)**
```yaml
deploy:
  resources:
    limits:
      cpus: '6'       # 75% of 8 cores
```
- Leave cores for OS and other processes
- Scale up for CPU-intensive workloads

**💻 AMD64 (12-16 cores)**
```yaml
deploy:
  resources:
    limits:
      cpus: '12'      # 75% of 16 cores
```
- More headroom available
- Can allocate more for heavy workloads

### Storage Optimization

#### 🍓 ARM64 (Raspberry Pi)

**SD Card Optimization:**
```bash
# Use high-quality SD card (UHS-I or better)
# Class 10 minimum, A2 rating preferred

# Check SD card performance
sudo hdparm -t /dev/mmcblk0

# Consider USB SSD for better performance
# Mount volume on USB SSD instead of SD card
```

**Best Practices:**
- Use USB 3.0 SSD for data volumes
- Keep OS on SD card
- Minimize write operations
- Use tmpfs for temporary files

**Example with USB SSD:**
```yaml
volumes:
  capability-data:
    driver: local
    driver_opts:
      type: none
      device: /mnt/usb-ssd/capability-data
      o: bind
```

#### 💻 AMD64

**SSD/NVMe Optimization:**
```bash
# Check disk performance
sudo hdparm -t /dev/nvme0n1

# Enable TRIM (if not already enabled)
sudo fstrim -v /
```

**Best Practices:**
- Use NVMe for best performance
- SATA SSD acceptable for most workloads
- Enable TRIM/discard
- Monitor disk space

## Platform-Specific Optimizations

### 🍓 ARM64 Optimization

#### 1. Thermal Management

**Monitor Temperature:**
```bash
# Raspberry Pi
vcgencmd measure_temp

# Watch temperature continuously
watch -n 1 vcgencmd measure_temp
```

**Thermal Throttling:**
- Pi 4: Throttles at 80°C
- Pi 5: Better thermal management, less throttling
- Use active cooling (fan) for sustained loads
- Consider heatsink for Pi 4

**Prevent Throttling:**
```bash
# Check throttling status
vcgencmd get_throttled

# 0x0 = no throttling
# Non-zero = throttling occurred
```

#### 2. Memory Management

**Enable zswap:**
```bash
# Add to /boot/cmdline.txt
zswap.enabled=1 zswap.compressor=lz4
```

**Reduce swappiness:**
```bash
# Set in /etc/sysctl.conf
vm.swappiness=10
```

#### 3. Network Optimization

**Raspberry Pi Network:**
- Gigabit Ethernet (1Gbps max)
- Shared USB/Ethernet bus on Pi 4
- Dedicated Ethernet on Pi 5

**Optimize for local deployment:**
```yaml
# Use host networking for lower latency
network_mode: host
```

#### 4. Power Management

**Disable unnecessary services:**
```bash
# Disable Bluetooth if not needed
sudo systemctl disable bluetooth

# Disable WiFi if using Ethernet
sudo rfkill block wifi
```

### 💻 AMD64 Optimization

#### 1. CPU Performance

**Set CPU governor:**
```bash
# Check current governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set to performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

**Disable CPU power saving:**
```bash
# In /etc/default/grub, add:
GRUB_CMDLINE_LINUX="intel_pstate=disable"
# Or for AMD:
GRUB_CMDLINE_LINUX="amd_pstate=disable"

# Update grub
sudo update-grub
```

#### 2. Memory Optimization

**Huge pages for large memory workloads:**
```bash
# Enable transparent huge pages
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

# Set in /etc/sysctl.conf
vm.nr_hugepages=1024
```

#### 3. Network Optimization

**Tune network stack:**
```bash
# Add to /etc/sysctl.conf
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
```

#### 4. Storage Optimization

**NVMe tuning:**
```bash
# Check NVMe queue depth
cat /sys/block/nvme0n1/queue/nr_requests

# Increase if needed (in /etc/udev/rules.d/60-nvme.rules)
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/nr_requests}="1024"
```

## Workload-Specific Tuning

### LLM Capabilities

**🍓 ARM64:**
```yaml
# Conservative for small models
memory: 4g
cpus: '4'

# Environment variables
environment:
  - NUM_THREADS=4
  - MAX_CONCURRENT_REQUESTS=2
```

**💻 AMD64:**
```yaml
# Generous for large models
memory: 20g
cpus: '8'

# Environment variables
environment:
  - NUM_THREADS=8
  - MAX_CONCURRENT_REQUESTS=5
```

### Speech-to-Text (STT)

**🍓 ARM64:**
```yaml
memory: 2g
cpus: '4'

environment:
  - WORKERS=2
  - BATCH_SIZE=1
```

**💻 AMD64:**
```yaml
memory: 8g
cpus: '6'

environment:
  - WORKERS=4
  - BATCH_SIZE=4
```

### Vision Capabilities

**🍓 ARM64:**
```yaml
memory: 3g
cpus: '4'

environment:
  - INFERENCE_THREADS=4
  - IMAGE_CACHE_SIZE=100
```

**💻 AMD64:**
```yaml
memory: 12g
cpus: '8'

environment:
  - INFERENCE_THREADS=8
  - IMAGE_CACHE_SIZE=500
```

## Monitoring and Benchmarking

### Real-Time Monitoring

**Container Stats:**
```bash
# Live stats
podman stats {{CAPABILITY_NAME}}-capability

# One-time snapshot
podman stats --no-stream {{CAPABILITY_NAME}}-capability
```

**System Resources:**
```bash
# Overall system
htop

# I/O monitoring
iotop

# Network monitoring
iftop
```

### Benchmarking

**Run performance tests:**
```bash
./tests/test-performance.sh
```

**Custom benchmarks:**
```bash
# Measure response time
time curl -X POST http://localhost:{{PORT}}{{ENDPOINT}} \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Concurrent requests
seq 10 | parallel -j 10 "curl -s http://localhost:{{PORT}}{{HEALTH_PATH}}"
```

### Performance Baseline

Establish baselines for your capability:

**🍓 ARM64 Expected:**
- Health check: 50-200ms
- Simple inference: 500ms-5s
- Complex inference: 5s-30s

**💻 AMD64 Expected:**
- Health check: 10-50ms
- Simple inference: 100ms-2s
- Complex inference: 1s-10s

## Optimization Checklist

### 🍓 ARM64 Optimization Checklist

- [ ] Using high-quality SD card or USB SSD
- [ ] Active cooling installed (fan or heatsink)
- [ ] Temperature monitoring configured
- [ ] Swap disabled or minimal
- [ ] Resource limits set appropriately
- [ ] Unnecessary services disabled
- [ ] Performance baseline established
- [ ] Thermal throttling not occurring

### 💻 AMD64 Optimization Checklist

- [ ] CPU governor set to performance
- [ ] Using SSD/NVMe storage
- [ ] Memory limits set appropriately
- [ ] CPU limits set appropriately
- [ ] Network tuning applied (if needed)
- [ ] Transparent huge pages enabled (if applicable)
- [ ] Performance baseline established
- [ ] Resource monitoring configured

## Common Performance Issues

### High Memory Usage

**Symptoms:**
- Container using more memory than expected
- System swapping
- OOM (Out of Memory) kills

**🍓 ARM64 Solutions:**
- Reduce memory limit
- Use smaller models
- Reduce concurrent requests
- Enable memory reservations

**💻 AMD64 Solutions:**
- Increase memory limit
- Check for memory leaks
- Use memory profiling tools
- Consider larger system

### High CPU Usage

**Symptoms:**
- Container using 100% CPU
- Slow response times
- System unresponsive

**🍓 ARM64 Solutions:**
- Reduce number of threads
- Limit concurrent requests
- Use CPU reservations
- Check for thermal throttling

**💻 AMD64 Solutions:**
- Increase CPU allocation
- Optimize application code
- Use profiling tools
- Check CPU governor

### Slow I/O

**Symptoms:**
- High disk usage
- Slow model loading
- Delayed responses

**🍓 ARM64 Solutions:**
- Use USB SSD instead of SD card
- Reduce write operations
- Use tmpfs for temporary files
- Optimize data loading

**💻 AMD64 Solutions:**
- Use NVMe instead of SATA SSD
- Check disk queue depth
- Enable TRIM
- Optimize file system (ext4, xfs)

### Network Latency

**Symptoms:**
- Slow API responses
- High network latency
- Connection timeouts

**🌐 Both Platforms:**
- Use host networking mode
- Reduce request/response sizes
- Enable HTTP/2 or gRPC
- Check network configuration

## Best Practices Summary

1. **🎯 Start Conservative** - Begin with lower resource limits and increase as needed
2. **📊 Monitor Continuously** - Use `podman stats` and system monitoring tools
3. **🔧 Tune Incrementally** - Make one change at a time and measure impact
4. **📝 Document Baselines** - Record performance metrics for comparison
5. **🧪 Test Realistic Workloads** - Use production-like data for testing
6. **⚖️ Balance Resources** - Don't over-allocate; leave headroom for OS
7. **🌡️ Watch Temperature** (ARM64) - Prevent thermal throttling
8. **⚡ Optimize Storage** - Use SSD/USB storage on ARM64, NVMe on AMD64
9. **🔄 Regular Reviews** - Revisit configurations as usage patterns change
10. **📖 Follow Platform Guides** - Use platform-specific optimizations

## Advanced Topics

### Container Runtime Optimization

**Podman configuration:**
```bash
# Edit /etc/containers/storage.conf
[storage]
driver = "overlay"
graphroot = "/var/lib/containers/storage"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
```

### Caching Strategies

**Layer caching:**
- Use multi-arch images
- Optimize Dockerfile layer order
- Use build cache

**Data caching:**
- Cache models in volumes
- Use Redis/Memcached for responses
- Implement application-level caching

### Load Balancing

**Multiple instances:**
```bash
# Run multiple capability instances
podman-compose up -d --scale {{CAPABILITY_NAME}}=3

# Use nginx or HAProxy for load balancing
```

## Summary

Performance tuning requires:
- Understanding platform characteristics
- Appropriate resource allocation
- Continuous monitoring
- Incremental optimization
- Platform-specific techniques

Use this guide to optimize your capability for your target platform and workload.

---

**See Also:**
- [Architecture Overview](architecture.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Deployment Guide](deployment-guide.md)
