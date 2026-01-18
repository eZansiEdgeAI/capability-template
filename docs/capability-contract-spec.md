# Capability Contract Specification

## Overview

The capability contract is a JSON document (`capability.json`) that defines the interface, requirements, and metadata for an eZansiEdgeAI capability. It serves as the **single source of truth** for capability discovery, validation, and deployment.

## Schema Version

**Current Version:** 1.0

## Complete Schema

```json
{
  "name": "string (required)",
  "version": "string (required)",
  "type": "string (required, must be 'capability')",
  "description": "string (required)",
  "provides": ["array of strings (required)"],
  "requires": ["array of strings (optional)"],
  "target_platforms": ["array of strings (required)"],
  "supported_architectures": ["array of strings (required)"],
  "resources": {
    "ram_mb": "number (required)",
    "cpu_cores": "number (required)",
    "storage_mb": "number (required)",
    "accelerator": "string (optional)"
  },
  "endpoints": {
    "health": {
      "method": "string (required)",
      "path": "string (required)",
      "input": "string (required)",
      "output": "string (required)"
    },
    "main": {
      "method": "string (required)",
      "path": "string (required)",
      "input": "string (required)",
      "output": "string (required)"
    }
  },
  "container": {
    "image": "string (required)",
    "port": "number (required)",
    "restart_policy": "string (required)"
  },
  "notes": "string (optional)"
}
```

## Field Specifications

### Top-Level Fields

#### `name` (required)
- **Type:** String
- **Format:** Lowercase, hyphen-separated
- **Pattern:** `^[a-z][a-z0-9-]*$`
- **Example:** `"my-awesome-capability"`
- **Description:** Unique identifier for the capability
- **Notes:** Used in container names, volume names, and deployment scripts

#### `version` (required)
- **Type:** String
- **Format:** Semantic versioning (semver)
- **Pattern:** `^\d+\.\d+(\.\d+)?$`
- **Example:** `"1.0"`, `"1.2.3"`
- **Description:** Capability version
- **Notes:** Should follow [Semantic Versioning](https://semver.org/)

#### `type` (required)
- **Type:** String
- **Allowed Values:** `"capability"`
- **Description:** Resource type identifier
- **Notes:** Must be exactly `"capability"` for validation

#### `description` (required)
- **Type:** String
- **Max Length:** 200 characters (recommended)
- **Example:** `"LLM capability using Ollama for text generation and chat"`
- **Description:** Human-readable description of what the capability does
- **Notes:** Keep concise and clear

#### `provides` (required)
- **Type:** Array of strings
- **Min Length:** 1
- **Example:** `["llm", "chat", "completion"]`
- **Description:** Service types this capability provides
- **Notes:** See [Standard Service Types](#standard-service-types) below

#### `requires` (optional)
- **Type:** Array of strings
- **Default:** `[]`
- **Example:** `["vector-db", "preprocessing"]`
- **Description:** Other capabilities this one depends on
- **Notes:** Used for dependency validation

#### `target_platforms` (required)
- **Type:** Array of strings
- **Example:** `["Raspberry Pi 4/5 (ARM64)", "AMD64 Linux (24GB+)"]`
- **Description:** Human-readable target platforms
- **Notes:** Informational, not validated

#### `supported_architectures` (required)
- **Type:** Array of strings
- **Allowed Values:** `"arm64"`, `"amd64"`, `"arm"`, `"arm/v7"`, `"ppc64le"`, `"s390x"`
- **Example:** `["arm64", "amd64"]`
- **Description:** CPU architectures this capability supports
- **Notes:** Must match `uname -m` output (arm64/aarch64, x86_64/amd64)

### Resources Section

#### `resources` (required)
Container resource requirements.

##### `resources.ram_mb` (required)
- **Type:** Number
- **Unit:** Megabytes
- **Example:** `4096` (4GB)
- **Description:** Minimum RAM required
- **Notes:** Used for validation and recommendations

##### `resources.cpu_cores` (required)
- **Type:** Number
- **Example:** `2`
- **Description:** Minimum CPU cores required
- **Notes:** Can be fractional (e.g., `0.5` for half a core)

##### `resources.storage_mb` (required)
- **Type:** Number
- **Unit:** Megabytes
- **Example:** `10240` (10GB)
- **Description:** Minimum storage space required
- **Notes:** Includes container image + data

##### `resources.accelerator` (optional)
- **Type:** String
- **Allowed Values:** `"none"`, `"gpu"`, `"npu"`, `"tpu"`
- **Default:** `"none"`
- **Example:** `"gpu"`
- **Description:** Hardware accelerator requirement
- **Notes:** Future feature, not currently validated

### Endpoints Section

#### `endpoints` (required)
API endpoint definitions.

##### `endpoints.health` (required)
Health check endpoint specification.

- **`method`** (required): HTTP method, typically `"GET"`
- **`path`** (required): URL path, e.g., `"/health"`
- **`input`** (required): Input format, `"none"` for GET
- **`output`** (required): Output format, typically `"application/json"`

**Example:**
```json
{
  "method": "GET",
  "path": "/health",
  "input": "none",
  "output": "application/json"
}
```

**Health Response Format:**
```json
{
  "status": "healthy",
  "service": "capability-name",
  "version": "1.0",
  "timestamp": "2024-01-18T12:00:00Z"
}
```

##### `endpoints.main` (required)
Primary capability endpoint specification.

- **`method`** (required): HTTP method, typically `"POST"`
- **`path`** (required): URL path, e.g., `"/api/generate"`
- **`input`** (required): Input format, typically `"application/json"`
- **`output`** (required): Output format, typically `"application/json"`

**Example:**
```json
{
  "method": "POST",
  "path": "/api/generate",
  "input": "application/json",
  "output": "application/json"
}
```

##### Additional Endpoints (optional)
You can define additional endpoints beyond `health` and `main`:

```json
{
  "endpoints": {
    "health": { ... },
    "main": { ... },
    "models": {
      "method": "GET",
      "path": "/api/models",
      "input": "none",
      "output": "application/json"
    }
  }
}
```

### Container Section

#### `container` (required)
Container deployment configuration.

##### `container.image` (required)
- **Type:** String
- **Format:** `registry/repository:tag` or `repository:tag`
- **Example:** `"docker.io/ollama/ollama:latest"`
- **Description:** Container image reference
- **Notes:** Should support multi-arch if `supported_architectures` has multiple values

##### `container.port` (required)
- **Type:** Number
- **Range:** 1-65535
- **Example:** `11434`
- **Description:** Primary service port
- **Notes:** Must match the port the service listens on inside the container

##### `container.restart_policy` (required)
- **Type:** String
- **Allowed Values:** `"no"`, `"always"`, `"unless-stopped"`, `"on-failure"`
- **Default:** `"unless-stopped"` (recommended)
- **Description:** Container restart policy
- **Notes:** See [Podman restart policies](https://docs.podman.io/en/latest/markdown/podman-run.1.html#restart)

## Standard Service Types

The `provides` field should use standard service type identifiers when applicable:

### AI/ML Services

| Service Type | Description | Example Use Case |
|--------------|-------------|------------------|
| `llm` | Large Language Model | Text generation, chat |
| `stt` | Speech-to-Text | Audio transcription |
| `tts` | Text-to-Speech | Voice synthesis |
| `vision` | Computer Vision | Image analysis, object detection |
| `ocr` | Optical Character Recognition | Text extraction from images |
| `embedding` | Text/Image Embeddings | Semantic search, similarity |
| `retrieval` | Retrieval/Search | Vector search, RAG |
| `classification` | Classification | Text/image categorization |
| `translation` | Language Translation | Multi-language support |
| `summarization` | Text Summarization | Document summarization |

### Supporting Services

| Service Type | Description | Example Use Case |
|--------------|-------------|------------------|
| `preprocessing` | Data Preprocessing | Text cleaning, normalization |
| `postprocessing` | Data Postprocessing | Format conversion, filtering |
| `vector-db` | Vector Database | Embedding storage |
| `cache` | Caching Service | Response caching |
| `queue` | Message Queue | Async processing |

### Custom Service Types

If none of the standard types fit, use a descriptive custom type:
- Use lowercase, hyphen-separated format
- Be specific but not overly verbose
- Example: `"sentiment-analysis"`, `"named-entity-recognition"`

## Validation Rules

### Required Fields Validation

All required fields must be present:
```bash
# Validate with jq
jq -e '.name and .version and .type and .description and .provides and .supported_architectures and .resources and .endpoints and .container' capability.json
```

### Name Validation

```bash
# Name must be lowercase with hyphens
jq -e '.name | test("^[a-z][a-z0-9-]*$")' capability.json
```

### Architecture Validation

```bash
# At least one architecture must be specified
jq -e '.supported_architectures | length > 0' capability.json
```

### Port Validation

```bash
# Port must be in valid range
jq -e '.container.port >= 1 and .container.port <= 65535' capability.json
```

### Endpoint Validation

```bash
# Health endpoint must exist
jq -e '.endpoints.health' capability.json

# Main endpoint must exist
jq -e '.endpoints.main' capability.json
```

## Multi-Architecture Fields

For multi-architecture support, ensure:

1. **`supported_architectures`** lists all supported architectures
2. **`container.image`** is a multi-arch image or has per-arch variants
3. **`resources`** values are reasonable for all architectures

### Platform-Specific Resource Recommendations

**ARM64 (Raspberry Pi):**
```json
{
  "resources": {
    "ram_mb": 2048,      // Conservative for 8GB Pi
    "cpu_cores": 2,       // Half of available cores
    "storage_mb": 5120    // 5GB
  }
}
```

**AMD64:**
```json
{
  "resources": {
    "ram_mb": 8192,      // More generous
    "cpu_cores": 4,       // More cores available
    "storage_mb": 20480   // 20GB
  }
}
```

**Note:** Use the lower values for multi-arch templates to ensure compatibility.

## Example Contracts

### Minimal Example

```json
{
  "name": "hello-capability",
  "version": "1.0",
  "type": "capability",
  "description": "A simple hello world capability",
  "provides": ["custom"],
  "requires": [],
  "target_platforms": ["Raspberry Pi 4/5 (ARM64)", "AMD64 Linux"],
  "supported_architectures": ["arm64", "amd64"],
  "resources": {
    "ram_mb": 512,
    "cpu_cores": 1,
    "storage_mb": 1024,
    "accelerator": "none"
  },
  "endpoints": {
    "health": {
      "method": "GET",
      "path": "/health",
      "input": "none",
      "output": "application/json"
    },
    "main": {
      "method": "POST",
      "path": "/api/hello",
      "input": "application/json",
      "output": "application/json"
    }
  },
  "container": {
    "image": "myregistry/hello:latest",
    "port": 8080,
    "restart_policy": "unless-stopped"
  }
}
```

### Complete Example (LLM)

```json
{
  "name": "llm-ollama",
  "version": "1.0",
  "type": "capability",
  "description": "LLM capability using Ollama for text generation and chat",
  "provides": ["llm", "chat", "completion", "embedding"],
  "requires": [],
  "target_platforms": [
    "Raspberry Pi 4/5 (ARM64)",
    "AMD64 Linux (24GB+)"
  ],
  "supported_architectures": ["arm64", "amd64"],
  "resources": {
    "ram_mb": 4096,
    "cpu_cores": 2,
    "storage_mb": 10240,
    "accelerator": "none"
  },
  "endpoints": {
    "health": {
      "method": "GET",
      "path": "/",
      "input": "none",
      "output": "text/plain"
    },
    "main": {
      "method": "POST",
      "path": "/api/generate",
      "input": "application/json",
      "output": "application/json"
    },
    "chat": {
      "method": "POST",
      "path": "/api/chat",
      "input": "application/json",
      "output": "application/json"
    },
    "models": {
      "method": "GET",
      "path": "/api/tags",
      "input": "none",
      "output": "application/json"
    }
  },
  "container": {
    "image": "docker.io/ollama/ollama:latest",
    "port": 11434,
    "restart_policy": "unless-stopped"
  },
  "notes": "Requires model to be pulled after deployment. See documentation for model management."
}
```

## Usage in Scripts

All deployment and validation scripts read from `capability.json`:

### Reading Values

```bash
# Read capability name
NAME=$(jq -r '.name' capability.json)

# Read port
PORT=$(jq -r '.container.port' capability.json)

# Read health endpoint
HEALTH_PATH=$(jq -r '.endpoints.health.path' capability.json)

# Read supported architectures
ARCHS=$(jq -r '.supported_architectures[]' capability.json)
```

### Validation

```bash
# Check if file exists and is valid JSON
if ! jq empty capability.json 2>/dev/null; then
    echo "Invalid capability.json"
    exit 1
fi

# Validate required fields
if [ "$(jq -r '.name' capability.json)" = "null" ]; then
    echo "Missing required field: name"
    exit 1
fi
```

## Best Practices

1. **Keep it accurate** - Contract should match actual implementation
2. **Be specific** - Use precise values for resources
3. **Document everything** - Use the `notes` field for important information
4. **Use standards** - Follow standard service types when possible
5. **Test validation** - Validate contract with `jq` before deployment
6. **Version properly** - Update version when contract changes
7. **Multi-arch aware** - Ensure resources work on all supported architectures

## Contract Evolution

### Version 1.0 → 1.1 (Future)

Potential additions:
- **Dependencies:** More structured `requires` with version constraints
- **Configuration:** Environment variable schemas
- **Metrics:** Exposed metrics endpoints
- **Events:** Event emission specifications
- **Security:** Authentication/authorization requirements

### Backwards Compatibility

When the contract specification evolves:
- Required fields will NOT be removed
- New optional fields may be added
- Scripts will ignore unknown fields
- Version field indicates which spec version is used

## Validation Tool

Create a validation script `scripts/validate-contract.sh`:

```bash
#!/bin/bash
# Validate capability.json against spec

REQUIRED_FIELDS=(
    "name"
    "version"
    "type"
    "description"
    "provides"
    "supported_architectures"
    "resources.ram_mb"
    "resources.cpu_cores"
    "resources.storage_mb"
    "endpoints.health"
    "endpoints.main"
    "container.image"
    "container.port"
    "container.restart_policy"
)

for field in "${REQUIRED_FIELDS[@]}"; do
    if [ "$(jq -r ".$field" capability.json)" = "null" ]; then
        echo "❌ Missing required field: $field"
        exit 1
    fi
done

echo "✅ capability.json is valid"
```

## Summary

The capability contract:
- **Standardizes** capability interfaces
- **Enables** automated deployment and validation
- **Documents** requirements and capabilities
- **Supports** multi-architecture deployment
- **Provides** service discovery metadata

All capabilities must implement a valid contract for integration with the eZansiEdgeAI platform.

---

**See Also:**
- [Architecture Overview](architecture.md)
- [Deployment Guide](deployment-guide.md)
- [Example Capabilities](https://github.com/eZansiEdgeAI)
