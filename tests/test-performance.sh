#!/bin/bash

# test-performance.sh - Architecture-aware performance tests
# Detects platform and measures performance with platform-specific expectations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CAPABILITY_JSON="$PROJECT_ROOT/capability.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Performance Tests ===${NC}"
echo ""

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required${NC}"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
echo -e "Architecture: ${GREEN}$ARCH${NC}"

# Set platform-specific expectations
case "$ARCH" in
    aarch64|arm64)
        PLATFORM="ARM64"
        EXPECTED_RESPONSE_TIME=500  # ms
        CONCURRENT_REQUESTS=5
        echo -e "Platform: ${GREEN}$PLATFORM (Raspberry Pi)${NC}"
        ;;
    x86_64|amd64)
        PLATFORM="AMD64"
        EXPECTED_RESPONSE_TIME=200  # ms
        CONCURRENT_REQUESTS=10
        echo -e "Platform: ${GREEN}$PLATFORM${NC}"
        ;;
    *)
        echo -e "${YELLOW}Warning: Unknown architecture $ARCH${NC}"
        PLATFORM="Unknown"
        EXPECTED_RESPONSE_TIME=1000
        CONCURRENT_REQUESTS=5
        ;;
esac
echo ""

# Read configuration
CAPABILITY_NAME=$(jq -r '.name' "$CAPABILITY_JSON")
PORT=$(jq -r '.container.port' "$CAPABILITY_JSON")
HEALTH_PATH=$(jq -r '.endpoints.health.path' "$CAPABILITY_JSON")
CONTAINER_NAME="${CAPABILITY_NAME}-capability"

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}✗ Container is not running${NC}"
    exit 1
fi

HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"

# Test 1: Single request latency
echo -e "${BLUE}Test 1: Single Request Latency${NC}"
TOTAL_TIME=0
ITERATIONS=10

for i in $(seq 1 $ITERATIONS); do
    START_TIME=$(date +%s%N)
    curl -s -o /dev/null "$HEALTH_URL"
    END_TIME=$(date +%s%N)
    RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
    TOTAL_TIME=$((TOTAL_TIME + RESPONSE_TIME))
    echo -e "  Request $i: ${RESPONSE_TIME}ms"
done

AVG_TIME=$((TOTAL_TIME / ITERATIONS))
echo -e "Average: ${GREEN}${AVG_TIME}ms${NC}"
echo -e "Expected: ${BLUE}< ${EXPECTED_RESPONSE_TIME}ms for $PLATFORM${NC}"

if [ $AVG_TIME -lt $EXPECTED_RESPONSE_TIME ]; then
    echo -e "${GREEN}✓ Performance meets expectations${NC}"
else
    echo -e "${YELLOW}⚠ Performance below expectations${NC}"
fi
echo ""

# Test 2: Concurrent requests
echo -e "${BLUE}Test 2: Concurrent Requests${NC}"
echo -e "Sending $CONCURRENT_REQUESTS concurrent requests..."

START_TIME=$(date +%s%N)
for i in $(seq 1 $CONCURRENT_REQUESTS); do
    curl -s -o /dev/null "$HEALTH_URL" &
done
wait
END_TIME=$(date +%s%N)

CONCURRENT_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
echo -e "Total time: ${GREEN}${CONCURRENT_TIME}ms${NC}"
echo -e "Requests: ${GREEN}$CONCURRENT_REQUESTS${NC}"
echo -e "Average per request: ${GREEN}$((CONCURRENT_TIME / CONCURRENT_REQUESTS))ms${NC}"
echo ""

# Test 3: Resource usage
echo -e "${BLUE}Test 3: Resource Usage${NC}"
echo -e "${BLUE}Current resource usage:${NC}"
podman stats --no-stream "$CONTAINER_NAME" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""

# Platform-specific metrics
echo -e "${BLUE}=== Platform-Specific Metrics ===${NC}"
case "$PLATFORM" in
    ARM64)
        echo -e "🍓 ARM64 Performance Notes:"
        echo "  - ARM64 typically has higher latency than AMD64"
        echo "  - Focus on power efficiency over raw speed"
        echo "  - Monitor temperature: vcgencmd measure_temp (on Raspberry Pi)"
        ;;
    AMD64)
        echo -e "💻 AMD64 Performance Notes:"
        echo "  - AMD64 typically has lower latency and higher throughput"
        echo "  - Can handle more concurrent requests"
        echo "  - Monitor system load: uptime"
        ;;
esac
echo ""

# Summary
echo -e "${GREEN}=== Performance Test Complete ===${NC}"
echo ""
echo "Additional monitoring:"
echo "  - Live stats: podman stats $CONTAINER_NAME"
echo "  - Container logs: podman logs $CONTAINER_NAME"
echo "  - System metrics: htop or top"
