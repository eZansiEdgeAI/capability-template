# eZansiEdgeAI Architecture

## Overview

eZansiEdgeAI is a modular, composable AI system designed for edge deployment. The architecture is built on the **LEGO brick philosophy** - small, independent, reusable components that can be combined to create complex AI systems.

## Design Philosophy

### 🧱 The LEGO Brick Metaphor

Just as LEGO bricks are:
- **Self-contained** - Each brick is complete and functional
- **Standardized** - All bricks follow the same connection interface
- **Composable** - Bricks can be combined in countless ways
- **Interchangeable** - Swap bricks without affecting others

eZansiEdgeAI capabilities are:
- **Self-contained** - Each capability runs independently in its own container
- **Standardized** - All capabilities follow the same contract specification
- **Composable** - Capabilities can be combined to create complex workflows
- **Interchangeable** - Swap implementations without breaking the system

### Core Principles

1. **Contract-Driven Design**
   - Every capability exposes a standard `capability.json` contract
   - Contracts define inputs, outputs, and resource requirements
   - Enables discovery and validation

2. **Platform Independence**
   - Works on ARM64 (Raspberry Pi) and AMD64 (x86-64)
   - Same contract, different resource allocations
   - Architecture-aware configurations

3. **Container-First**
   - All capabilities run in Podman/Docker containers
   - Isolation and reproducibility
   - Easy deployment and scaling

4. **Edge-Optimized**
   - Designed for resource-constrained environments
   - Efficient memory and CPU usage
   - Minimal dependencies

## Three-Layer Architecture Model

eZansiEdgeAI follows a three-layer architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     APPLICATION LAYER                        │
│  User applications, workflows, orchestration, UI            │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                    CAPABILITY LAYER                          │
│  Individual capabilities (LLM, STT, TTS, Vision, etc.)      │
│  - Each capability is a container                           │
│  - Exposes standard REST API                                │
│  - Follows capability.json contract                         │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                        │
│  Podman, networking, storage, resource management           │
└─────────────────────────────────────────────────────────────┘
```

### Layer 1: Infrastructure Layer

**Components:**
- Container runtime (Podman/Docker)
- Network configuration
- Volume management
- Resource limits and quotas

**Responsibilities:**
- Container lifecycle management
- Network isolation and routing
- Persistent storage
- Resource allocation

**Platform-Specific:**
- 🍓 ARM64: Optimized for low power, limited RAM
- 💻 AMD64: Higher performance, more resources

### Layer 2: Capability Layer

**Components:**
- Individual capabilities (this template)
- Each capability is a self-contained service
- Standard REST API interface
- Capability contract (`capability.json`)

**Responsibilities:**
- Provide specific AI/ML functionality
- Health monitoring
- Resource management
- API endpoint exposure

**Standard Capability Types:**
- **LLM** - Large Language Models (chat, completion)
- **STT** - Speech-to-Text
- **TTS** - Text-to-Speech
- **Vision** - Image analysis, object detection
- **Retrieval** - Vector search, RAG
- **Custom** - Any other service type

### Layer 3: Application Layer

**Components:**
- User applications
- Workflow orchestration
- UI/UX
- Integration logic

**Responsibilities:**
- Combine capabilities into workflows
- User interaction
- Business logic
- Application-specific features

**Examples:**
- Voice assistant combining STT → LLM → TTS
- Document analysis combining Vision → LLM → Retrieval
- Multi-modal AI applications

## Capability Contract Specification

The capability contract is the **interface** that all capabilities must implement. It's defined in `capability.json`:

### Required Fields

```json
{
  "name": "capability-name",
  "version": "1.0",
  "type": "capability",
  "description": "What this capability does",
  "provides": ["service-type"],
  "requires": [],
  "supported_architectures": ["arm64", "amd64"],
  "endpoints": {
    "health": {
      "method": "GET",
      "path": "/health",
      "output": "application/json"
    },
    "main": {
      "method": "POST",
      "path": "/api/endpoint",
      "input": "application/json",
      "output": "application/json"
    }
  },
  "container": {
    "image": "registry/image:tag",
    "port": 8080,
    "restart_policy": "unless-stopped"
  },
  "resources": {
    "ram_mb": 4096,
    "cpu_cores": 2,
    "storage_mb": 10240
  }
}
```

See [capability-contract-spec.md](capability-contract-spec.md) for the complete specification.

## Multi-Architecture Support

### Design Decisions

**Why Support Multiple Architectures?**

1. **Flexibility** - Deploy on available hardware
2. **Development Workflow** - Develop on AMD64, deploy on ARM64
3. **Cost Optimization** - Use ARM64 for production edge, AMD64 for development
4. **Performance Scaling** - Start on Pi, scale to servers

**How It Works:**

1. **Same Container Image** - Multi-arch images support both platforms
2. **Different Configurations** - Resource limits adjusted per platform
3. **Platform Detection** - Scripts auto-detect architecture
4. **Separate Compose Files** - Platform-specific resource allocations

### Architecture Comparison

| Aspect | ARM64 (Raspberry Pi) | AMD64 (x86-64) |
|--------|---------------------|----------------|
| **Performance** | Lower | Higher |
| **Power** | 5-15W | 50-300W |
| **Cost** | $60-100 | $500-2000+ |
| **RAM** | 4-16GB | 16-128GB+ |
| **Use Case** | Edge, IoT | Development, servers |
| **Latency** | Higher | Lower |
| **Throughput** | Lower | Higher |

### Platform Selection Guide

**Choose ARM64 (Raspberry Pi) when:**
- Deploying at the edge
- Power consumption is critical
- Cost is a constraint
- Physical space is limited
- Moderate performance is acceptable

**Choose AMD64 when:**
- Development and testing
- High performance is required
- Large models or datasets
- High throughput needed
- Server/cloud deployment

## Resource Management

### Memory Allocation Strategy

**General Rule:** Reserve 10-25% of total RAM for the OS and system processes.

**Platform-Specific:**

🍓 **ARM64 (Pi 4 8GB):**
- Total: 8GB
- Container limit: 5GB
- Reservation: 3GB
- Headroom: 3GB for OS

🍓 **ARM64 (Pi 5 16GB):**
- Total: 16GB
- Container limit: 12GB
- Reservation: 8GB
- Headroom: 4GB for OS

💻 **AMD64 (24GB):**
- Total: 24GB
- Container limit: 18GB
- Reservation: 12GB
- Headroom: 6GB for OS

💻 **AMD64 (32GB+):**
- Total: 32GB+
- Container limit: 28GB
- Reservation: 20GB
- Headroom: 4GB+ for OS

### CPU Allocation Strategy

**Conservative Approach:**
- Start with 50% of available cores
- Monitor actual usage
- Increase if needed
- Avoid overcommitting

**Platform-Specific:**

🍓 **ARM64:**
- Pi 4/5: 4 cores total → allocate all 4
- Limited by single-thread performance

💻 **AMD64:**
- 6-8 cores: allocate 4-6
- 12-16 cores: allocate 8-12
- Scale based on workload

## Networking Architecture

### Container Networking

**Default Setup:**
- Host port mapping (e.g., 8080:8080)
- Container-to-container communication via host network
- No custom networks required (simplicity)

**Advanced Setup:**
- Create Podman network for capability isolation
- Use service discovery
- Internal routing between capabilities

### Endpoint Design

**Standard Endpoints:**

1. **Health Endpoint** (`/health`)
   - GET request
   - Returns JSON health status
   - Used for container health checks
   - Must be fast (< 100ms)

2. **Main Endpoint** (capability-specific)
   - POST request (usually)
   - JSON input/output
   - Capability-specific functionality
   - Can be slower (depends on task)

## Storage Architecture

### Volume Management

**Pattern:**
```yaml
volumes:
  capability-data:/data
```

**Best Practices:**
- Use named volumes for persistence
- Mount at `/data` inside container
- Store models, cache, state
- Platform-independent paths

**Platform Considerations:**

🍓 **ARM64:**
- SD card I/O can be slow
- Use high-quality SD cards (UHS-I or better)
- Consider USB SSD for better performance
- Monitor disk space (limited capacity)

💻 **AMD64:**
- SSD recommended
- NVMe for best performance
- More capacity available
- Faster I/O

## API Design

### REST API Principles

1. **Stateless** - Each request is independent
2. **JSON** - Standard data format
3. **HTTP Status Codes** - Proper error handling
4. **Versioned** - API version in contract
5. **Documented** - Clear endpoint specifications

### Standard Response Format

**Success (200 OK):**
```json
{
  "status": "success",
  "data": {
    "result": "..."
  }
}
```

**Error (4xx/5xx):**
```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

## Testing Strategy

### Test Levels

1. **Health Tests** - Container and endpoint availability
2. **API Tests** - Functional correctness
3. **Performance Tests** - Platform-specific benchmarks
4. **Integration Tests** - Multi-capability workflows

### Platform-Aware Testing

Tests adjust expectations based on detected architecture:

🍓 **ARM64 Expectations:**
- Higher latency (< 500ms)
- Lower throughput
- Fewer concurrent requests

💻 **AMD64 Expectations:**
- Lower latency (< 200ms)
- Higher throughput
- More concurrent requests

## Future Enhancements

### Planned Features

1. **Service Discovery**
   - Automatic capability registration
   - Dynamic endpoint discovery
   - Load balancing

2. **Orchestration**
   - Multi-capability workflows
   - Pipeline definitions
   - Event-driven architecture

3. **Monitoring**
   - Centralized logging
   - Metrics collection
   - Performance dashboards

4. **Security**
   - Authentication/authorization
   - API key management
   - TLS/HTTPS support

### Extensibility Points

1. **Custom Service Types** - Add new capability types beyond LLM/STT/TTS
2. **Additional Platforms** - Support for other architectures (ARM32, RISC-V)
3. **Alternative Runtimes** - Support for Docker, Kubernetes
4. **Cloud Integration** - Hybrid edge-cloud deployments

## Design Trade-offs

### Simplicity vs. Features

**Chosen:** Simplicity
- Single-container capabilities
- No complex orchestration required
- Easy to understand and deploy
- Trade-off: Manual workflow composition

### Performance vs. Portability

**Chosen:** Portability
- Same code on ARM64 and AMD64
- Multi-arch images
- Platform-specific configurations
- Trade-off: Not maximally optimized for any single platform

### Flexibility vs. Standardization

**Chosen:** Standardization
- Strict capability contract
- Standard endpoints and formats
- Predictable behavior
- Trade-off: Less flexibility in API design

## Best Practices

1. **Follow the Contract** - Implement all required endpoints
2. **Platform Testing** - Test on both ARM64 and AMD64
3. **Resource Awareness** - Respect resource limits
4. **Health Monitoring** - Implement robust health checks
5. **Error Handling** - Return proper HTTP status codes
6. **Documentation** - Document capability-specific features
7. **Logging** - Use structured logging
8. **Graceful Shutdown** - Handle SIGTERM properly

## Summary

eZansiEdgeAI's architecture is built on:
- **🧱 LEGO brick philosophy** - Composable, standardized capabilities
- **📜 Contract-driven design** - Standard interfaces and discovery
- **🌐 Multi-architecture** - ARM64 and AMD64 support
- **🐳 Container-first** - Isolation and portability
- **⚡ Edge-optimized** - Efficient resource usage

This architecture enables building complex AI systems from simple, reusable components that work across different hardware platforms.

---

**Next Steps:**
- Read [Capability Contract Specification](capability-contract-spec.md)
- Review [Performance Tuning Guide](performance-tuning.md)
- Check [Deployment Guide](deployment-guide.md)
