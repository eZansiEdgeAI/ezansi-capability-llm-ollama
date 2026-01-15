# Deployment & Portability Guide

You can deploy fully-loaded containers to any Linux system with Podman. Choose the approach that fits your needs:

## Option 1: Export & Import (Single Machine Transfer)

For transferring a fully-loaded Ollama container to another machine:

```bash
# On source machine - save the container image
podman save ollama-capability:latest -o ollama-capability-image.tar

# Transfer the file to target machine
scp ollama-capability-image.tar user@raspberrypi:/home/user/

# On target machine - load and run
podman load -i ollama-capability-image.tar
podman run -d ollama-capability:latest
```

**Best for:** Air-gapped systems, Raspberry Pi deployments, one-off transfers  
**Trade-off:** Large file size (5-10GB+ with pre-loaded models), slower transfer

## Option 2: Container Registry (Multiple Machines)

For deploying to multiple systems efficiently:

```bash
# On source machine
podman tag ollama-capability:latest myregistry.com/ollama-capability:latest
podman push myregistry.com/ollama-capability:latest

# On any target machine
podman pull myregistry.com/ollama-capability:latest
podman run -d myregistry.com/ollama-capability:latest
```

**Best for:** Fleet deployments, multiple Raspberry Pis, CI/CD pipelines  
**Trade-off:** Requires a registry (Docker Hub, Podman registry, etc.)

## Option 3: Rebuild on Target (Optimized)

Copy the `Containerfile` and build locally on the target system:

```bash
# Transfer this repo
scp -r <this-repo> user@raspberrypi:

# On target machine
cd <this-repo>
podman build -t ollama-capability:latest .
podman run -d ollama-capability:latest
```

**Best for:** Optimizing for target architecture, minimal initial transfer, bandwidth-constrained environments  
**Trade-off:** Slower first startup (models download/compile on target)

## Cross-Architecture Considerations

- **x86 → ARM (Raspberry Pi):** Use Option 3 (rebuild) for best compatibility
- **ARM → ARM (Pi 4 → Pi 5):** Options 1-2 work well, same architecture
- **Mixed fleet:** Use Option 2 (registry) with multi-architecture builds

## Quick Start: Deploy to Raspberry Pi 5

```bash
# Clone this repo on your Pi 5
git clone https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama.git
cd ezansi-capability-llm-ollama

# Build and run (Option 3)
podman build -t ollama-capability:latest .
podman run -d \
  --name ollama \
  -p 11434:11434 \
  -v ollama-models:/root/.ollama \
  ollama-capability:latest

# Verify it's running
./scripts/health-check.sh
```

See [DEPLOYMENT.md](../README.md) for additional configuration options.
