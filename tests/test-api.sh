#!/bin/bash

# test-api.sh - Generic API tests
# Reads endpoints from capability.json and performs basic API testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CAPABILITY_JSON="$PROJECT_ROOT/capability.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== API Tests ===${NC}"
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

# Check if capability.json exists
if [ ! -f "$CAPABILITY_JSON" ]; then
    echo -e "${RED}Error: capability.json not found${NC}"
    exit 1
fi

# Read configuration
CAPABILITY_NAME=$(jq -r '.name' "$CAPABILITY_JSON")
PORT=$(jq -r '.container.port' "$CAPABILITY_JSON")
HEALTH_PATH=$(jq -r '.endpoints.health.path' "$CAPABILITY_JSON")
MAIN_PATH=$(jq -r '.endpoints.main.path' "$CAPABILITY_JSON")
CONTAINER_NAME="${CAPABILITY_NAME}-capability"

echo -e "Testing: ${GREEN}$CAPABILITY_NAME${NC}"
echo -e "Port: ${GREEN}$PORT${NC}"
echo ""

# Check if container is running
if ! podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}✗ Container is not running${NC}"
    echo "Start it with: ./scripts/deploy.sh"
    exit 1
fi

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Health endpoint
echo -e "${BLUE}Test 1: Health endpoint${NC}"
HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
HTTP_CODE=$(curl -s -o /tmp/test-health.json -w "%{http_code}" "$HEALTH_URL")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Health endpoint returned HTTP 200${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Check if response is valid JSON
    if jq . /tmp/test-health.json > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Health endpoint returned valid JSON${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Health endpoint did not return valid JSON${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}✗ Health endpoint returned HTTP $HTTP_CODE${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 2))
fi
rm -f /tmp/test-health.json
echo ""

# Test 2: Main endpoint (capability-specific)
echo -e "${BLUE}Test 2: Main endpoint${NC}"
echo -e "${YELLOW}Note: This is a placeholder test. Customize for your capability.${NC}"
MAIN_URL="http://localhost:${PORT}${MAIN_PATH}"
echo -e "Endpoint: $MAIN_URL"

# Example test payload (customize this for your capability)
TEST_PAYLOAD='{"test": "placeholder"}'
HTTP_CODE=$(curl -s -o /tmp/test-main.json -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$TEST_PAYLOAD" \
    "$MAIN_URL")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "422" ]; then
    echo -e "${YELLOW}⚠ Main endpoint returned HTTP $HTTP_CODE (expected for placeholder test)${NC}"
    echo -e "${BLUE}Customize this test with real payload for your capability${NC}"
else
    echo -e "${YELLOW}⚠ Main endpoint returned HTTP $HTTP_CODE${NC}"
fi
rm -f /tmp/test-main.json
echo ""

# Test 3: Response time
echo -e "${BLUE}Test 3: Response time${NC}"
START_TIME=$(date +%s%N)
curl -s -o /dev/null "$HEALTH_URL"
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))

echo -e "Response time: ${GREEN}${RESPONSE_TIME}ms${NC}"
if [ $RESPONSE_TIME -lt 1000 ]; then
    echo -e "${GREEN}✓ Response time is acceptable (< 1s)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠ Response time is high (> 1s)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests failed${NC}"
    exit 1
fi
