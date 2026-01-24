#!/bin/bash

# Pull and configure a model for Ollama
# Usage: ./pull-model.sh <model-name>
#        ./pull-model.sh --recommended

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'EOF'
Usage:
    ./scripts/pull-model.sh <model-name>
    ./scripts/pull-model.sh
  ./scripts/pull-model.sh --recommended
  ./scripts/pull-model.sh --recommended-raw
  ./scripts/pull-model.sh --help

Description:
  Pull a model into your local Ollama instance (http://localhost:11434).
        When run with no arguments, this script prints recommended models for your
        device (from ./scripts/choose-compose.sh --models), prompts for a model
        name, then pulls that model.

Options:
  --recommended       Print recommended models (friendly format) and exit.
  --recommended-raw   Print recommended models (raw; one per line) and exit.
  -h, --help          Show this help.
EOF
}

list_recommended_models() {
    if [ ! -x "$SCRIPT_DIR/choose-compose.sh" ]; then
        echo "Error: scripts/choose-compose.sh not found or not executable" >&2
        echo "Expected: $SCRIPT_DIR/choose-compose.sh" >&2
        return 2
    fi

    echo "================================================"
    echo "Recommended models (from choose-compose)"
    echo "================================================"
    if ! "$SCRIPT_DIR/choose-compose.sh" --models | sed 's/^/- /'; then
        echo "" >&2
        echo "Tip: run ./scripts/choose-compose.sh to see why device detection failed." >&2
        return 3
    fi

    return 0
}

print_recommended_models_and_exit() {
    local raw="$1"

    if [ ! -x "$SCRIPT_DIR/choose-compose.sh" ]; then
        echo "Error: scripts/choose-compose.sh not found or not executable" >&2
        echo "Expected: $SCRIPT_DIR/choose-compose.sh" >&2
        exit 2
    fi

    if [ "$raw" = "1" ]; then
        "$SCRIPT_DIR/choose-compose.sh" --models
        exit $?
    fi

    if ! list_recommended_models; then
        exit $?
    fi

    echo ""
    echo "Pull one with: ./scripts/pull-model.sh <model-name>"
    exit 0
}

prompt_for_model_name() {
    local __out_var="$1"
    local input=""

    echo "" >&2
    echo "Type a model name to pull, or press Enter to exit." >&2

    if [ -t 0 ]; then
        # Normal interactive use.
        read -r -p "Model name: " input
    elif [ -t 1 ] && [ -r /dev/tty ]; then
        # stdin may have been consumed by earlier pipelines; read directly from the terminal.
        read -r -p "Model name: " input </dev/tty
    else
        # Non-interactive stdin (e.g. piped). If there's no input (EOF), exit.
        if ! IFS= read -r input; then
            return 1
        fi
    fi

    # Trim leading/trailing whitespace
    input="$(printf '%s' "$input" | sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//')"
    if [ -z "$input" ]; then
        return 1
    fi

    printf -v "$__out_var" '%s' "$input"
    return 0
}

case "${1:-}" in
    --interactive)
        # Alias: previous iteration used --interactive.
        print_recommended_models_and_exit 0
        ;;
    --recommended)
        print_recommended_models_and_exit 0
        ;;
    --recommended-raw)
        print_recommended_models_and_exit 1
        ;;
    -h|--help)
        usage
        exit 0
        ;;
esac

MODEL_NAME="${1:-}"
if [ -z "$MODEL_NAME" ]; then
    if ! list_recommended_models; then
        echo "" >&2
        echo "(Continuing: you can still type a model name manually.)" >&2
    fi

    echo ""
    echo "Pull one with: ./scripts/pull-model.sh <model-name>"

    if ! prompt_for_model_name MODEL_NAME; then
        exit 0
    fi
fi

echo "================================================"
echo "Ollama Model Puller"
echo "================================================"
echo "Model: $MODEL_NAME"
echo "Ollama: http://localhost:11434"
echo ""

# Check if Ollama is running
echo "Checking Ollama..."
if ! curl -fsS \
    --connect-timeout 2 \
    --max-time 5 \
    http://localhost:11434/api/tags >/dev/null; then
    echo "Error: Ollama is not running or not reachable at http://localhost:11434" >&2
    echo "Start it with: podman-compose up -d" >&2
    exit 1
fi

echo "Pulling model: $MODEL_NAME..."
echo "This may take several minutes depending on model size and internet speed."
echo ""

# Pull the model (single-line progress)
# Streams JSON progress from the Ollama API, splits concatenated objects,
# extracts status/total/completed, and renders a human-readable progress line.
curl -sN -X POST http://localhost:11434/api/pull \
    -d "{\"name\":\"$MODEL_NAME\"}" \
    -H "Content-Type: application/json" \
    --connect-timeout 2 \
    --max-time 0 \
| sed -u 's/}{/}\n{/g' \
| while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Extract fields from JSON line
    status=$(printf '%s' "$line" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')
    total=$(printf '%s' "$line" | sed -n 's/.*"total":\([0-9]*\).*/\1/p')
    completed=$(printf '%s' "$line" | sed -n 's/.*"completed":\([0-9]*\).*/\1/p')

    # Render progress
    if [ -n "$status" ] && [ -n "$total" ] && [ -n "$completed" ] && [ "$total" -gt 0 ] 2>/dev/null; then
        percent=$((completed * 100 / total))
        completed_h=$(awk -v b="$completed" 'function human(x){u="B KB MB GB TB PB"; n=split(u,a," "); i=1; while (x>=1024 && i<n){x/=1024; i++} printf "%.3f%s", x, a[i]} BEGIN{human(b)}')
        total_h=$(awk -v b="$total" 'function human(x){u="B KB MB GB TB PB"; n=split(u,a," "); i=1; while (x>=1024 && i<n){x/=1024; i++} printf "%.3f%s", x, a[i]} BEGIN{human(b)}')
        printf "\r\033[K%s %3d%% (%s/%s)" "$status" "$percent" "$completed_h" "$total_h"
    else
        printf "\r\033[K%s" "$line"
    fi

    if [ "$status" = "success" ]; then
        printf "\n"
    fi
done

echo ""
echo "================================================"
echo "Model pull complete!"
echo "================================================"
echo ""
echo "Test it with:"
echo "curl -X POST http://localhost:11434/api/generate \\" 
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\":\"$MODEL_NAME\",\"prompt\":\"Hello\"}'"
echo ""
