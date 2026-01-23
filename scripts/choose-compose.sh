#!/bin/bash
set -euo pipefail

# Preflight helper: choose the right compose preset for this host.
#
# Usage:
#   ./scripts/choose-compose.sh
#   ./scripts/choose-compose.sh --device raspberry-pi-5-16gb
#   ./scripts/choose-compose.sh --quiet
#   ./scripts/choose-compose.sh --run
#   ./scripts/choose-compose.sh --list

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEVICE_OVERRIDE=""
RUN=false
LIST=false
QUIET=false

usage() {
	cat <<'EOF'
Choose the right podman-compose preset for this device.

Usage:
  ./scripts/choose-compose.sh [--device NAME] [--run] [--quiet]
  ./scripts/choose-compose.sh --list

Options:
  --device NAME  Override auto-detection. Examples:
                raspberry-pi-5-16gb | raspberry-pi-4-8gb | amd64-24gb | amd64-32gb
  --run          Run: podman-compose -f <recommended> up -d
  --quiet        Print only the recommended compose file path
  --list         List supported device profile names
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--device)
			DEVICE_OVERRIDE="${2:-}"
			if [[ -z "$DEVICE_OVERRIDE" ]]; then
				echo "--device requires a value" >&2
				exit 2
			fi
			shift 2
			;;
		--run)
			RUN=true
			shift
			;;
		--list)
			LIST=true
			shift
			;;
		--quiet)
			QUIET=true
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown arg: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

if $LIST; then
	printf '%s\n' \
		raspberry-pi-5-16gb \
		raspberry-pi-4-8gb \
		amd64-24gb \
		amd64-32gb
	exit 0
fi

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "Error: '$1' is required." >&2
		exit 3
	}
}

get_arch() { uname -m 2>/dev/null || echo "unknown"; }

get_ram_mb() {
	if [[ -r /proc/meminfo ]]; then
		awk '/MemTotal:/ {print int($2/1024)}' /proc/meminfo
	else
		echo 0
	fi
}

get_cpu_cores() {
	if command -v nproc >/dev/null 2>&1; then
		nproc
	elif command -v getconf >/dev/null 2>&1; then
		getconf _NPROCESSORS_ONLN || echo 0
	else
		echo 0
	fi
}

get_pi_model() {
	if [[ -r /proc/device-tree/model ]]; then
		tr -d '\000' < /proc/device-tree/model
	else
		echo ""
	fi
}

compose_for_device() {
	local device="$1"
	case "$device" in
		raspberry-pi-5-16gb)
			echo "config/pi5-16gb.yml"
			;;
		raspberry-pi-4-8gb)
			echo "config/pi4-8gb.yml"
			;;
		amd64-24gb)
			echo "config/amd64-24gb.yml"
			;;
		amd64-32gb)
			echo "config/amd64-32gb.yml"
			;;
		*)
			echo ""
			;;
	esac
}

choose_device() {
	local arch="$1"
	local ram_mb="$2"
	local cpu_cores="$3"
	local pi_model="$4"

	if [[ "$arch" == "x86_64" || "$arch" == "amd64" ]]; then
		if (( ram_mb >= 32000 )) && (( cpu_cores >= 8 )); then
			echo "amd64-32gb"
			return 0
		fi
		if (( ram_mb >= 24000 )) && (( cpu_cores >= 6 )); then
			echo "amd64-24gb"
			return 0
		fi
		# Conservative fallback.
		echo "amd64-24gb"
		return 0
	fi

	if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
		if [[ "$pi_model" == *"Raspberry Pi 5"* ]]; then
			echo "raspberry-pi-5-16gb"
			return 0
		fi
		# Default to pi4 preset for arm64.
		echo "raspberry-pi-4-8gb"
		return 0
	fi

	echo ""
	return 1
}

ARCH="$(get_arch)"
RAM_MB="$(get_ram_mb)"
CPU_CORES="$(get_cpu_cores)"
PI_MODEL="$(get_pi_model)"

DEVICE=""
if [[ -n "$DEVICE_OVERRIDE" ]]; then
	DEVICE="$DEVICE_OVERRIDE"
else
	DEVICE="$(choose_device "$ARCH" "$RAM_MB" "$CPU_CORES" "$PI_MODEL" || true)"
fi

COMPOSE_REL="$(compose_for_device "$DEVICE")"
if [[ -z "$COMPOSE_REL" ]]; then
	if ! $QUIET; then
		echo "Unable to determine a supported preset for this host." >&2
		echo "Detected: arch=$ARCH ram_mb=$RAM_MB cpu_cores=$CPU_CORES${PI_MODEL:+ model=\"$PI_MODEL\"}" >&2
		echo "Try: ./scripts/choose-compose.sh --list" >&2
		echo "Or override: ./scripts/choose-compose.sh --device <name>" >&2
	fi
	exit 3
fi

COMPOSE_ABS="$ROOT_DIR/$COMPOSE_REL"
if [[ ! -f "$COMPOSE_ABS" ]]; then
	if ! $QUIET; then
		echo "Preset compose file is missing: $COMPOSE_REL" >&2
		echo "Tip: ensure config presets exist under config/." >&2
	fi
	exit 3
fi

if $QUIET; then
	echo "$COMPOSE_REL"
	exit 0
fi

cat <<EOF
================================================
Compose Preset Selector (preflight)
================================================

Detected:
  arch:       $ARCH
  ram_mb:     $RAM_MB
  cpu_cores:  $CPU_CORES
EOF

if [[ -n "$PI_MODEL" ]]; then
	echo "  pi_model:   $PI_MODEL"
fi

echo ""
echo "Recommended device profile: $DEVICE"
echo "Recommended compose preset: $COMPOSE_REL"
echo ""
echo "Run this:"
echo "  podman-compose -f \"$COMPOSE_ABS\" up -d"
echo ""

echo "Notes:"
echo "- Using -f avoids overwriting podman-compose.yml."

echo ""

if $RUN; then
	need_cmd podman
	need_cmd podman-compose
	echo "Starting container stack..."
	podman-compose -f "$COMPOSE_ABS" up -d
	echo "OK"
fi
