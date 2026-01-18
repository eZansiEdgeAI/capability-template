# Deployment Guide

## Overview

This guide covers comprehensive deployment strategies for eZansiEdgeAI capabilities across different environments and architectures. Choose the deployment strategy that best fits your infrastructure, security requirements, and operational constraints.

**Platform Markers:**
- 🍓 **ARM64** - Raspberry Pi specific
- 💻 **AMD64** - x86-64 specific  
- 🌐 **Both** - Applies to both platforms

## Deployment Strategy Overview

| Strategy | Best For | Complexity | Internet Required | Architecture Support |
|----------|----------|------------|-------------------|---------------------|
| **Clone & Configure** | Development, testing | Low | Yes (initial) | 🌐 Both |
| **Export/Import** | Air-gapped environments | Medium | No | 🌐 Both |
| **Registry-based** | Production, CI/CD | Low | Yes | 🌐 Both |
| **Rebuild from Source** | Custom modifications | High | Yes | 🌐 Both |
| **Cross-Architecture** | Platform migration | Medium | Yes | 🌐 Both |

## Strategy 1: Clone and Configure (Recommended for Development)

### Overview

Clone the capability repository and customize configuration files. Best for development and initial deployment.

### Prerequisites

**🌐 Both Platforms:**
```bash
# Git
git --version

# Podman
podman --version

# podman-compose
podman-compose --version

# Basic utilities
curl --version
jq --version
```

### Deployment Steps

#### 1. Clone the Repository

```bash
# Clone the capability repository
git clone https://github.com/your-org/{{CAPABILITY_NAME}}.git
cd {{CAPABILITY_NAME}}

# Or if using this template, create from template first
```

#### 2. Customize Configuration

```bash
# Edit capability contract
vim capability.json

# Replace all placeholders:
# - {{CAPABILITY_NAME}} → your-capability-name
# - {{CONTAINER_IMAGE}} → registry/image:tag
# - {{PORT}} → 8080
# - {{HEALTH_PATH}} → /health
```

**Example capability.json:**
```json
{
  "name": "my-llm-capability",
  "version": "1.0.0",
  "type": "capability",
  "description": "LLM inference capability",
  "provides": ["llm"],
  "container": {
    "image": "myregistry/llm-capability:latest",
    "port": 8080
  },
  "endpoints": {
    "health": {
      "path": "/health"
    },
    "main": {
      "path": "/api/generate"
    }
  }
}
```

#### 3. Select Platform Configuration

**🍓 ARM64 (Raspberry Pi):**
```bash
# For Pi 4 (8GB)
cp config/pi4-8gb.yml podman-compose.yml

# For Pi 5 (16GB) - Recommended
cp podman-compose.pi5.yml podman-compose.yml
```

**💻 AMD64:**
```bash
# For systems with 24GB RAM
cp config/amd64-24gb.yml podman-compose.yml

# For systems with 32GB+ RAM (Recommended)
cp podman-compose.amd64.yml podman-compose.yml
```

#### 4. Deploy

```bash
# Pull the container image
podman pull {{CONTAINER_IMAGE}}

# Deploy with auto-detection (recommended)
./scripts/deploy.sh

# Or deploy manually
podman-compose up -d

# Verify deployment
./scripts/validate-deployment.sh
```

#### 5. Validate

```bash
# Quick health check
./scripts/health-check.sh

# Test API
curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Monitor logs
podman logs -f {{CAPABILITY_NAME}}-capability

# Check resource usage
podman stats --no-stream {{CAPABILITY_NAME}}-capability
```

### Advantages

- ✅ Easy to customize and modify
- ✅ Full control over configuration
- ✅ Version control friendly
- ✅ Good for iterative development
- ✅ Simple troubleshooting

### Disadvantages

- ❌ Requires Git and repository access
- ❌ Manual configuration updates
- ❌ Not ideal for production at scale

### When to Use

- Development and testing environments
- Learning and experimentation
- Single-instance deployments
- Custom capability development

## Strategy 2: Export/Import Container (Air-gapped Deployment)

### Overview

Export container images and import them on target systems without internet access. Ideal for air-gapped or restricted environments.

### Prerequisites

**Source System (with internet):**
- Podman installed
- Internet access
- Sufficient disk space for image export

**Target System (air-gapped):**
- Podman installed
- No internet required
- Method to transfer files (USB, network share)

### Deployment Steps

#### 1. Export Container Image (Source System)

```bash
# Pull the image
podman pull {{CONTAINER_IMAGE}}

# Export to tar file
podman save -o {{CAPABILITY_NAME}}-image.tar {{CONTAINER_IMAGE}}

# Compress for easier transfer (optional)
gzip {{CAPABILITY_NAME}}-image.tar

# Verify export
ls -lh {{CAPABILITY_NAME}}-image.tar.gz
```

#### 2. Export Configuration Files

```bash
# Create deployment package
mkdir -p {{CAPABILITY_NAME}}-deployment
cd {{CAPABILITY_NAME}}-deployment

# Copy essential files
cp ../capability.json .
cp ../podman-compose.yml .
cp -r ../scripts .
cp -r ../config .

# Create archive
cd ..
tar -czf {{CAPABILITY_NAME}}-deployment.tar.gz {{CAPABILITY_NAME}}-deployment/

# Verify package
ls -lh {{CAPABILITY_NAME}}-deployment.tar.gz
```

#### 3. Transfer Files to Target System

```bash
# Example: USB transfer
cp {{CAPABILITY_NAME}}-image.tar.gz /media/usb/
cp {{CAPABILITY_NAME}}-deployment.tar.gz /media/usb/

# Example: SCP transfer (if network available)
scp {{CAPABILITY_NAME}}-*.tar.gz user@target-host:/tmp/

# Verify checksums
sha256sum {{CAPABILITY_NAME}}-*.tar.gz > checksums.txt
```

#### 4. Import on Target System

```bash
# Extract deployment package
tar -xzf {{CAPABILITY_NAME}}-deployment.tar.gz
cd {{CAPABILITY_NAME}}-deployment

# Load container image
podman load -i ../{{CAPABILITY_NAME}}-image.tar.gz

# Verify image loaded
podman images | grep {{CAPABILITY_NAME}}

# Deploy
podman-compose up -d

# Validate
./scripts/validate-deployment.sh
```

#### 5. Cleanup (Optional)

```bash
# Remove transferred files
rm {{CAPABILITY_NAME}}-image.tar.gz
rm {{CAPABILITY_NAME}}-deployment.tar.gz

# Keep only running container and volumes
```

### Advanced: Multi-Architecture Export

```bash
# Export for both ARM64 and AMD64
podman save -o capability-multi.tar \
  {{CONTAINER_IMAGE}}:latest-arm64 \
  {{CONTAINER_IMAGE}}:latest-amd64

# On target, Podman will use the correct architecture automatically
podman load -i capability-multi.tar
```

### Advantages

- ✅ Works in air-gapped environments
- ✅ No internet required on target
- ✅ Controlled deployment timing
- ✅ Repeatable and auditable
- ✅ Offline-first architecture

### Disadvantages

- ❌ Manual transfer process
- ❌ Large file sizes
- ❌ Update process more complex
- ❌ Version management overhead

### When to Use

- Air-gapped or restricted networks
- High-security environments
- Limited or unreliable internet
- Compliance requirements (auditing)
- Edge devices without connectivity

## Strategy 3: Registry-based Deployment (Recommended for Production)

### Overview

Deploy directly from container registry. Best for production environments with reliable internet access.

### Prerequisites

**🌐 Both Platforms:**
```bash
# Podman with registry access
podman --version

# Network access to registry
ping registry.example.com

# Authentication (if private registry)
podman login registry.example.com
```

### Deployment Steps

#### 1. Configure Registry Access

**Public Registry (Docker Hub, GitHub Container Registry):**
```bash
# No authentication needed for public images
podman pull docker.io/{{CONTAINER_IMAGE}}
podman pull ghcr.io/{{CONTAINER_IMAGE}}
```

**Private Registry:**
```bash
# Login to private registry
podman login registry.example.com
# Username: your-username
# Password: your-password

# Or use credentials file
cat > auth.json <<EOF
{
  "auths": {
    "registry.example.com": {
      "auth": "base64-encoded-credentials"
    }
  }
}
EOF

podman login --authfile=auth.json registry.example.com
```

#### 2. Create Deployment Configuration

```bash
# Create minimal deployment structure
mkdir -p {{CAPABILITY_NAME}}
cd {{CAPABILITY_NAME}}

# Create capability.json
cat > capability.json <<EOF
{
  "name": "{{CAPABILITY_NAME}}",
  "container": {
    "image": "registry.example.com/{{CONTAINER_IMAGE}}:latest",
    "port": {{PORT}}
  },
  "endpoints": {
    "health": {
      "path": "{{HEALTH_PATH}}"
    }
  }
}
EOF

# Create podman-compose.yml (platform-appropriate)
```

**🍓 ARM64 Example:**
```yaml
version: '3.8'

services:
  {{CAPABILITY_NAME}}:
    image: registry.example.com/{{CONTAINER_IMAGE}}:latest
    container_name: {{CAPABILITY_NAME}}-capability
    ports:
      - "{{PORT}}:{{PORT}}"
    volumes:
      - {{CAPABILITY_NAME}}-data:/data
    deploy:
      resources:
        limits:
          memory: 12g
          cpus: '4'
        reservations:
          memory: 8g
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{PORT}}{{HEALTH_PATH}}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  {{CAPABILITY_NAME}}-data:
```

**💻 AMD64 Example:**
```yaml
version: '3.8'

services:
  {{CAPABILITY_NAME}}:
    image: registry.example.com/{{CONTAINER_IMAGE}}:latest
    container_name: {{CAPABILITY_NAME}}-capability
    ports:
      - "{{PORT}}:{{PORT}}"
    volumes:
      - {{CAPABILITY_NAME}}-data:/data
    deploy:
      resources:
        limits:
          memory: 20g
          cpus: '8'
        reservations:
          memory: 16g
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{PORT}}{{HEALTH_PATH}}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  {{CAPABILITY_NAME}}-data:
```

#### 3. Deploy from Registry

```bash
# Pull latest image
podman pull registry.example.com/{{CONTAINER_IMAGE}}:latest

# Deploy
podman-compose up -d

# Verify
podman ps | grep {{CAPABILITY_NAME}}
curl http://localhost:{{PORT}}{{HEALTH_PATH}}
```

#### 4. Set Up Automatic Updates (Optional)

**Using systemd timer:**
```bash
# Create update script
cat > /usr/local/bin/update-{{CAPABILITY_NAME}}.sh <<'EOF'
#!/bin/bash
cd /opt/{{CAPABILITY_NAME}}
podman pull registry.example.com/{{CONTAINER_IMAGE}}:latest
podman-compose up -d
EOF

chmod +x /usr/local/bin/update-{{CAPABILITY_NAME}}.sh

# Create systemd service
sudo tee /etc/systemd/system/update-{{CAPABILITY_NAME}}.service <<EOF
[Unit]
Description=Update {{CAPABILITY_NAME}} capability
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-{{CAPABILITY_NAME}}.sh
EOF

# Create systemd timer
sudo tee /etc/systemd/system/update-{{CAPABILITY_NAME}}.timer <<EOF
[Unit]
Description=Update {{CAPABILITY_NAME}} capability daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable timer
sudo systemctl enable update-{{CAPABILITY_NAME}}.timer
sudo systemctl start update-{{CAPABILITY_NAME}}.timer
```

### Multi-Architecture Registry Support

```bash
# Push multi-arch manifest to registry
podman manifest create {{CONTAINER_IMAGE}}:latest

podman manifest add {{CONTAINER_IMAGE}}:latest \
  docker://{{CONTAINER_IMAGE}}:latest-amd64

podman manifest add {{CONTAINER_IMAGE}}:latest \
  docker://{{CONTAINER_IMAGE}}:latest-arm64

podman manifest push {{CONTAINER_IMAGE}}:latest \
  docker://registry.example.com/{{CONTAINER_IMAGE}}:latest

# Podman automatically pulls correct architecture
```

### Advantages

- ✅ Centralized image management
- ✅ Easy updates and rollbacks
- ✅ Version control via tags
- ✅ Multi-architecture support
- ✅ Automated deployment possible
- ✅ CI/CD integration

### Disadvantages

- ❌ Requires internet access
- ❌ Registry dependency
- ❌ Potential network latency
- ❌ Authentication complexity

### When to Use

- Production deployments
- Multiple instances across infrastructure
- Automated CI/CD pipelines
- Centralized image management
- Teams with container registry infrastructure

## Strategy 4: Rebuild from Source

### Overview

Build container image from source code. Best for custom modifications or when pre-built images are unavailable.

### Prerequisites

**🌐 Both Platforms:**
```bash
# Build tools
podman --version
git --version

# Platform-specific build requirements
# (varies by capability)
```

### Deployment Steps

#### 1. Clone Source Repository

```bash
# Clone capability source
git clone https://github.com/your-org/{{CAPABILITY_NAME}}-source.git
cd {{CAPABILITY_NAME}}-source

# Checkout specific version (recommended)
git checkout v1.0.0

# Or use main/master for latest
git checkout main
```

#### 2. Review Build Configuration

```bash
# Check Dockerfile
cat Dockerfile

# Review build arguments
grep ARG Dockerfile

# Check multi-arch support
grep -E "FROM.*--platform" Dockerfile
```

#### 3. Build Container Image

**🌐 Single Architecture Build:**
```bash
# Build for current architecture
podman build -t {{CONTAINER_IMAGE}}:local .

# Verify build
podman images | grep {{CONTAINER_IMAGE}}
```

**🌐 Multi-Architecture Build:**
```bash
# Build for ARM64
podman build --platform linux/arm64 \
  -t {{CONTAINER_IMAGE}}:local-arm64 .

# Build for AMD64
podman build --platform linux/amd64 \
  -t {{CONTAINER_IMAGE}}:local-amd64 .

# Create multi-arch manifest
podman manifest create {{CONTAINER_IMAGE}}:local

podman manifest add {{CONTAINER_IMAGE}}:local \
  {{CONTAINER_IMAGE}}:local-arm64

podman manifest add {{CONTAINER_IMAGE}}:local \
  {{CONTAINER_IMAGE}}:local-amd64
```

#### 4. Test Built Image

```bash
# Run container for testing
podman run -d \
  --name {{CAPABILITY_NAME}}-test \
  -p {{PORT}}:{{PORT}} \
  {{CONTAINER_IMAGE}}:local

# Test health endpoint
sleep 10  # Wait for startup
curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check logs
podman logs {{CAPABILITY_NAME}}-test

# Cleanup test container
podman stop {{CAPABILITY_NAME}}-test
podman rm {{CAPABILITY_NAME}}-test
```

#### 5. Deploy Built Image

```bash
# Update podman-compose.yml to use local image
sed -i 's|image:.*|image: {{CONTAINER_IMAGE}}:local|' podman-compose.yml

# Deploy
podman-compose up -d

# Validate
./scripts/validate-deployment.sh
```

#### 6. Optional: Push to Registry

```bash
# Tag for registry
podman tag {{CONTAINER_IMAGE}}:local \
  registry.example.com/{{CONTAINER_IMAGE}}:v1.0.0

# Login to registry
podman login registry.example.com

# Push
podman push registry.example.com/{{CONTAINER_IMAGE}}:v1.0.0
```

### Platform-Specific Build Considerations

**🍓 ARM64 (Raspberry Pi):**
- Builds are slower (limited CPU)
- May require cross-compilation for complex builds
- Consider building on AMD64 with `--platform linux/arm64`
- Watch for thermal throttling during builds
- Ensure sufficient disk space on SD card

**💻 AMD64:**
- Faster builds
- Can cross-compile for ARM64
- More build resources available
- Better for development iteration

### Advantages

- ✅ Full control over build process
- ✅ Custom modifications possible
- ✅ No dependency on pre-built images
- ✅ Transparency and auditability
- ✅ Version pinning at source level

### Disadvantages

- ❌ Build time overhead
- ❌ Requires build tools and dependencies
- ❌ More complex process
- ❌ Platform-specific build considerations
- ❌ Larger disk space requirements

### When to Use

- Custom capability modifications
- Private/proprietary capabilities
- Security compliance (build verification)
- No pre-built images available
- Development and debugging

## Strategy 5: Cross-Architecture Deployment

### Overview

Deploy capabilities across different architectures (ARM64 ↔ AMD64). Essential for platform migration and multi-platform deployments.

### Use Cases

1. **Development → Production**: Develop on AMD64, deploy on ARM64 edge devices
2. **Platform Migration**: Move from Pi 4 to Pi 5, or Pi to AMD64 server
3. **Hybrid Deployment**: Some instances on ARM64, others on AMD64
4. **Testing**: Test on one platform, deploy on another

### Cross-Platform Deployment Process

#### 1. Verify Multi-Architecture Image

```bash
# Check if image supports multiple architectures
podman manifest inspect {{CONTAINER_IMAGE}}:latest | jq '.manifests[].platform'

# Should show both:
# {
#   "architecture": "amd64",
#   "os": "linux"
# }
# {
#   "architecture": "arm64",
#   "os": "linux"
# }
```

#### 2. Platform-Specific Configuration Preparation

**Create configuration for source platform:**
```bash
# On AMD64 (development)
cat > podman-compose.amd64.yml <<EOF
version: '3.8'
services:
  {{CAPABILITY_NAME}}:
    image: {{CONTAINER_IMAGE}}:latest
    deploy:
      resources:
        limits:
          memory: 20g
          cpus: '8'
EOF
```

**Create configuration for target platform:**
```bash
# For ARM64 (production edge)
cat > podman-compose.pi5.yml <<EOF
version: '3.8'
services:
  {{CAPABILITY_NAME}}:
    image: {{CONTAINER_IMAGE}}:latest
    deploy:
      resources:
        limits:
          memory: 12g
          cpus: '4'
EOF
```

#### 3. Export Configuration and Scripts

```bash
# Create deployment package
tar -czf deployment-package.tar.gz \
  capability.json \
  podman-compose.*.yml \
  config/ \
  scripts/

# Transfer to target platform
scp deployment-package.tar.gz user@target-host:/opt/{{CAPABILITY_NAME}}/
```

#### 4. Deploy on Target Platform

```bash
# On target platform
cd /opt/{{CAPABILITY_NAME}}
tar -xzf deployment-package.tar.gz

# Auto-detect platform and deploy
./scripts/deploy.sh

# Or manually specify configuration
# For Pi 5:
podman-compose -f podman-compose.pi5.yml up -d

# For AMD64:
podman-compose -f podman-compose.amd64.yml up -d
```

### Migration Scenarios

#### Scenario 1: Pi 4 (8GB) → Pi 5 (16GB)

**Why Migrate:**
- Better performance (faster CPU)
- More RAM (16GB vs 8GB)
- Better thermals (less throttling)
- Improved I/O performance

**Migration Steps:**

```bash
# 1. On Pi 4 - Backup data
podman-compose down
podman volume export {{CAPABILITY_NAME}}-data > capability-data.tar

# 2. Transfer data
scp capability-data.tar user@pi5:/tmp/

# 3. On Pi 5 - Import data
podman volume create {{CAPABILITY_NAME}}-data
podman volume import {{CAPABILITY_NAME}}-data < /tmp/capability-data.tar

# 4. Deploy with Pi 5 configuration
podman-compose -f podman-compose.pi5.yml up -d

# 5. Validate
./scripts/validate-deployment.sh

# 6. Performance comparison
./tests/test-performance.sh
```

**Expected Improvements:**
- 20-40% faster inference
- 2x memory capacity
- No thermal throttling
- Better concurrent request handling

#### Scenario 2: ARM64 → AMD64 (Edge to Server)

**Why Migrate:**
- Scale up for higher load
- Better performance needed
- More complex workloads
- Development to production

**Migration Steps:**

```bash
# 1. On ARM64 - Export configuration and data
podman-compose down
podman volume export {{CAPABILITY_NAME}}-data > data.tar
tar -czf config-backup.tar.gz capability.json config/

# 2. Transfer to AMD64
scp data.tar config-backup.tar.gz user@amd64-host:/opt/{{CAPABILITY_NAME}}/

# 3. On AMD64 - Deploy
cd /opt/{{CAPABILITY_NAME}}
tar -xzf config-backup.tar.gz

# Create AMD64-specific compose file
cp config/amd64-32gb.yml podman-compose.yml

# Import data
podman volume create {{CAPABILITY_NAME}}-data
podman volume import {{CAPABILITY_NAME}}-data < data.tar

# Pull AMD64 image (automatic)
podman pull {{CONTAINER_IMAGE}}:latest

# Deploy
podman-compose up -d

# 4. Validate and benchmark
./scripts/validate-deployment.sh
./tests/test-performance.sh
```

**Expected Improvements:**
- 3-5x faster inference
- 2-4x memory capacity
- 10x better concurrent handling
- Lower latency

#### Scenario 3: AMD64 → ARM64 (Server to Edge)

**Why Migrate:**
- Deploy to edge locations
- Reduce power consumption
- Lower cost for distributed deployment
- Edge computing requirements

**Migration Steps:**

```bash
# 1. On AMD64 - Optimize for edge
# Test with ARM64-like constraints first
podman run -d \
  --name test-edge \
  --memory=12g \
  --cpus=4 \
  -p {{PORT}}:{{PORT}} \
  {{CONTAINER_IMAGE}}:latest

# Verify performance is acceptable
curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Export
podman-compose down
podman volume export {{CAPABILITY_NAME}}-data > data.tar

# 2. Transfer to ARM64
scp data.tar podman-compose.pi5.yml user@pi5:/opt/{{CAPABILITY_NAME}}/

# 3. On ARM64 - Deploy
cd /opt/{{CAPABILITY_NAME}}
podman volume create {{CAPABILITY_NAME}}-data
podman volume import {{CAPABILITY_NAME}}-data < data.tar

podman-compose -f podman-compose.pi5.yml up -d

# 4. Monitor performance
podman stats {{CAPABILITY_NAME}}-capability

# 5. Monitor temperature (important for ARM64)
watch -n 5 vcgencmd measure_temp
```

**Considerations:**
- Performance will be lower (expected)
- May need to reduce concurrent load
- Monitor thermal throttling
- Consider using lighter models
- Optimize for edge constraints

### Volume Migration Considerations

**🌐 Data Persistence:**
```bash
# Export volume
podman volume export {{CAPABILITY_NAME}}-data -o data.tar

# Transfer
scp data.tar target:/tmp/

# Import on target
podman volume create {{CAPABILITY_NAME}}-data
podman volume import {{CAPABILITY_NAME}}-data -i data.tar

# Or use bind mount for easier migration
mkdir -p /opt/{{CAPABILITY_NAME}}/data
# Update compose file to use bind mount instead
```

**🌐 Large Data Volumes:**
```bash
# Use rsync for large volumes
podman volume inspect {{CAPABILITY_NAME}}-data | jq -r '.[0].Mountpoint'
# Get mountpoint path, then rsync
rsync -avz --progress /var/lib/containers/storage/volumes/{{CAPABILITY_NAME}}-data/_data/ \
  user@target:/opt/data/
```

### Performance Expectations

| Metric | Pi 4 (8GB) | Pi 5 (16GB) | AMD64 (24GB) | AMD64 (32GB+) |
|--------|------------|-------------|--------------|---------------|
| **LLM Inference** | 2-5s | 1-3s | 0.5-1.5s | 0.3-1s |
| **Health Check** | 50-200ms | 30-100ms | 10-50ms | 10-30ms |
| **Concurrent Requests** | 1-2 | 2-4 | 5-10 | 10-20 |
| **Memory Headroom** | 3GB | 4GB | 6GB | 4-8GB |
| **Startup Time** | 30-60s | 20-40s | 10-20s | 10-15s |

### Advantages

- ✅ Platform flexibility
- ✅ Optimize cost/performance trade-offs
- ✅ Support hybrid deployments
- ✅ Easy migration path
- ✅ Development/production parity

### Disadvantages

- ❌ Performance differences to manage
- ❌ Platform-specific testing required
- ❌ Configuration overhead
- ❌ Potential compatibility issues

### When to Use

- Multi-platform infrastructure
- Development on one platform, production on another
- Platform migration projects
- Cost optimization initiatives
- Hybrid cloud-edge deployments

## Best Practices

### General Deployment Best Practices

1. **📋 Version Everything**
   ```bash
   # Tag images with versions
   podman tag {{CONTAINER_IMAGE}}:latest {{CONTAINER_IMAGE}}:v1.0.0
   
   # Version control configurations
   git tag -a v1.0.0 -m "Production release"
   ```

2. **🔍 Validate Before Production**
   ```bash
   # Always validate deployments
   ./scripts/validate-deployment.sh
   
   # Run health checks
   ./scripts/health-check.sh
   
   # Test API endpoints
   ./tests/test-api.sh
   ```

3. **📊 Monitor Resource Usage**
   ```bash
   # Check resource consumption
   podman stats --no-stream {{CAPABILITY_NAME}}-capability
   
   # Set up alerts for high usage
   ```

4. **💾 Backup Data Volumes**
   ```bash
   # Regular backups
   podman volume export {{CAPABILITY_NAME}}-data > \
     backup-$(date +%Y%m%d).tar
   ```

5. **🔄 Plan for Rollbacks**
   ```bash
   # Keep previous image
   podman tag {{CONTAINER_IMAGE}}:latest {{CONTAINER_IMAGE}}:rollback
   
   # Document rollback procedure
   ```

### Platform-Specific Best Practices

**🍓 ARM64 (Raspberry Pi):**
- Use USB SSD for better I/O performance
- Monitor temperature to prevent throttling
- Set conservative resource limits initially
- Test under sustained load
- Plan for slower build times
- Use active cooling for production

**💻 AMD64:**
- Utilize available resources efficiently
- Monitor for resource waste
- Use NVMe storage when possible
- Set up automated updates
- Consider horizontal scaling
- Implement load balancing for multiple instances

### Security Best Practices

1. **🔐 Use Private Registries for Production**
   ```bash
   # Secure registry access
   podman login --username user --password-stdin registry.example.com
   
   # Use read-only volumes when possible
   volumes:
     - config:/app/config:ro
   ```

2. **🛡️ Run as Non-Root**
   ```yaml
   # In podman-compose.yml
   user: "1000:1000"
   ```

3. **🔒 Limit Container Capabilities**
   ```yaml
   cap_drop:
     - ALL
   cap_add:
     - NET_BIND_SERVICE
   ```

4. **🚫 Use Read-Only Root Filesystem**
   ```yaml
   read_only: true
   tmpfs:
     - /tmp
   ```

### Monitoring and Maintenance

**Set up regular health checks:**
```bash
# Create monitoring script
cat > /usr/local/bin/monitor-{{CAPABILITY_NAME}}.sh <<'EOF'
#!/bin/bash
STATUS=$(curl -sf http://localhost:{{PORT}}{{HEALTH_PATH}} || echo "FAILED")
if [ "$STATUS" == "FAILED" ]; then
  echo "Health check failed at $(date)" | mail -s "Alert" admin@example.com
  podman restart {{CAPABILITY_NAME}}-capability
fi
EOF

chmod +x /usr/local/bin/monitor-{{CAPABILITY_NAME}}.sh

# Add to crontab
echo "*/5 * * * * /usr/local/bin/monitor-{{CAPABILITY_NAME}}.sh" | crontab -
```

**Set up log rotation:**
```bash
# Limit log size
podman run --log-opt max-size=10m --log-opt max-file=3 ...
```

## Troubleshooting Deployment Issues

### Image Pull Failures

**Symptom:** Cannot pull container image

**Solutions:**
```bash
# Check connectivity
ping registry.example.com

# Verify authentication
podman login registry.example.com

# Check image exists
podman search {{CONTAINER_IMAGE}}

# Try manual pull with verbose output
podman pull --log-level=debug {{CONTAINER_IMAGE}}
```

### Port Conflicts

**Symptom:** Port already in use

**Solutions:**
```bash
# Find process using port
sudo lsof -i :{{PORT}}

# Use different port
sed -i 's/{{PORT}}/8081/' podman-compose.yml

# Or stop conflicting service
sudo systemctl stop conflicting-service
```

### Resource Limit Issues

**Symptom:** Container OOM killed or CPU throttled

**Solutions:**
```bash
# Check current limits
podman inspect {{CAPABILITY_NAME}}-capability | jq '.HostConfig.Memory'

# Increase limits
# Edit podman-compose.yml
memory: 16g  # Increase from 12g

# Redeploy
podman-compose up -d
```

### Architecture Mismatch

**Symptom:** Container won't start, architecture error

**Solutions:**
```bash
# Check image architecture
podman inspect {{CONTAINER_IMAGE}} | jq '.[].Architecture'

# Verify platform
uname -m

# Pull correct architecture
podman pull --platform linux/arm64 {{CONTAINER_IMAGE}}
podman pull --platform linux/amd64 {{CONTAINER_IMAGE}}
```

## Summary

Choose your deployment strategy based on:

| Your Situation | Recommended Strategy |
|----------------|---------------------|
| Development, iteration, customization | Clone & Configure |
| Air-gapped, high-security environments | Export/Import |
| Production, automation, CI/CD | Registry-based |
| Custom modifications, source access | Rebuild from Source |
| Multi-platform, migration needs | Cross-Architecture |

All strategies support both ARM64 and AMD64 platforms with appropriate configuration adjustments.

---

**See Also:**
- [AMD64 Deployment Guide](deployment-guide-amd64.md) - AMD64-specific details
- [Architecture Overview](architecture.md) - eZansiEdgeAI architecture
- [Performance Tuning](performance-tuning.md) - Optimization strategies
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
