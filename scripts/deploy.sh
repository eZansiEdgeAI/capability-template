#!/bin/bash
set -e

# deploy.sh - Multi-architecture deployment script
# Automatically detects platform and deploys with appropriate configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CAPABILITY_JSON="$PROJECT_ROOT/capability.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== eZansiEdgeAI Capability Deployment ===${NC}"
echo ""

# Check if capability.json exists
if [ ! -f "$CAPABILITY_JSON" ]; then
    echo -e "${RED}Error: capability.json not found at $CAPABILITY_JSON${NC}"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    echo "Install with: sudo apt-get install jq"
    exit 1
fi

# Read capability name from capability.json
CAPABILITY_NAME=$(jq -r '.name' "$CAPABILITY_JSON")
echo -e "Capability: ${GREEN}$CAPABILITY_NAME${NC}"

# Detect architecture
ARCH=$(uname -m)
echo -e "Architecture: ${GREEN}$ARCH${NC}"

# Detect available RAM (in GB)
if [ -f /proc/meminfo ]; then
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_GB=$((RAM_KB / 1024 / 1024))
    echo -e "Available RAM: ${GREEN}${RAM_GB}GB${NC}"
else
    echo -e "${YELLOW}Warning: Could not detect RAM${NC}"
    RAM_GB=0
fi

# Suggest appropriate compose file based on platform
COMPOSE_FILE=""
case "$ARCH" in
    aarch64|arm64)
        if [ $RAM_GB -ge 14 ]; then
            COMPOSE_FILE="podman-compose.pi5.yml"
            echo -e "${GREEN}Detected: Raspberry Pi 5 (16GB)${NC}"
        elif [ $RAM_GB -ge 7 ]; then
            COMPOSE_FILE="podman-compose.yml"
            echo -e "${GREEN}Detected: Raspberry Pi 4 (8GB)${NC}"
        else
            COMPOSE_FILE="config/pi4-8gb.yml"
            echo -e "${YELLOW}Detected: ARM64 with limited RAM (using conservative config)${NC}"
        fi
        ;;
    x86_64|amd64)
        if [ $RAM_GB -ge 30 ]; then
            COMPOSE_FILE="podman-compose.amd64.yml"
            echo -e "${GREEN}Detected: AMD64 (32GB+)${NC}"
            echo -e "${BLUE}Note: For even better performance, consider config/amd64-32gb.yml${NC}"
        elif [ $RAM_GB -ge 22 ]; then
            COMPOSE_FILE="podman-compose.amd64.yml"
            echo -e "${GREEN}Detected: AMD64 (24GB)${NC}"
        else
            COMPOSE_FILE="podman-compose.amd64.yml"
            echo -e "${YELLOW}Detected: AMD64 with limited RAM (using default config)${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

# Allow user to override compose file
if [ -n "$1" ]; then
    COMPOSE_FILE="$1"
    echo -e "${YELLOW}Using user-specified config: $COMPOSE_FILE${NC}"
fi

# Check if compose file exists
COMPOSE_PATH="$PROJECT_ROOT/$COMPOSE_FILE"
if [ ! -f "$COMPOSE_PATH" ]; then
    echo -e "${RED}Error: Compose file not found: $COMPOSE_PATH${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Deployment Configuration:${NC}"
echo -e "  File: ${GREEN}$COMPOSE_FILE${NC}"
echo ""

# Check if podman-compose is installed
if ! command -v podman-compose &> /dev/null; then
    echo -e "${RED}Error: podman-compose is required but not installed${NC}"
    echo "Install with: pip3 install podman-compose"
    exit 1
fi

# Ask for confirmation
read -p "Deploy with this configuration? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Deploy
echo ""
echo -e "${BLUE}Starting deployment...${NC}"
cd "$PROJECT_ROOT"
podman-compose -f "$COMPOSE_FILE" up -d

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "  - Check status: podman ps"
echo "  - View logs: podman logs ${CAPABILITY_NAME}-capability"
echo "  - Run health check: ./scripts/health-check.sh"
echo "  - Validate deployment: ./scripts/validate-deployment.sh"
