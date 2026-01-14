#!/bin/bash

# Performance Test for Ollama LLM Capability
# Measures response time and throughput

set -e

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${TEST_MODEL:-mistral}"
PROMPT="${TEST_PROMPT:-Explain AI in one sentence}"

echo "================================================"
echo "Ollama Performance Test"
echo "================================================"
echo "Model: $MODEL"
echo "Prompt: $PROMPT"
echo ""

# Check if model exists
if ! curl -s "$OLLAMA_URL/api/tags" | grep -q "\"$MODEL\""; then
    echo "Error: Model '$MODEL' not found"
    echo "Available models:"
    curl -s "$OLLAMA_URL/api/tags" | grep '"name"' | cut -d'"' -f4
    exit 1
fi

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
