#!/bin/bash

# Deployment wrapper script
# Combines podman-compose with validation

set -e

echo "================================================"
echo "Ollama LLM Capability - Deployment"
echo "================================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v podman &> /dev/null; then
    echo "Error: Podman is not installed"
    echo "Install with: sudo apt install -y podman podman-compose"
    exit 1
fi

if ! command -v podman-compose &> /dev/null; then
    echo "Error: podman-compose is not installed"
    echo "Install with: sudo apt install -y podman-compose"
    exit 1
fi

echo "✓ Prerequisites satisfied"
echo ""

# Deploy
echo "Starting Ollama container..."
podman-compose up -d

echo ""
echo "Waiting for container to be ready..."
sleep 5

echo ""
echo "Running validation..."
./scripts/validate-deployment.sh

echo ""
echo "================================================"
echo "Deployment complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Pull a model: ./scripts/pull-model.sh mistral"
echo "2. Test generation: ./scripts/../tests/test-api.sh"
echo ""
