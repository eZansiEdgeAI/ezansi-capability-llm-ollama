#!/bin/bash

# Performance Test for Ollama LLM Capability
# Measures response time and throughput

set -e

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
PROMPT="${TEST_PROMPT:-Explain AI in one sentence}"

echo "================================================"
echo "Ollama Performance Test"
echo "================================================"

# Get available models
echo "Fetching available models..."
MODELS_JSON=$(curl -s "$OLLAMA_URL/api/tags")
MODELS=$(echo "$MODELS_JSON" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)

if [ -z "$MODELS" ]; then
    echo "Error: No models found. Please pull a model first:"
    echo "  podman exec ollama-llm-capability ollama pull mistral:latest"
    exit 1
fi

echo ""
echo "Available models:"
select MODEL in $MODELS; do
    if [ -n "$MODEL" ]; then
        echo "Selected: $MODEL"
        break
    else
        echo "Invalid selection, please try again"
    fi
done

echo ""
echo "Model: $MODEL"
echo "Prompt: $PROMPT"
echo ""

echo "Running generation test..."
START_TIME=$(date +%s.%N)

RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"$PROMPT\",\"stream\":false}" \
    -H "Content-Type: application/json")

END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc)

echo ""
echo "Results:"
echo "  Duration: ${DURATION}s"
echo "  Response length: $(echo "$RESPONSE" | wc -c) bytes"
echo ""
echo "Response:"
echo "$RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4
echo ""
