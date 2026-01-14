# Performance Tuning Guide

## Raspberry Pi Optimization

### Hardware Considerations

| Device | RAM | Recommended Models | Max Memory Limit | Concurrent Requests |
|--------|-----|-------------------|------------------|---------------------|
| Pi 5 (16GB) | 16GB | mistral, llama2, neural-chat | 8GB | 4 |
| Pi 5 (8GB) | 8GB | mistral, neural-chat, orca-mini | 6GB | 2 |
| Pi 4 (8GB) | 8GB | neural-chat, orca-mini, tinyllama | 5GB | 2 |

### Resource Allocation

#### Memory Limits

**Pi 5 (16GB) - Maximum Performance**
```yaml
deploy:
  resources:
    limits:
      memory: 8g
    reservations:
      memory: 6g
```

**Pi 5/4 (8GB) - Balanced**
```yaml
deploy:
  resources:
    limits:
      memory: 6g
    reservations:
      memory: 4g
```

**Pi 4 (8GB) - Conservative**
```yaml
deploy:
  resources:
    limits:
      memory: 5g
    reservations:
      memory: 3g
```

#### CPU Allocation

All Raspberry Pi models (4 and 5) have 4 cores:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
```

### Ollama Environment Variables

#### OLLAMA_NUM_PARALLEL

Controls number of parallel requests:

```yaml
environment:
  - OLLAMA_NUM_PARALLEL=4  # Pi 5 16GB
  - OLLAMA_NUM_PARALLEL=2  # Pi 4/5 8GB
```

#### OLLAMA_MAX_LOADED_MODELS

Controls how many models stay in memory:

```yaml
environment:
  - OLLAMA_MAX_LOADED_MODELS=2  # Pi 5 16GB
  - OLLAMA_MAX_LOADED_MODELS=1  # Pi 4/5 8GB
```

## Model Selection

### Recommended Models by Device

**Pi 5 (16GB) - Best Performance**
- `mistral` (7B) - Best quality, acceptable speed
- `llama2` (7B) - Alternative to Mistral
- `neural-chat` (7B) - Conversational
- `phi` (2.7B) - Faster, lighter

**Pi 5/4 (8GB) - Balanced**
- `mistral` (7B) - Still works, slower
- `neural-chat` (7B) - Conversational
- `orca-mini` (3B) - Faster alternative
- `phi` (2.7B) - Recommended for speed

**Pi 4 (8GB) - Speed Priority**
- `neural-chat` (7B) - Slowest acceptable
- `orca-mini` (3B) - Recommended
- `tinyllama` (1.1B) - Fastest
- `phi` (2.7B) - Good balance

### Model Performance Characteristics

| Model | Size | RAM Usage | Speed (Pi 5) | Speed (Pi 4) | Quality |
|-------|------|-----------|--------------|--------------|---------|
| llama2 | 7B | ~4-5GB | Slow | Very Slow | Excellent |
| mistral | 7B | ~4-5GB | Slow | Very Slow | Excellent |
| neural-chat | 7B | ~4-5GB | Slow | Very Slow | Very Good |
| phi | 2.7B | ~2-3GB | Medium | Slow | Good |
| orca-mini | 3B | ~2-3GB | Medium | Slow | Good |
| tinyllama | 1.1B | ~1-2GB | Fast | Medium | Fair |

## Storage Optimization

### Use Fast Storage

- **Recommended:** NVMe SSD via USB 3.0+
- **Acceptable:** High-quality microSD (UHS-3 or better)
- **Not recommended:** Cheap microSD cards

### Volume Configuration

Use named volumes for persistence:

```yaml
volumes:
  ollama-data:
    driver: local
```

For SSD/USB storage, use bind mounts:

```yaml
volumes:
  - /mnt/ssd/ollama-data:/root/.ollama
```

## Network Optimization

### Local Access Only

If only accessing locally, bind to localhost:

```yaml
ports:
  - "127.0.0.1:11434:11434"
```

### LAN Access

For access from other devices on network:

```yaml
ports:
  - "0.0.0.0:11434:11434"
```

## OS-Level Optimizations

### Swap Configuration

Disable swap for better performance (if you have enough RAM):

```bash
sudo dphys-swapfile swapoff
sudo systemctl disable dphys-swapfile
```

Or reduce swap usage:

```bash
sudo nano /etc/sysctl.conf
# Add: vm.swappiness=10
sudo sysctl -p
```

### CPU Governor

Set CPU to performance mode:

```bash
echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Make permanent:

```bash
sudo apt install cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl restart cpufrequtils
```

## Monitoring Performance

### Check Resource Usage

```bash
# Monitor container stats
podman stats ollama-llm-capability

# Check system resources
htop
```

### Measure Generation Speed

```bash
# Run performance test
./tests/test-performance.sh

# Custom test
time curl -X POST http://localhost:11434/api/generate \
  -d '{"model":"mistral","prompt":"Explain AI"}' \
  -H "Content-Type: application/json"
```

### Expected Performance

**Text Generation (100 tokens):**

| Device | Model | Time | Tokens/sec |
|--------|-------|------|------------|
| Pi 5 16GB | mistral | ~20-30s | 3-5 |
| Pi 5 16GB | phi | ~8-12s | 8-12 |
| Pi 4 8GB | orca-mini | ~25-35s | 3-4 |
| Pi 4 8GB | tinyllama | ~10-15s | 7-10 |

## Thermal Management

### Monitor Temperature

```bash
# Check CPU temperature
vcgencmd measure_temp

# Continuous monitoring
watch -n 1 vcgencmd measure_temp
```

### Cooling Recommendations

- **Required:** Active cooling (fan)
- **Recommended:** Heatsink + fan combo
- **Optimal:** Case with active cooling

**Thermal throttling occurs at:**
- Pi 5: 85°C
- Pi 4: 80°C

## Configuration Presets

Use device-specific configs from `config/` directory:

```bash
# Pi 5 16GB (maximum performance)
cp config/pi5-16gb.yml podman-compose.yml

# Pi 4 8GB (conservative)
cp config/pi4-8gb.yml podman-compose.yml
```

## Troubleshooting Slow Performance

### Container is slow

1. Check memory limits aren't too restrictive
2. Verify model size fits in RAM
3. Check storage speed (avoid slow SD cards)
4. Monitor CPU temperature (thermal throttling)

### Out of memory errors

1. Use smaller model
2. Reduce memory limit slightly
3. Set `OLLAMA_MAX_LOADED_MODELS=1`
4. Restart container to clear memory

### High CPU usage at idle

Normal - Ollama keeps models loaded in memory. Adjust with:

```yaml
environment:
  - OLLAMA_KEEP_ALIVE=5m  # Unload after 5 minutes idle
```

## Best Practices

1. **Start conservative** - Use smaller models first, scale up
2. **Monitor resources** - Watch memory and CPU usage
3. **Use fast storage** - NVMe/SSD makes a big difference
4. **Active cooling** - Essential for sustained performance
5. **Match workload to hardware** - Don't run 7B models on Pi 4
6. **Test before deploying** - Use performance test scripts
7. **Leave headroom** - Don't allocate 100% of RAM to container

## References

- [Ollama Performance Tips](https://github.com/ollama/ollama#performance)
- [Raspberry Pi 5 Performance Guide](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#performance)
- Device configs: `config/device-constraints.json`
