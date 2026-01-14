# Troubleshooting Guide

## Common Issues and Solutions

### Container Won't Start

#### Symptoms
- `podman-compose up -d` fails
- Container exits immediately
- Error messages in logs

#### Solutions

**Check if Podman is running:**
```bash
podman ps
```

If command fails:
```bash
# Start Podman socket
systemctl --user start podman.socket

# Enable on boot
systemctl --user enable podman.socket
```

**Check container logs:**
```bash
podman logs ollama-llm-capability
```

**Verify image exists:**
```bash
podman images | grep ollama
```

If not present:
```bash
podman pull docker.io/ollama/ollama
```

**Check resource availability:**
```bash
free -h  # Check available RAM
df -h    # Check disk space
```

---

### Image Pull Fails

#### Symptoms
- `Error: short-name "ollama/ollama" did not resolve`
- Connection timeout during pull

#### Solutions

**Use fully qualified image name:**
```bash
podman pull docker.io/ollama/ollama
```

**Configure default registries:**
```bash
sudo nano /etc/containers/registries.conf
```

Add:
```ini
unqualified-search-registries = ["docker.io"]
```

**Check network connectivity:**
```bash
ping -c 3 docker.io
curl -I https://docker.io
```

---

### API Not Responding

#### Symptoms
- `curl http://localhost:11434/api/tags` times out
- Health check fails
- Connection refused errors

#### Solutions

**Wait for container to fully start:**
```bash
# Container can take 30-60 seconds to be ready
sleep 30
curl http://localhost:11434/api/tags
```

**Check if container is running:**
```bash
podman ps | grep ollama
```

**Check port binding:**
```bash
sudo lsof -i :11434
# or
sudo netstat -tulpn | grep 11434
```

**Verify health check:**
```bash
podman inspect ollama-llm-capability | grep -A 10 Health
```

**Check firewall:**
```bash
sudo ufw status
# If blocking, allow:
sudo ufw allow 11434/tcp
```

---

### Out of Memory Errors

#### Symptoms
- Container crashes during model load
- `OOMKilled` in container status
- System becomes unresponsive

#### Solutions

**Check container memory limit:**
```bash
podman inspect ollama-llm-capability | grep -i memory
```

**Use smaller model:**
```bash
# Instead of mistral (7B), try:
curl -X POST http://localhost:11434/api/pull -d '{"name":"phi"}'        # 2.7B
curl -X POST http://localhost:11434/api/pull -d '{"name":"orca-mini"}'  # 3B
curl -X POST http://localhost:11434/api/pull -d '{"name":"tinyllama"}'  # 1.1B
```

**Reduce memory limit:**

Edit `podman-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 5g  # Reduced from 6g
```

**Set max loaded models:**
```yaml
environment:
  - OLLAMA_MAX_LOADED_MODELS=1
```

**Free system memory:**
```bash
# Drop caches
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Restart container
podman restart ollama-llm-capability
```

---

### Slow Performance

#### Symptoms
- Text generation takes very long
- High CPU usage
- System lag

#### Solutions

**Check thermal throttling:**
```bash
vcgencmd measure_temp
# If > 80°C, improve cooling
```

**Use appropriate model for hardware:**

See [performance-tuning.md](performance-tuning.md) for recommendations.

**Check storage speed:**
```bash
# Test write speed
dd if=/dev/zero of=test.img bs=1M count=1024 oflag=direct
# Should be > 20 MB/s for acceptable performance
```

**Optimize Ollama settings:**

Edit `podman-compose.yml`:
```yaml
environment:
  - OLLAMA_NUM_PARALLEL=2  # Reduce if too slow
  - OLLAMA_KEEP_ALIVE=5m   # Unload models after 5 min idle
```

---

### Model Pull Fails or Hangs

#### Symptoms
- Model download starts but never completes
- Connection timeout during pull
- Partial download

#### Solutions

**Check disk space:**
```bash
df -h
# Models need 4-8GB typically
```

**Check network speed:**
```bash
speedtest-cli  # Install with: sudo apt install speedtest-cli
```

**Pull in foreground to see progress:**
```bash
curl -X POST http://localhost:11434/api/pull \
  -d '{"name":"mistral"}' \
  -H "Content-Type: application/json"
```

**Use smaller model first:**
```bash
# Test with tiny model
curl -X POST http://localhost:11434/api/pull -d '{"name":"tinyllama"}'
```

**Check Ollama logs during pull:**
```bash
podman logs -f ollama-llm-capability
```

---

### Memory Limit Errors (cgroups)

#### Symptoms
- `Error: crun: opening file 'memory.max' for writing: No such file or directory`
- `OCI runtime attempted to invoke a command that was not found`
- Memory/CPU limits in podman-compose don't work

#### Cause

Raspberry Pi OS may not have cgroups v2 memory controller enabled by default. This is required for Podman resource limits.

#### Solutions

**Check current cgroups version:**
```bash
stat -fc %T /sys/fs/cgroup/
# Should output: cgroup2fs
```

**If output is `tmpfs` (cgroups v1), enable cgroups v2:**

1. Edit boot configuration:
```bash
sudo nano /boot/firmware/cmdline.txt
```

2. Add these parameters to the **end of the existing line** (don't create new lines):
```
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 systemd.unified_cgroup_hierarchy=1
```

3. Save and reboot:
```bash
sudo reboot
```

4. Verify after reboot:
```bash
stat -fc %T /sys/fs/cgroup/
# Should now output: cgroup2fs

# Check memory controller is available
cat /sys/fs/cgroup/cgroup.controllers
# Should include: cpuset cpu io memory pids
```

**If using older Raspberry Pi OS:**

The file might be `/boot/cmdline.txt` instead of `/boot/firmware/cmdline.txt`:
```bash
sudo nano /boot/cmdline.txt
```

**Workaround (if can't enable cgroups v2):**

Remove resource limits from podman-compose.yml temporarily:

```yaml
services:
  ollama:
    image: docker.io/ollama/ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    # deploy:                    # Comment out resource limits
    #   resources:
    #     limits:
    #       memory: 6g
    #       cpus: '4'
    restart: unless-stopped
```

**Note:** Without resource limits, Ollama can consume all available system resources. Monitor with `htop` or `podman stats`.

---

### Permission Denied Errors

#### Symptoms
- Cannot start container
- Volume mount errors
- Socket permission errors

#### Solutions

**Enable user lingering:**
```bash
loginctl enable-linger $USER
```

**Fix socket permissions:**
```bash
systemctl --user restart podman.socket
ls -la /run/user/$(id -u)/podman/
```

**Check volume permissions:**
```bash
podman volume inspect ollama-data
```

**Run validation script:**
```bash
./scripts/validate-deployment.sh
```

---

### Container Restarts Repeatedly

#### Symptoms
- Container status shows "Restarting"
- Constant crash loop
- Health check failures

#### Solutions

**Check logs for errors:**
```bash
podman logs --tail 50 ollama-llm-capability
```

**Disable restart temporarily:**
```bash
podman update --restart=no ollama-llm-capability
```

**Check health check configuration:**
```bash
podman inspect ollama-llm-capability | grep -A 10 Healthcheck
```

**Recreate container:**
```bash
podman-compose down
podman-compose up -d
```

---

### Validation Script Fails

#### Symptoms
- `./scripts/validate-deployment.sh` reports errors
- Health checks fail

#### Solutions

**Check script has execute permissions:**
```bash
chmod +x scripts/validate-deployment.sh
```

**Run manually to see detailed output:**
```bash
bash -x scripts/validate-deployment.sh
```

**Verify prerequisites:**
```bash
# Podman installed?
podman --version

# Container running?
podman ps

# API accessible?
curl http://localhost:11434/api/tags
```

---

## Diagnostic Commands

### System Information
```bash
# OS and kernel
uname -a
cat /etc/os-release

# Memory
free -h
cat /proc/meminfo

# CPU
lscpu
vcgencmd measure_temp

# Storage
df -h
lsblk
```

### Podman Information
```bash
# Podman version and info
podman version
podman info

# Container status
podman ps -a

# Container logs
podman logs ollama-llm-capability

# Container resource usage
podman stats ollama-llm-capability

# Container details
podman inspect ollama-llm-capability
```

### Network Debugging
```bash
# Check port binding
sudo netstat -tulpn | grep 11434
sudo lsof -i :11434

# Test API
curl -v http://localhost:11434/api/tags

# Check DNS
nslookup docker.io
```

## Getting Help

If you're still stuck:

1. **Check the logs first:**
   ```bash
   podman logs ollama-llm-capability
   ```

2. **Run validation script:**
   ```bash
   ./scripts/validate-deployment.sh
   ```

3. **Gather diagnostic info:**
   ```bash
   podman info > podman-info.txt
   podman logs ollama-llm-capability > ollama-logs.txt
   free -h > system-memory.txt
   df -h > disk-space.txt
   ```

4. **Check documentation:**
   - [Architecture](architecture.md)
   - [Performance Tuning](performance-tuning.md)
   - [Ollama Documentation](https://github.com/ollama/ollama)

5. **File an issue** with:
   - Hardware specs (Pi model, RAM)
   - OS version
   - Podman version
   - Error messages
   - Diagnostic output

## Prevention Best Practices

1. **Always validate deployment** after changes
2. **Monitor resources** regularly
3. **Keep Podman updated:** `sudo apt update && sudo apt upgrade podman`
4. **Use version-specific configs** from `config/` directory
5. **Test with small models first** before deploying large ones
6. **Enable user lingering** for reliable service restarts
7. **Use fast storage** (SSD/NVMe over microSD when possible)
8. **Ensure adequate cooling** to prevent thermal throttling
