#!/bin/bash

# health-check.sh - Quick health verification script
# Reads endpoint configuration from capability.json and checks container health

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CAPABILITY_JSON="$PROJECT_ROOT/capability.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if capability.json exists
if [ ! -f "$CAPABILITY_JSON" ]; then
    echo -e "${RED}Error: capability.json not found${NC}"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    exit 1
fi

# Read capability configuration
CAPABILITY_NAME=$(jq -r '.name' "$CAPABILITY_JSON")
PORT=$(jq -r '.container.port' "$CAPABILITY_JSON")
HEALTH_PATH=$(jq -r '.endpoints.health.path' "$CAPABILITY_JSON")
CONTAINER_NAME="${CAPABILITY_NAME}-capability"

echo -e "${BLUE}=== Health Check: $CAPABILITY_NAME ===${NC}"
echo ""

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}✗ Container is not running${NC}"
    echo ""
    echo "Start the container with:"
    echo "  ./scripts/deploy.sh"
    exit 1
fi

echo -e "${GREEN}✓ Container is running${NC}"

# Check container status
STATUS=$(podman ps --filter "name=^${CONTAINER_NAME}$" --format "{{.Status}}")
echo -e "Status: ${GREEN}$STATUS${NC}"

# Check health endpoint
HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
echo -e "Health endpoint: ${BLUE}$HEALTH_URL${NC}"
echo ""

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Warning: curl is not installed; skipping endpoint test${NC}"
    exit 0
fi

# Perform health check
HTTP_CODE=$(curl -s -o /tmp/health-response.json -w "%{http_code}" "$HEALTH_URL")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Health check passed (HTTP $HTTP_CODE)${NC}"
    echo ""
    echo -e "${BLUE}Response:${NC}"
    cat /tmp/health-response.json | jq . 2>/dev/null || cat /tmp/health-response.json
    echo ""
    rm -f /tmp/health-response.json
    exit 0
else
    echo -e "${RED}✗ Health check failed (HTTP $HTTP_CODE)${NC}"
    echo ""
    if [ -f /tmp/health-response.json ]; then
        echo -e "${BLUE}Response:${NC}"
        cat /tmp/health-response.json
        echo ""
        rm -f /tmp/health-response.json
    fi
    echo "Check container logs with:"
    echo "  podman logs $CONTAINER_NAME"
    exit 1
fi
