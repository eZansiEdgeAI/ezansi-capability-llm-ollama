#!/bin/bash
set -euo pipefail

# Preflight helper: choose the right compose preset for this host.
#
# Usage:
#   ./scripts/choose-compose.sh
#   ./scripts/choose-compose.sh --device raspberry-pi-5-16gb
#   ./scripts/choose-compose.sh --run
#   ./scripts/choose-compose.sh --list
#
# Exit codes:
#   0 = recommendation printed (or deployment ran)
#   2 = usage / invalid args
#   3 = unsupported / insufficient resources

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEVICE_OVERRIDE=""
RUN=false
LIST=false
QUIET=false
MODELS_ONLY=false

usage() {
	cat <<'EOF'
Choose the right podman-compose preset for this device.

Usage:
  ./scripts/choose-compose.sh [--device NAME] [--run] [--quiet]
	./scripts/choose-compose.sh [--device NAME] --models
  ./scripts/choose-compose.sh --list

Options:
  --device NAME   Override auto-detection. Examples:
                 raspberry-pi-5-16gb | raspberry-pi-5-8gb | raspberry-pi-4-8gb | amd64-24gb | amd64-32gb
  --run           Run: podman-compose -f <recommended> up -d
  --quiet         Print only the recommended compose file path
	--models        Print only the recommended models for the selected device profile (one per line)
  --list          List supported device profile names

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
		--models)
			MODELS_ONLY=true
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

if $QUIET && $MODELS_ONLY; then
	echo "Error: --quiet and --models are mutually exclusive" >&2
	exit 2
fi

if $LIST; then
	printf '%s\n' \
		raspberry-pi-5-16gb \
		raspberry-pi-5-8gb \
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

constraints_lookup() {
	# Usage: constraints_lookup <device_name>
	# Prints four tab-separated fields:
	#   recommended_models_csv<TAB>max_concurrent_requests<TAB>memory_limit<TAB>num_parallel<TAB>max_loaded_models
	local device_name="$1"

	if ! command -v python3 >/dev/null 2>&1; then
		return 1
	fi

	python3 - <<'PY' "$ROOT_DIR/config/device-constraints.json" "$device_name"
import json
import sys

path = sys.argv[1]
device = sys.argv[2]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

devices = data.get("devices", [])
row = next((d for d in devices if d.get("name") == device), None)
if not row:
    sys.exit(2)

recommended_models = row.get("recommended_models") or []
max_concurrent = row.get("max_concurrent_requests", "")
ollama_cfg = row.get("ollama_config") or {}
memory_limit = ollama_cfg.get("memory_limit", "")
num_parallel = ollama_cfg.get("num_parallel", "")
max_loaded = ollama_cfg.get("max_loaded_models", "")

print(
    ", ".join(recommended_models)
    + "\t" + str(max_concurrent)
    + "\t" + str(memory_limit)
    + "\t" + str(num_parallel)
    + "\t" + str(max_loaded)
)
PY
}

get_arch() {
	uname -m 2>/dev/null || echo "unknown"
}

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
	# /proc/device-tree/model contains NUL-terminated string.
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
		raspberry-pi-5-8gb)
			echo "config/pi5-8gb.yml"
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

choose_device_profile() {
	local arch="$1"
	local ram_mb="$2"
	local cpu_cores="$3"
	local pi_model="$4"

	# AMD64 host selection.
	if [[ "$arch" == "x86_64" || "$arch" == "amd64" ]]; then
		if (( ram_mb >= 32000 )) && (( cpu_cores >= 12 )); then
			echo "amd64-32gb"
			return 0
		fi
		if (( ram_mb >= 24000 )) && (( cpu_cores >= 8 )); then
			echo "amd64-24gb"
			return 0
		fi
		echo ""
		return 1
	fi

	# ARM64 (Raspberry Pi) selection.
	if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
		if [[ "$pi_model" == *"Raspberry Pi 5"* ]]; then
			if (( ram_mb >= 12000 )); then
				echo "raspberry-pi-5-16gb"
				return 0
			fi
			if (( ram_mb >= 7000 )); then
				echo "raspberry-pi-5-8gb"
				return 0
			fi
		fi

		if [[ "$pi_model" == *"Raspberry Pi 4"* ]]; then
			if (( ram_mb >= 7000 )); then
				echo "raspberry-pi-4-8gb"
				return 0
			fi
		fi

		# Fallback based on RAM if model isn't readable.
		if (( ram_mb >= 12000 )); then
			echo "raspberry-pi-5-16gb"
			return 0
		fi
		if (( ram_mb >= 7000 )); then
			echo "raspberry-pi-4-8gb"
			return 0
		fi

		echo ""
		return 1
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
	DEVICE="$(choose_device_profile "$ARCH" "$RAM_MB" "$CPU_CORES" "$PI_MODEL" || true)"
fi

COMPOSE_FILE_REL="$(compose_for_device "$DEVICE")"
if [[ -z "$COMPOSE_FILE_REL" ]]; then
	if ! $QUIET; then
		echo "Unable to determine a supported preset for this host." >&2
		echo "Detected: arch=$ARCH ram_mb=$RAM_MB cpu_cores=$CPU_CORES${PI_MODEL:+ model=\"$PI_MODEL\"}" >&2
		echo "Try: ./scripts/choose-compose.sh --list" >&2
		echo "Or override: ./scripts/choose-compose.sh --device <name>" >&2
	fi
	exit 3
fi

COMPOSE_FILE_ABS="$ROOT_DIR/$COMPOSE_FILE_REL"
if [[ ! -f "$COMPOSE_FILE_ABS" ]]; then
	if ! $QUIET; then
		echo "Preset compose file is missing: $COMPOSE_FILE_REL" >&2
		echo "Detected device profile: $DEVICE" >&2
		echo "Tip: ensure you've pulled the latest repo version." >&2
	fi
	exit 3
fi

constraints=""
if [[ -f "$ROOT_DIR/config/device-constraints.json" ]]; then
	constraints="$(constraints_lookup "$DEVICE" 2>/dev/null || true)"
fi

if $QUIET; then
	echo "$COMPOSE_FILE_REL"
	exit 0
fi

if $MODELS_ONLY; then
	if [[ -z "$constraints" ]]; then
		echo "Error: unable to load recommended models (python3 and config/device-constraints.json required)" >&2
		exit 3
	fi
	IFS=$'\t' read -r recommended_models _max_concurrent _memory_limit _num_parallel _max_loaded_models <<< "$constraints"
	# Print one model per line for easy scripting.
	python3 - <<'PY' "$recommended_models"
import sys
s = sys.argv[1]
items = [x.strip() for x in s.split(',') if x.strip()]
for item in items:
    print(item)
PY
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
echo "Recommended compose preset: $COMPOSE_FILE_REL"

if [[ -n "$constraints" ]]; then
	IFS=$'\t' read -r recommended_models max_concurrent memory_limit num_parallel max_loaded_models <<< "$constraints"
	echo ""
	echo "Recommended models: ${recommended_models:-unknown}"
	if [[ -n "${max_concurrent:-}" ]]; then
		echo "Suggested max concurrent requests: $max_concurrent"
	fi
	if [[ -n "${memory_limit:-}" || -n "${num_parallel:-}" || -n "${max_loaded_models:-}" ]]; then
		echo "Suggested Ollama config: memory_limit=${memory_limit:-?} num_parallel=${num_parallel:-?} max_loaded_models=${max_loaded_models:-?}"
	fi
fi

echo ""
echo "Run this:" 
echo "  podman-compose -f \"$COMPOSE_FILE_ABS\" up -d"
echo ""

echo "Notes:" 
echo "- Using -f avoids overwriting podman-compose.yml."
echo "- See config/device-constraints.json for recommended limits/models."

echo ""

if $RUN; then
	need_cmd podman
	need_cmd podman-compose
	echo "Starting container stack..."
	podman-compose -f "$COMPOSE_FILE_ABS" up -d
	echo "OK"
fi
