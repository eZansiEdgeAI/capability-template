# Testing Documentation

This directory contains test scripts for validating the capability deployment and performance.

## Test Scripts

### `test-api.sh` - API Tests
Generic API testing script that validates:
- Health endpoint accessibility
- JSON response validity
- Response times
- Main endpoint availability

**Usage:**
```bash
./tests/test-api.sh
```

**Requirements:**
- Container must be running (`./scripts/deploy.sh`)
- `curl` and `jq` must be installed

**Customization:**
The script reads endpoint configuration from `capability.json`. Customize the main endpoint test with your capability-specific payload and validation logic.

### `test-performance.sh` - Performance Tests
Architecture-aware performance testing that:
- Detects platform (ARM64 vs AMD64)
- Measures single request latency
- Tests concurrent request handling
- Reports resource usage
- Provides platform-specific performance expectations

**Usage:**
```bash
./tests/test-performance.sh
```

**Platform Expectations:**
- **ARM64 (Raspberry Pi):** < 500ms response time, 5 concurrent requests
- **AMD64:** < 200ms response time, 10 concurrent requests

## Environment Variables

You can customize test behavior with environment variables:

```bash
# Override test endpoints (reads from capability.json by default)
export TEST_PORT=8080
export TEST_HOST=localhost

# Adjust performance test parameters
export PERF_ITERATIONS=20           # Number of single request tests (default: 10)
export PERF_CONCURRENT=15           # Number of concurrent requests (default: platform-specific)
export PERF_EXPECTED_TIME=300       # Expected response time in ms (default: platform-specific)
```

## Test Workflow

### 1. Basic Health Check
```bash
# Quick health verification
./scripts/health-check.sh
```

### 2. API Validation
```bash
# Run API tests
./tests/test-api.sh
```

### 3. Performance Benchmarking
```bash
# Run performance tests
./tests/test-performance.sh
```

### 4. Full Validation
```bash
# Complete deployment validation
./scripts/validate-deployment.sh
```

## Continuous Integration

For CI/CD pipelines, combine all tests:

```bash
#!/bin/bash
set -e

# Deploy
./scripts/deploy.sh

# Wait for startup
sleep 10

# Run tests
./scripts/health-check.sh
./tests/test-api.sh
./tests/test-performance.sh
./scripts/validate-deployment.sh

echo "All tests passed!"
```

## Adding Custom Tests

To add capability-specific tests:

1. **Copy a template:**
   ```bash
   cp tests/test-api.sh tests/test-custom.sh
   ```

2. **Modify for your capability:**
   - Update test payloads
   - Add capability-specific assertions
   - Adjust expected responses

3. **Make it executable:**
   ```bash
   chmod +x tests/test-custom.sh
   ```

4. **Read from capability.json:**
   ```bash
   ENDPOINT=$(jq -r '.endpoints.custom.path' capability.json)
   ```

## Troubleshooting

### Tests fail with "Container not running"
```bash
# Check container status
podman ps -a

# Start the container
./scripts/deploy.sh

# Check logs
podman logs {{CAPABILITY_NAME}}-capability
```

### Tests fail with "Connection refused"
```bash
# Verify the container is healthy
./scripts/health-check.sh

# Check if the port is correct in capability.json
jq '.container.port' capability.json

# Check if the container port is exposed
podman port {{CAPABILITY_NAME}}-capability
```

### Performance tests show poor results
- **ARM64:** This is normal; ARM has lower performance than AMD64
- **AMD64:** Check system resources with `htop`
- **Both:** Review container resource limits in the compose file
- **Both:** Check logs for errors: `podman logs {{CAPABILITY_NAME}}-capability`

## Platform-Specific Notes

### 🍓 ARM64 (Raspberry Pi)
- Expect higher latency than AMD64
- Monitor temperature: `vcgencmd measure_temp`
- Reduce concurrent requests if thermal throttling occurs
- Use Pi 5 configs for better performance

### 💻 AMD64
- Can handle higher concurrency
- Monitor CPU usage with `htop`
- Adjust resource limits in `podman-compose.amd64.yml`
- Consider using higher-spec config files

## Best Practices

1. **Always run health check first** before other tests
2. **Run tests sequentially** to avoid resource contention
3. **Monitor container logs** during test runs
4. **Adjust expectations** based on your platform
5. **Customize tests** for your specific capability requirements
6. **Document test results** for performance baseline
