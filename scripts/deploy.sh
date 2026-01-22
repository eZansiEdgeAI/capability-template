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

usage() {
    cat <<EOF
Usage: ./scripts/deploy.sh [OPTIONS] [compose-file]

Options:
  --profile <pi4|pi5|amd64|amd64-24gb|amd64-32gb>  Select a known profile (overrides auto-detection)
  --compose-file <path>                            Use a specific compose file
  --build                                          Pass --build to podman-compose (useful on cold start)
  --yes                                            Non-interactive (skip confirmation)
  -h, --help                                       Show this help

Notes:
  - If a positional compose-file is provided, it takes precedence.
  - Auto-detection chooses a reasonable default if no options are provided.
EOF
}

PROFILE=""
COMPOSE_FILE_OVERRIDE=""
AUTO_YES=0
DO_BUILD=0

# Backwards compatible: allow a single positional compose-file arg.
POSITIONAL_COMPOSE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            PROFILE="${2:-}"
            shift 2
            ;;
        --compose-file|-f)
            COMPOSE_FILE_OVERRIDE="${2:-}"
            shift 2
            ;;
        --build)
            DO_BUILD=1
            shift
            ;;
        --yes|-y)
            AUTO_YES=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$POSITIONAL_COMPOSE" && "$1" != -* ]]; then
                POSITIONAL_COMPOSE="$1"
                shift
            else
                echo -e "${RED}Error: Unknown argument: $1${NC}"
                usage
                exit 1
            fi
            ;;
    esac
done

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

# Determine compose file
COMPOSE_FILE=""

# Highest precedence: positional compose file
if [[ -n "$POSITIONAL_COMPOSE" ]]; then
    COMPOSE_FILE="$POSITIONAL_COMPOSE"
    echo -e "${YELLOW}Using user-specified config: $COMPOSE_FILE${NC}"
elif [[ -n "$COMPOSE_FILE_OVERRIDE" ]]; then
    COMPOSE_FILE="$COMPOSE_FILE_OVERRIDE"
    echo -e "${YELLOW}Using specified config: $COMPOSE_FILE${NC}"
elif [[ -n "$PROFILE" ]]; then
    case "$PROFILE" in
        pi5)
            COMPOSE_FILE="podman-compose.pi5.yml"
            ;;
        pi4)
            COMPOSE_FILE="config/pi4-8gb.yml"
            ;;
        amd64)
            COMPOSE_FILE="podman-compose.amd64.yml"
            ;;
        amd64-24gb)
            COMPOSE_FILE="config/amd64-24gb.yml"
            ;;
        amd64-32gb)
            COMPOSE_FILE="config/amd64-32gb.yml"
            ;;
        *)
            echo -e "${RED}Error: Unknown profile: $PROFILE${NC}"
            usage
            exit 1
            ;;
    esac
    echo -e "${GREEN}Profile selected: $PROFILE${NC}"
else
    # Auto-detect based on architecture + RAM
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
    echo "Install with: sudo apt install podman-compose (preferred)"
    echo "Fallback: pip3 install --user podman-compose"
    exit 1
fi

# Ask for confirmation (unless --yes)
if [[ $AUTO_YES -ne 1 ]]; then
    read -p "Deploy with this configuration? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}Non-interactive mode: proceeding without confirmation (--yes)${NC}"
fi

# Deploy
echo ""
echo -e "${BLUE}Starting deployment...${NC}"
cd "$PROJECT_ROOT"

UP_ARGS=("-f" "$COMPOSE_FILE" "up" "-d")
if [[ $DO_BUILD -eq 1 ]]; then
    UP_ARGS+=("--build")
fi

podman-compose "${UP_ARGS[@]}"

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "  - Check status: podman ps"
echo "  - View logs: podman logs ${CAPABILITY_NAME}-capability"
echo "  - Run health check: ./scripts/health-check.sh"
echo "  - Validate deployment: ./scripts/validate-deployment.sh"
