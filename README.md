# ezansi-capability-llm-ollama

# Ollama LLM Capability

Provides: text-generation  
Target device: Raspberry Pi 5 (16GB)

## What this capability does

Runs a local LLM using Ollama and exposes it as a discoverable text-generation capability for the eZansiEdgeAI platform.

## Resource Requirements

- RAM: ~6GB
- CPU: 4 cores


## How to Run (Podman)

podman-compose up -d


## How to Test

curl http://localhost:11434/api/tags

## Getting the Rasberry Pi 5 ready for Ollma in container
```
sudo apt install -y podman podman-compose
podman --version
loginctl enable-linger $USER #This allows Podman containers to survive logout/reboot
podman pull docker.io/ollama/ollama
sudo podman run -d --name ollama -p 11434:11434 -v ollama-data:/root/.ollama --memory=6g --cpus=4 docker.io/ollama/ollama
```
