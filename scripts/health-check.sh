#!/bin/bash

# Health check script for Ollama capability
# Returns 0 if healthy, 1 if unhealthy

set -e

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
TIMEOUT=5

# Check if Ollama API is responding
if curl -s --max-time $TIMEOUT "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo "✓ Ollama is healthy"
    exit 0
else
    echo "✗ Ollama is not responding"
    exit 1
fi
