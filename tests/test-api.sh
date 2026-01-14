#!/bin/bash

# API Integration Test for Ollama LLM Capability
# Tests basic API functionality

set -e

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "Ollama API Integration Test"
echo "================================================"
echo ""

# Test 1: Health Check
echo -n "Test 1: Health check... "
if curl -s --max-time 5 "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "Ollama API is not responding"
    exit 1
fi

# Test 2: List Models
echo -n "Test 2: List models... "
MODELS=$(curl -s "$OLLAMA_URL/api/tags")
if echo "$MODELS" | grep -q "models"; then
    echo -e "${GREEN}PASS${NC}"
    MODEL_COUNT=$(echo "$MODELS" | grep -o '"name"' | wc -l)
    echo "  Found $MODEL_COUNT model(s)"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 3: Check if any model is loaded
if [ "$MODEL_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No models installed${NC}"
    echo "  Pull a model with: ./scripts/pull-model.sh mistral"
    echo "  Skipping generation test"
    exit 0
fi

# Test 4: Text Generation
MODEL_NAME=$(echo "$MODELS" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
echo -n "Test 3: Text generation (model: $MODEL_NAME)... "

RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" \
    -d "{\"model\":\"$MODEL_NAME\",\"prompt\":\"Say hello\",\"stream\":false}" \
    -H "Content-Type: application/json")

if echo "$RESPONSE" | grep -q "response"; then
    echo -e "${GREEN}PASS${NC}"
    echo "  Response preview: $(echo "$RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4 | head -c 50)..."
else
    echo -e "${RED}FAIL${NC}"
    echo "  Response: $RESPONSE"
    exit 1
fi

echo ""
echo "================================================"
echo -e "${GREEN}All tests passed!${NC}"
echo "================================================"
echo ""
