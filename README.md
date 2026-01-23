# eZansiEdgeAI Capability Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Multi-Architecture](https://img.shields.io/badge/arch-ARM64%20%7C%20AMD64-blue)](https://github.com/eZansiEdgeAI/capability-template)

A complete, reusable template for creating multi-architecture eZansiEdgeAI capabilities that work seamlessly on both **ARM64** (Raspberry Pi) and **AMD64** (x86-64) platforms.

This template is aimed at developers and contributors building new capability “LEGO bricks” that can be discovered and invoked via the eZansi Platform Core gateway.

## 🎯 Overview

This template provides everything you need to build production-ready eZansiEdgeAI capabilities:

- ✅ **Multi-architecture support** - Works on ARM64 (Raspberry Pi 4/5) and AMD64 (x86-64)
- ✅ **Contract-driven design** - Standard `capability.json` contract specification
- ✅ **Platform-optimized configs** - Separate configurations for Pi 4, Pi 5, and AMD64 variants
- ✅ **Generic automation scripts** - Deploy, validate, and health-check scripts that work for ANY capability
- ✅ **Comprehensive documentation** - Architecture guides, troubleshooting, and performance tuning
- ✅ **Testing framework** - API and performance tests with platform-aware expectations

## 🚀 Quick Start

### 1. Use This Template

Click the **"Use this template"** button on GitHub to create your new capability repository.

### 2. Customize the Capability Contract

Edit `capability.json` and replace the template values:

```json
{
  "name": "my-awesome-capability",
  "description": "My awesome capability that does amazing things",
  "provides": ["custom-service"],
  "api": {
    "endpoint": "http://localhost:8080",
    "type": "REST",
    "health_check": "/health"
  },
  "container": {
    "image": "myregistry/my-capability:latest",
    "port": 8080
  },
  "endpoints": {
    "health": {
      "method": "GET",
      "path": "/health"
    },
    "main": {
      "method": "POST",
      "path": "/api/process"
    }
  }
}
```

### 3. Update Configuration Files

Replace template values in the `podman-compose.yml` files:
- `my-capability` → Your capability name
- `myregistry/mycapability:latest` → Your container image
- `8080` → Your service port
- `/health` → Your health endpoint path

### 4. Deploy

```bash
# Automatic platform detection and deployment
./scripts/deploy.sh

# Or specify a configuration
./scripts/deploy.sh config/pi5-16gb.yml
./scripts/deploy.sh config/amd64-24gb.yml
```

### 5. Validate

```bash
# Quick health check
./scripts/health-check.sh

# Full validation
./scripts/validate-deployment.sh

# Run tests
./tests/test-api.sh
./tests/test-performance.sh
```

### 6. Manual cold-start (recommended)

Once you’ve implemented your capability’s API, follow the end-to-end cold-start checklist:

- [docs/quickstart-manual-test.md](docs/quickstart-manual-test.md)

## 📋 Resource Requirements

| Platform | RAM | CPU | Storage | Use Case |
|----------|-----|-----|---------|----------|
| **Raspberry Pi 4 (8GB)** | 8GB total<br/>5GB limit | 4 cores | 16GB+ | Development, small-scale inference |
| **Raspberry Pi 5 (16GB)** | 16GB total<br/>12GB limit | 4 cores | 32GB+ | Production edge, medium-scale |
| **AMD64 (24GB)** | 24GB total<br/>18GB limit | 6-8 cores | 50GB+ | Development workstations, testing |
| **AMD64 (32GB+)** | 32GB+ total<br/>28GB limit | 8-16 cores | 100GB+ | Production servers, heavy workloads |

## 🔧 Prerequisites

### ARM64 (Raspberry Pi)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Podman
sudo apt install -y podman

# Install podman-compose (prefer distro package)
sudo apt install -y podman-compose || true

# Fallback (if your distro doesn't package podman-compose)
pip3 install --user podman-compose

# Install utilities
sudo apt install -y curl jq
```

### AMD64 (x86-64)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y podman podman-compose curl jq || true

# Fallback (if your distro doesn't package podman-compose)
pip3 install --user podman-compose

# Fedora/RHEL
sudo dnf install -y podman curl jq
sudo dnf install -y podman podman-compose curl jq || true

# Fallback (if your distro doesn't package podman-compose)
pip3 install --user podman-compose
```

## 📦 Deployment Options

### Option 1: Auto-Detection (Recommended)

```bash
./scripts/deploy.sh
```

Or (recommended for parity with capability repos), use the preflight selector:

```bash
./scripts/choose-compose.sh
./scripts/choose-compose.sh --run
```

The script will:
- Detect your architecture (ARM64 or AMD64)
- Check available RAM
- Suggest the optimal configuration
- Deploy with the appropriate compose file

### Option 2: Manual Configuration

```bash
# Raspberry Pi 4 (8GB)
podman-compose -f config/pi4-8gb.yml up -d

# Raspberry Pi 5 (16GB)
podman-compose -f config/pi5-16gb.yml up -d

# AMD64 with 24GB RAM
podman-compose -f config/amd64-24gb.yml up -d

# AMD64 with 32GB+ RAM
podman-compose -f config/amd64-32gb.yml up -d
```

### Option 3: Default Configurations

```bash
# ARM64 (default: optimized for Pi 4/5)
podman-compose up -d

# AMD64
podman-compose -f config/amd64-24gb.yml up -d
```

## 🏗️ Project Structure

```
capability-template/
├── capability.json              # Capability contract (CUSTOMIZE THIS)
├── podman-compose.yml           # Default ARM64 config (Pi 4/5)
│
├── config/                      # Platform-specific configurations
│   ├── pi4-8gb.yml             # Conservative Pi 4 config
│   ├── pi5-16gb.yml            # Pi 5 optimized (16GB)
│   ├── amd64-24gb.yml          # AMD64 with 24GB RAM
│   ├── amd64-32gb.yml          # AMD64 with 32GB+ RAM
│   └── device-constraints.json # Platform capabilities reference
│
├── scripts/                     # Generic automation scripts
│   ├── deploy.sh               # Multi-arch deployment with auto-detection
│   ├── choose-compose.sh        # Preflight: recommends the right preset for your device
│   ├── validate-deployment.sh  # Deployment validation
│   └── health-check.sh         # Quick health verification
│
├── tests/                       # Testing framework
│   ├── test-api.sh             # API tests
│   ├── test-performance.sh     # Architecture-aware performance tests
│   └── README.md               # Testing documentation
│
└── docs/                        # Comprehensive documentation
    ├── README.md               # Documentation index
    ├── architecture.md         # eZansiEdgeAI architecture overview
    ├── capability-contract-spec.md  # Contract specification
    ├── performance-tuning.md   # Optimization guide
    ├── troubleshooting.md      # Platform-specific troubleshooting
    ├── deployment-guide.md     # General deployment strategies
    └── deployment-guide-amd64.md    # AMD64-specific guide
```

## 🔍 Health Checks & Monitoring

### Quick Health Check

```bash
./scripts/health-check.sh
```

### View Logs

```bash
# Follow logs
podman logs -f {{CAPABILITY_NAME}}-capability

# Last 100 lines
podman logs --tail 100 {{CAPABILITY_NAME}}-capability
```

### Resource Monitoring

```bash
# Live stats
podman stats {{CAPABILITY_NAME}}-capability

# One-time snapshot
podman stats --no-stream {{CAPABILITY_NAME}}-capability
```

## 🛠️ Troubleshooting

### Container Won't Start

```bash
# Check container status
podman ps -a

# View logs
podman logs {{CAPABILITY_NAME}}-capability

# Check resource limits
podman inspect {{CAPABILITY_NAME}}-capability | jq '.HostConfig'
```

### Health Check Fails

```bash
# Verify endpoint configuration
jq '.endpoints' capability.json

# Test manually
curl http://localhost:{{PORT}}{{HEALTH_PATH}}

# Check if port is exposed
podman port {{CAPABILITY_NAME}}-capability
```

### Performance Issues

**🍓 ARM64 (Raspberry Pi):**
- Monitor temperature: `vcgencmd measure_temp`
- Check for thermal throttling
- Reduce memory limits if swapping occurs
- Use Pi 5 for better performance

**💻 AMD64:**
- Check CPU usage: `htop`
- Verify resource limits in compose file
- Consider using higher-spec configuration
- Monitor disk I/O: `iotop`

See [docs/troubleshooting.md](docs/troubleshooting.md) for more details.

## 📚 Understanding Capability Contracts

The `capability.json` file is the contract that defines your capability:

```json
{
  "name": "capability-name",
  "provides": ["service-type"],
  "supported_architectures": ["arm64", "amd64"],
  "endpoints": {
    "health": { "path": "/health" },
    "main": { "path": "/api/endpoint" }
  },
  "resources": {
    "ram_mb": 4096,
    "cpu_cores": 2
  }
}
```

All scripts read from this contract, making them reusable across different capability types.

See [docs/capability-contract-spec.md](docs/capability-contract-spec.md) for the full specification.

## 🎓 Helper Scripts Documentation

### `scripts/deploy.sh`

Multi-architecture deployment with automatic platform detection:
- Detects ARM64 vs AMD64
- Checks available RAM
- Suggests optimal configuration
- Deploys with selected compose file

**Usage:** `./scripts/deploy.sh [compose-file]`

### `scripts/validate-deployment.sh`

Comprehensive deployment validation:
- Verifies Podman installation
- Checks container status
- Tests health endpoint
- Validates resource limits
- Shows current resource usage

**Usage:** `./scripts/validate-deployment.sh`

### `scripts/health-check.sh`

Quick health verification:
- Reads endpoint from `capability.json`
- Checks container status
- Tests health endpoint
- Returns JSON response

**Usage:** `./scripts/health-check.sh`

## 🎛️ Device Configurations

### Pi 4 (8GB) - Conservative
- **Memory:** 5GB limit (3GB reserved)
- **CPU:** 4 cores
- **Best for:** Development, testing

### Pi 5 (16GB) - Optimized
- **Memory:** 12GB limit (8GB reserved)
- **CPU:** 4 cores
- **Best for:** Production edge deployment

### AMD64 (24GB) - Moderate
- **Memory:** 18GB limit (12GB reserved)
- **CPU:** 6 cores
- **Best for:** Development workstations

### AMD64 (32GB+) - High Performance
- **Memory:** 28GB limit (20GB reserved)
- **CPU:** 12 cores
- **Best for:** Production servers, heavy workloads

See [config/device-constraints.json](config/device-constraints.json) for detailed specifications.

## 🌐 Multi-Architecture Support

This template supports both ARM64 and AMD64 architectures:

**ARM64 Advantages:**
- Lower power consumption
- Better for edge deployment
- Cost-effective hardware
- Compact form factor

**AMD64 Advantages:**
- Higher raw performance
- More RAM available
- Better for development
- Faster for heavy workloads

Choose your platform based on your deployment needs. All scripts and configurations are architecture-aware.

## 📖 Documentation

- **[Architecture Overview](docs/architecture.md)** - eZansiEdgeAI architecture and design
- **[Capability Contract Spec](docs/capability-contract-spec.md)** - Complete contract specification
- **[Performance Tuning](docs/performance-tuning.md)** - ARM64 vs AMD64 optimization
- **[Troubleshooting](docs/troubleshooting.md)** - Platform-specific troubleshooting
- **[Deployment Guide](docs/deployment-guide.md)** - General deployment strategies
- **[AMD64 Deployment](docs/deployment-guide-amd64.md)** - AMD64-specific guide

## 🤝 Contributing

This is a template repository. To improve the template:

1. Fork this repository
2. Create a feature branch
3. Make your improvements
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🔗 Part of eZansiEdgeAI

This template is part of the [eZansiEdgeAI](https://github.com/eZansiEdgeAI) platform - a modular, composable AI system designed for edge deployment.

**Other eZansiEdgeAI Repositories:**
- [ezansi-capability-llm-ollama](https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama) - LLM capability using Ollama
- More capabilities coming soon...

## 🏷️ Version

**v1.0.0** - Initial multi-architecture template release

See [CHANGELOG.md](CHANGELOG.md) for version history.