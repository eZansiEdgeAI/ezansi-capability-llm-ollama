#!/bin/bash

# Deployment Validation Script for ollama-llm Capability
# Validates that Podman is running, Ollama container is healthy, and API responds

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "Ollama LLM Capability - Deployment Validation"
echo "================================================"
echo ""

# Check 1: Podman is installed
echo -n "Checking Podman installation... "
if ! command -v podman &> /dev/null; then
    echo -e "${RED}FAIL${NC}"
    echo "Podman is not installed. Install with: sudo apt install -y podman podman-compose"
    exit 1
fi
echo -e "${GREEN}OK${NC}"
echo "  Version: $(podman --version)"
echo ""

# Check 2: Podman daemon is running
echo -n "Checking Podman daemon... "
if ! podman ps &> /dev/null; then
    echo -e "${RED}FAIL${NC}"
    echo "Podman daemon is not running. Start with: podman system service --time=0 &"
    exit 1
fi
echo -e "${GREEN}OK${NC}"
echo ""

# Check 3: Ollama container is running
echo -n "Checking Ollama container status... "
if ! podman ps --filter "name=ollama-llm-capability" --format "{{.Names}}" | grep -q "ollama-llm-capability"; then
    echo -e "${YELLOW}NOT RUNNING${NC}"
    echo "Starting Ollama container with podman-compose..."
    podman-compose up -d
    sleep 10
    echo "  Waiting for Ollama to be ready..."
else
    echo -e "${GREEN}RUNNING${NC}"
    echo "  Container ID: $(podman ps --filter "name=ollama-llm-capability" --format "{{.ID}}" | cut -c1-12)"
fi
echo ""

# Check 4: Ollama API is responding
echo -n "Checking Ollama API health... "
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        echo "  Endpoint: http://localhost:11434"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}FAIL${NC}"
        echo "Ollama API not responding after $MAX_ATTEMPTS attempts."
        echo "Check logs with: podman logs ollama-llm-capability"
        exit 1
    fi
    sleep 1
done
echo ""

# Check 5: Test basic API call
echo "Testing Ollama API..."
RESPONSE=$(curl -s http://localhost:11434/api/tags)
MODELS=$(echo "$RESPONSE" | grep -o '"name"' | wc -l)
if [ $MODELS -eq 0 ]; then
    echo -e "  ${YELLOW}No models installed yet${NC}"
    echo "  Pull a model with: curl -X POST http://localhost:11434/api/pull -d '{\"name\":\"mistral\"}'"
else
    echo -e "  ${GREEN}Found $MODELS model(s)${NC}"
fi
echo ""

# Check 6: Resource verification
echo "Resource Verification:"
CONTAINER_ID=$(podman ps --filter "name=ollama-llm-capability" --format "{{.ID}}" | head -1)
if [ ! -z "$CONTAINER_ID" ]; then
    MEMORY=$(podman inspect "$CONTAINER_ID" --format '{{.HostConfig.Memory}}' | awk '{printf "%.2f GB\n", $1/1024/1024/1024}')
    echo -e "  Memory limit: ${GREEN}${MEMORY}${NC}"
fi
echo ""

echo "================================================"
echo -e "${GREEN}✓ Deployment validation successful!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Pull a model: curl -X POST http://localhost:11434/api/pull -d '{\"name\":\"mistral\"}'"
echo "2. Generate text: curl -X POST http://localhost:11434/api/generate -d '{\"model\":\"mistral\",\"prompt\":\"Hello\"}'"
echo ""
