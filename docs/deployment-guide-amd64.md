# AMD64 Deployment Guide

This guide covers deploying the Ollama LLM capability on x86-64 (AMD64) systems with 24GB or more of RAM.

## System Requirements

### Minimum Requirements
- **CPU:** 8 cores (Intel/AMD x86-64)
- **RAM:** 24GB (minimum), 32GB+ recommended
- **Storage:** 50GB free (for models)
- **OS:** Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+, or equivalent)

### Recommended Specifications
- **CPU:** 16+ cores
- **RAM:** 32GB or more
- **Storage:** 100GB+ SSD (faster model loading)
- **GPU:** Optional NVIDIA CUDA support (requires NVIDIA GPU and CUDA runtime)

### Prerequisites
- Podman or Docker installed (`podman --version` or `docker --version`)
- `curl` command available
- Network connectivity to pull the Ollama image

## Quick Start (24GB-32GB Systems)

```bash
# 1. Clone this repository
git clone https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama.git
cd ezansi-capability-llm-ollama

# 2. Deploy using the recommended preset
./scripts/choose-compose.sh --run

# 3. Verify the service is healthy
./scripts/health-check.sh

# 4. Pull a model
podman exec ollama-llm-capability ollama pull mistral
```

## Compose File Selection

Choose the appropriate configuration for your system:

### `config/amd64-24gb.yml` (Explicit 24GB configuration)
- Memory limit: 18GB / 14GB reserved
- CPU limit: 8 cores
- Parallel requests: 8
- Max loaded models: 3
- **Best for:** Systems with exactly 24GB RAM

### `config/amd64-32gb.yml` (High-performance systems)
- Memory limit: 28GB / 24GB reserved
- CPU limit: 16 cores
- Parallel requests: 16
- Max loaded models: 4
- **Best for:** Systems with 32GB+ RAM and many CPU cores

## Deployment Methods

### Method 1: Using Podman Compose (Recommended)

```bash
# Start the service
podman-compose -f ./config/amd64-24gb.yml up -d

# Check status
podman-compose -f ./config/amd64-24gb.yml ps

# View logs
podman-compose -f ./config/amd64-24gb.yml logs -f

# Stop the service
podman-compose -f ./config/amd64-24gb.yml down
```

### Method 2: Using Docker Compose

If you prefer Docker instead of Podman:

```bash
# Start the service
docker-compose -f ./config/amd64-24gb.yml up -d

# Note: The file works with both Podman and Docker
```

### Method 3: Manual Podman Run

```bash
# Pull the image
podman pull docker.io/ollama/ollama

# Create volume for persistence
podman volume create ollama-data

# Run the container
podman run -d \
  --name ollama-llm-capability \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  --memory 18g \
  --cpus 8 \
  --restart unless-stopped \
  -e OLLAMA_NUM_PARALLEL=8 \
  -e OLLAMA_MAX_LOADED_MODELS=3 \
  docker.io/ollama/ollama

# Verify it's running
curl http://localhost:11434/api/tags
```

## Model Management

### Pulling Models

```bash
# List available models first (view at https://ollama.ai/library)
podman exec ollama-llm-capability ollama list

# Pull a model
podman exec ollama-llm-capability ollama pull mistral

# Pull a larger model (requires more VRAM)
podman exec ollama-llm-capability ollama pull llama2

# Pull multiple models
podman exec ollama-llm-capability ollama pull neural-chat
podman exec ollama-llm-capability ollama pull orca-mini
```

### Recommended Models for AMD64

Based on available system RAM:

| Model | Size | RAM Required | Best For |
|-------|------|--------------|----------|
| `mistral` | 4.1B | 8GB | Fast inference, balanced quality |
| `neural-chat` | 7B | 12GB | Chat applications, good quality |
| `llama2` | 7B | 12GB | General purpose, popular |
| `orca-mini` | 3B | 6GB | Light workloads, embedded systems |
| `dolphin-mixtral` | MoE | 24GB+ | High quality, requires 32GB+ systems |

### Checking Loaded Models

```bash
# View all available models
podman exec ollama-llm-capability ollama list

# Check current memory usage
podman exec ollama-llm-capability ps aux
```

### Removing Models

```bash
# Remove a specific model
podman exec ollama-llm-capability ollama rm mistral

# List models before deletion
podman exec ollama-llm-capability ollama list
```

## API Usage

The Ollama API runs on `localhost:11434` (or your server's IP address).

### Generate Text

```bash
# Using curl
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Tell me about edge AI",
  "stream": false
}'

# With streaming
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Tell me about edge AI",
  "stream": true
}'
```

### Remote Access

If accessing from another machine on your network:

```bash
# On remote client
curl -X POST http://<server-ip>:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Hello",
  "stream": false
}'

# Security note: This exposes the API to your network
# Consider using a firewall or reverse proxy for production
```

## Performance Optimization

### Memory Management

The AMD64 configurations are tuned for systems with 24GB+. To optimize for your specific system:

```yaml
# Edit your config preset file under config/ (or run ./scripts/choose-compose.sh to see which one to use)
deploy:
  resources:
    limits:
      memory: 20g        # Adjust based on your RAM
      cpus: '8'          # Match your CPU count
```

### CPU Usage

Increase parallel requests for systems with more CPU cores:

```yaml
environment:
  - OLLAMA_NUM_PARALLEL=16  # For 16+ core systems
  - OLLAMA_MAX_LOADED_MODELS=4  # For 32GB+ RAM
```

### Monitoring Performance

```bash
# Check container resource usage
podman stats ollama-llm-capability

# View container logs for performance metrics
podman logs ollama-llm-capability | grep -i "error\|warning"
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
podman logs ollama-llm-capability

# Verify image is available
podman images | grep ollama

# Try pulling the image again
podman pull docker.io/ollama/ollama

# Check if port 11434 is already in use
lsof -i :11434
```

### Out of Memory (OOM)

```bash
# Check memory limits
podman stats ollama-llm-capability

# Reduce memory limit in compose file
# Reduce OLLAMA_MAX_LOADED_MODELS
# Unload some models: podman exec ollama-llm-capability ollama rm model-name
```

### Slow Performance

1. **Check system resources:**
   ```bash
   top -bn1 | head -20  # CPU usage
   free -h              # Memory usage
   df -h                # Disk space
   ```

2. **Monitor container:**
   ```bash
   podman stats ollama-llm-capability
   ```

3. **Optimize configuration:**
   - Ensure no system overload
   - Reduce OLLAMA_NUM_PARALLEL if CPU-bound
   - Add more memory reservation if RAM-bound

### Model Loading Fails

```bash
# Check available disk space
df -h /path/to/ollama-data

# Clear cached data if needed
podman exec ollama-llm-capability rm -rf /root/.ollama/tmp/*

# Restart the service
podman-compose -f ./config/amd64-24gb.yml restart
```

## Stopping and Updating

### Stop the Service

```bash
podman-compose -f ./config/amd64-24gb.yml down

# Remove volumes too (WARNING: deletes models)
podman-compose -f ./config/amd64-24gb.yml down -v
```

### Update Ollama Image

```bash
# Pull the latest image
podman pull docker.io/ollama/ollama

# Restart the service
podman-compose -f ./config/amd64-24gb.yml restart
```

### Backup Models

Before updating or removing volumes:

```bash
# Export the container image with loaded models
podman commit ollama-llm-capability ollama-llm-backup:latest

# Or backup the volume
podman run --rm \
  -v ollama-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/ollama-backup.tar.gz -C /data .
```

## Security Considerations

### Network Exposure

The Ollama API is exposed on port 11434. By default, it's only accessible locally. For remote access:

1. **Use a firewall:**
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 11434
   ```

2. **Use a reverse proxy (nginx):**
   ```nginx
   server {
       listen 80;
       server_name ollama.example.com;
       
       location / {
           proxy_pass http://localhost:11434;
           proxy_buffering off;
       }
   }
   ```

3. **Use authentication:**
   Consider wrapping the API with an authentication layer for production.

## Advanced Configuration

### Custom Environment Variables

```yaml
environment:
  - OLLAMA_NUM_PARALLEL=8
  - OLLAMA_MAX_LOADED_MODELS=3
  - OLLAMA_LOAD_TIMEOUT=5m  # Model load timeout
  - OLLAMA_KEEP_ALIVE=5m    # Keep model in memory for 5 minutes
```

### Custom Model Directory

```yaml
volumes:
  - /path/to/custom/models:/root/.ollama
```

### Running Multiple Instances

If you need multiple Ollama instances on the same machine:

```bash
# Use different ports and container names
podman run -d \
  --name ollama-instance-2 \
  -p 11435:11434 \
  -v ollama-data-2:/root/.ollama \
  docker.io/ollama/ollama
```

## Next Steps

1. **Verify deployment:** Run `./scripts/health-check.sh`
2. **Pull your first model:** Follow Model Management section above
3. **Test the API:** Use the API Usage examples
4. **Integrate with eZansiEdgeAI:** See the main README for capability registry configuration
5. **Monitor performance:** Use the Performance Optimization section for your workload

## Support & Troubleshooting

For additional issues:

1. Check [troubleshooting.md](troubleshooting.md) for common issues
2. Review [architecture.md](architecture.md) for system design
3. See [performance-tuning.md](performance-tuning.md) for optimization
4. Check Ollama documentation: https://github.com/ollama/ollama
