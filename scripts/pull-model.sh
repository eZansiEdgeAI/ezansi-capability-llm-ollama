#!/bin/bash

# Pull and configure a model for Ollama
# Usage: ./pull-model.sh <model-name>

set -e

MODEL_NAME="${1:-mistral}"

echo "================================================"
echo "Ollama Model Puller"
echo "================================================"
echo "Model: $MODEL_NAME"
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Error: Ollama is not running or not accessible on port 11434"
    echo "Start it with: podman-compose up -d"
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
echo "  -d '{\"model\":\"$MODEL_NAME\",\"prompt\":\"Hello\"}' \\"
echo "  -H \"Content-Type: application/json\""
echo ""
