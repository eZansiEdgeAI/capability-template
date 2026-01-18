#!/bin/bash
set -e

# validate-deployment.sh - Generic deployment validation script
# Reads configuration from capability.json and validates the deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CAPABILITY_JSON="$PROJECT_ROOT/capability.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Deployment Validation ===${NC}"
echo ""

# Check if capability.json exists
if [ ! -f "$CAPABILITY_JSON" ]; then
    echo -e "${RED}✗ capability.json not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ capability.json found${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}✗ jq is not installed${NC}"
    echo "Install with: sudo apt-get install jq"
    exit 1
fi
echo -e "${GREEN}✓ jq is installed${NC}"

# Read capability configuration
CAPABILITY_NAME=$(jq -r '.name' "$CAPABILITY_JSON")
CONTAINER_IMAGE=$(jq -r '.container.image' "$CAPABILITY_JSON")
PORT=$(jq -r '.container.port' "$CAPABILITY_JSON")
HEALTH_PATH=$(jq -r '.endpoints.health.path' "$CAPABILITY_JSON")

echo -e "Capability: ${GREEN}$CAPABILITY_NAME${NC}"
echo ""

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo -e "${RED}✗ Podman is not installed${NC}"
    echo "Install with: sudo apt-get install podman"
    exit 1
fi
echo -e "${GREEN}✓ Podman is installed${NC}"

# Check if podman-compose is installed
if ! command -v podman-compose &> /dev/null; then
    echo -e "${YELLOW}⚠ podman-compose is not installed (optional)${NC}"
else
    echo -e "${GREEN}✓ podman-compose is installed${NC}"
fi

# Check if container is running
CONTAINER_NAME="${CAPABILITY_NAME}-capability"
if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✓ Container is running: $CONTAINER_NAME${NC}"
else
    echo -e "${RED}✗ Container is not running: $CONTAINER_NAME${NC}"
    echo ""
    echo "Available containers:"
    podman ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    exit 1
fi

# Check container health status
HEALTH_STATUS=$(podman inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Container health status: $HEALTH_STATUS${NC}"
elif [ "$HEALTH_STATUS" = "starting" ]; then
    echo -e "${YELLOW}⚠ Container health status: $HEALTH_STATUS (still initializing)${NC}"
else
    echo -e "${YELLOW}⚠ Container health status: $HEALTH_STATUS${NC}"
fi

# Check if port is accessible
if command -v curl &> /dev/null; then
    HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
    echo -e "Testing health endpoint: ${BLUE}$HEALTH_URL${NC}"
    
    if curl -f -s "$HEALTH_URL" > /dev/null; then
        echo -e "${GREEN}✓ Health endpoint is accessible${NC}"
        
        # Show health response
        HEALTH_RESPONSE=$(curl -s "$HEALTH_URL")
        echo -e "${BLUE}Health response:${NC}"
        echo "$HEALTH_RESPONSE" | jq . 2>/dev/null || echo "$HEALTH_RESPONSE"
    else
        echo -e "${RED}✗ Health endpoint is not accessible${NC}"
        echo "This might be normal if the container is still starting up."
        echo "Check logs with: podman logs $CONTAINER_NAME"
    fi
else
    echo -e "${YELLOW}⚠ curl is not installed; skipping endpoint test${NC}"
fi

# Check resource limits
echo ""
echo -e "${BLUE}Resource Allocation:${NC}"
MEMORY_LIMIT=$(podman inspect "$CONTAINER_NAME" --format='{{.HostConfig.Memory}}' 2>/dev/null || echo "0")
CPU_QUOTA=$(podman inspect "$CONTAINER_NAME" --format='{{.HostConfig.CpuQuota}}' 2>/dev/null || echo "0")

if [ "$MEMORY_LIMIT" -gt 0 ]; then
    MEMORY_GB=$((MEMORY_LIMIT / 1024 / 1024 / 1024))
    echo -e "  Memory limit: ${GREEN}${MEMORY_GB}GB${NC}"
else
    echo -e "  Memory limit: ${YELLOW}unlimited${NC}"
fi

if [ "$CPU_QUOTA" -gt 0 ]; then
    CPU_CORES=$((CPU_QUOTA / 100000))
    echo -e "  CPU limit: ${GREEN}${CPU_CORES} cores${NC}"
else
    echo -e "  CPU limit: ${YELLOW}unlimited${NC}"
fi

# Show current resource usage
echo ""
echo -e "${BLUE}Current Resource Usage:${NC}"
podman stats --no-stream "$CONTAINER_NAME" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo -e "${GREEN}=== Validation Complete ===${NC}"
echo ""
echo "Additional checks:"
echo "  - View logs: podman logs $CONTAINER_NAME"
echo "  - Follow logs: podman logs -f $CONTAINER_NAME"
echo "  - Container details: podman inspect $CONTAINER_NAME"
