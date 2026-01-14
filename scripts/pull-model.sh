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

# Pull the model
curl -X POST http://localhost:11434/api/pull \
    -d "{\"name\":\"$MODEL_NAME\"}" \
    -H "Content-Type: application/json"

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
