# ezansi-capability-llm-ollama

Ollama LLM Capability for eZansiEdgeAI — a modular, containerized text-generation service designed to run on Raspberry Pi 5.

**Provides:** `text-generation`  
**Target device:** Raspberry Pi 5 (16GB)  
**Deployment method:** Podman + podman-compose

---

## Deployment Plan

This project focuses on getting the base Ollama capability up and deployable from this repository. The goal is to establish the first "LEGO brick" in the eZansiEdgeAI modular capability architecture.

### Deliverables

1. **Capability Contract** (`capability.json`) — Fully defines the Ollama LLM capability with name, version, API details, resource requirements, and container configuration. This contract is the foundation for the modular platform.

2. **Podman Compose Configuration** (`podman-compose.yml`) — Production-ready container setup with:
   - Health checks to verify service availability
   - Resource limits (6GB RAM, 4 CPU cores) tuned for Pi 5
   - Persistent volume for model storage
   - Auto-restart on failure

3. **Automated Deployment Validation** (`scripts/validate-deployment.sh`) — A shell script that validates:
   - Podman is installed and running
   - Ollama container starts successfully
   - API health check passes
   - Container resources are configured correctly

4. **Deployment Documentation** — Clear step-by-step instructions for users to deploy from this repo on their Pi 5.

5. **Capability Contract Documentation** — Explanation of the `capability.json` schema so others can create additional capabilities (speech-to-text, vision, retrieval, etc.).

### Architectural Context

This capability is part of the **eZansiEdgeAI** platform vision:
- **Ncane** (small): Lightweight, containerized modules
- **Shesha** (fast): Low-latency edge execution  
- **Khanya** (light): Minimal overhead on constrained hardware
- **Umngcele** (edge): Intelligence at the network edge

The modular "capability contract" pattern allows different AI services to be discovered, wired together, and orchestrated into learning stacks without code changes. This is the foundation implementation.

---

## What This Capability Does

Runs a local LLM using [Ollama](https://ollama.ai) in a containerized environment and exposes it as a REST API for text-generation tasks. The API can be called to:
- List available models
- Generate text from prompts
- Stream responses
- Manage local model downloads

---

## Resource Requirements

| Resource | Requirement |
|----------|-------------|
| RAM      | 6 GB (limit), 4 GB (reserved) |
| CPU      | 4 cores (recommended Pi 5 minimum) |
| Storage  | 8 GB+ (for model data) |
| Disk I/O | SSD or USB 3.0+ recommended |

---

## Prerequisites

### 1. Prepare Your Raspberry Pi 5

Ensure your Pi is running a supported OS (Raspberry Pi OS 64-bit recommended) and has:
- Podman and podman-compose installed
- User-level Podman access configured
- Sufficient storage for model data

**Installation commands:**

```bash
# Install Podman and podman-compose
sudo apt update
sudo apt install -y podman podman-compose

# Verify installation
podman --version
podman-compose --version

# Enable user-level Podman persistence (survive logout/reboot)
loginctl enable-linger $USER

# Verify Podman daemon is accessible
podman ps
```

### 1b. Configure User-Level Podman Access

**Why this matters:** By default, Podman containers run as your user (rootless Podman). For containers to survive logout/reboot and run as expected on a Pi, you must enable user lingering and configure the Podman socket.

**Check current status:**

```bash
# Check if your user has linger enabled
loginctl show-user $USER | grep Linger

# Expected output: Linger=yes
```

**If Linger=no, enable it:**

```bash
# Enable user lingering (allows services to run after logout)
loginctl enable-linger $USER

# Verify it's enabled
loginctl show-user $USER | grep Linger
```

**Start the Podman socket service (rootless):**

```bash
# Start the user-level Podman socket service
systemctl --user start podman.socket

# Enable it to start on boot
systemctl --user enable podman.socket

# Verify it's running
systemctl --user status podman.socket
```

**Set environment variable for Podman CLI (optional but recommended):**

Add this to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
```

Then reload:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

**Verify everything works:**

```bash
# Test basic Podman commands
podman ps
podman images

# Should work without sudo
```

**Troubleshooting:**

If you get permission errors:
```bash
# Check if the socket exists
ls -la /run/user/$(id -u)/podman/

# If socket doesn't exist, start the service again
systemctl --user restart podman.socket

# Verify it's running
systemctl --user is-active podman.socket
```

### 1c. Enable Memory Controller in cgroups (Required for Resource Limits)

**Why this matters:** Podman resource limits (memory, CPU) require the memory controller to be enabled in cgroups. This must be explicitly configured via boot parameters on Raspberry Pi OS.

**Check if memory controller is available:**

```bash
cat /sys/fs/cgroup/cgroup.controllers
# Should show: cpuset cpu io memory pids
# If you see only: cpuset cpu io pids (memory missing)
# Then follow the steps below
```

**Enable memory controller:**

1. Edit boot configuration:
```bash
sudo nano /boot/firmware/cmdline.txt
# Or on older Pi OS: sudo nano /boot/cmdline.txt
```

2. **Move to the END of the existing line** (use Ctrl+E or End key, don't create new line) and add:
```
cgroup_enable=memory cgroup_memory=1
```

**Example:** Your line should look like:
```
console=serial0,115200 console=tty1 root=PARTUUID=xxxxx rootfstype=ext4 fsck.repair=yes rootwait quiet splash cfg80211.ieee80211_regdom=GB cgroup_enable=memory cgroup_memory=1
```

3. Save and reboot:
```bash
# Press Ctrl+X, then Y, then Enter
sudo reboot
```

4. Verify after reboot:
```bash
cat /sys/fs/cgroup/cgroup.controllers
# Should now show: cpuset cpu io memory pids
```

**If you skip this step:** Container will start but resource limits won't be enforced, potentially consuming all system resources.

For troubleshooting, see [docs/troubleshooting.md](docs/troubleshooting.md#memory-limit-errors-cgroups).

### 2. Clone This Repository

```bash
git clone https://github.com/your-org/ezansi-capability-llm-ollama.git
cd ezansi-capability-llm-ollama
```

---

## Deployment Instructions

### Step 1: Start the Ollama Container

From the repository root, run:

```bash
podman-compose up -d
```

This will:
- Pull the Ollama image from Docker Hub (first run only)
- Create and start the `ollama-llm-capability` container
- Expose the API on `http://localhost:11434`
- Create a persistent volume for model data

### Step 2: Validate Deployment

Run the automated validation script to ensure the service is healthy:

```bash
./scripts/validate-deployment.sh
```

This script checks:
- ✓ Podman is installed and running
- ✓ Ollama container is up and responding
- ✓ API health endpoint returns data
- ✓ Resource limits are configured
- ✓ Container is ready for use

**Expected output:** All checks pass with green indicators.

### Step 3: Pull a Language Model

Before generating text, pull a model. Start with a lightweight model for Pi 5:

```bash
# Pull Mistral (7B, recommended for Pi 5)
curl -X POST http://localhost:11434/api/pull -d '{"name":"mistral"}'

# Or pull Llama 2 (7B alternative)
curl -X POST http://localhost:11434/api/pull -d '{"name":"llama2"}'

# Or pull Neural Chat (lighter, faster)
curl -X POST http://localhost:11434/api/pull -d '{"name":"neural-chat"}'
```

Models download to the persistent volume (`ollama-data`). First pull takes time depending on internet and Pi storage speed.

### Step 4: Test Text Generation

Once a model is loaded, generate text:

```bash
curl -X POST http://localhost:11434/api/generate \
  -d '{"model":"mistral","prompt":"Explain quantum computing in one sentence"}' \
  -H "Content-Type: application/json"
```

For streaming responses:

```bash
curl -X POST http://localhost:11434/api/generate \
  -d '{"model":"mistral","prompt":"Hello","stream":true}' \
  -H "Content-Type: application/json"
```

---

## Health Checks

### Check If Service Is Running

```bash
# List running containers
podman ps

# Expected: ollama-llm-capability container should be listed
```

### Check API Responsiveness

```bash
# List available models
curl http://localhost:11434/api/tags

# Expected JSON response with "models" array
```

### View Container Logs

```bash
podman logs ollama-llm-capability

# Follow logs in real-time
podman logs -f ollama-llm-capability
```

### Check Resource Usage

```bash
podman stats ollama-llm-capability

# Expected: RAM usage ~4-6 GB depending on model, CPU ~0-100% during inference
```

---

## Stopping and Cleaning Up

### Stop the Container

```bash
podman-compose down
```

This stops the container but preserves model data in the volume.

### Remove Everything (Including Models)

```bash
podman-compose down -v
```

**Warning:** This deletes all downloaded models. Re-pulling takes time.

---

## Understanding the Capability Contract

### What is `capability.json`?

The `capability.json` file is a **capability contract** — a standardized interface that defines:
- What service this provides (`text-generation`)
- How to reach it (`http://localhost:11434`)
- What resources it needs (6GB RAM, 4 CPU cores)
- What container implements it (`docker.io/ollama/ollama`)

This contract enables the eZansiEdgeAI platform to:
1. **Discover** capabilities available on a device
2. **Check** if a device has enough resources
3. **Wire together** multiple capabilities into learning stacks
4. **Orchestrate** workflows without hardcoding service addresses

### Creating Additional Capabilities

To add a new capability (e.g., speech-to-text, vision, retrieval), create a similar contract:

```json
{
  "name": "capability-name",
  "version": "1.0",
  "description": "What this capability does",
  "provides": ["service-type"],
  "api": {
    "endpoint": "http://localhost:<port>",
    "type": "REST",
    "health_check": "/health"
  },
  "resources": {
    "ram_mb": 2000,
    "cpu_cores": 2,
    "storage_mb": 1000
  },
  "container": {
    "image": "container/image:tag",
    "port": <port>,
    "restart_policy": "unless-stopped"
  },
  "target_platform": "Raspberry Pi 5"
}
```

Additional capabilities follow the same modular pattern, allowing them to be combined into learning stacks.

See [docs/capability-contract-spec.md](docs/capability-contract-spec.md).

---

## Development Plan

### Phase 1: Validate Base Capability (Next)

1. **Pull a model and test text generation**
   ```bash
   ./scripts/pull-model.sh mistral
   curl -X POST http://localhost:11434/api/generate \
     -d '{"model":"mistral","prompt":"Hello"}' \
     -H "Content-Type: application/json"
   ```

2. **Run test suite**
   ```bash
   ./tests/test-api.sh          # Verify API
   ./tests/test-performance.sh  # Measure speed
   ```

### Phase 2: Expand Ecosystem (Soon)

3. **Create second capability** (Whisper STT or Piper TTS)
   - Follow same pattern as capability-llm-ollama
   - Own capability.json contract
   - Separate repository

4. **Build platform-core repo**
   - Registry service (discovery)
   - Orchestrator (capability matching)
   - Gateway (single entry point)

5. **Implement basic registry**
   - File-based v1 (simple, debuggable)
   - Capability discovery
   - Auto-registration

6. **Create example stack.yaml**
   - Voice assistant: STT → LLM → TTS
   - Document composition pattern
   - Show how orchestrator wires capabilities

### Phase 3: Orchestration & Composition (Future)

- Multi-stack management
- Resource constraint checking
- Dynamic capability wiring
- Student-facing UI shell

---

## Quick Reference

### Helper Scripts

Located in `scripts/`:

- **deploy.sh** - Complete deployment with validation
- **validate-deployment.sh** - Post-deployment health checks
- **pull-model.sh** - Download and configure models
- **health-check.sh** - Quick health status

Usage:
```bash
./scripts/deploy.sh              # Deploy everything
./scripts/pull-model.sh mistral  # Pull a model
./scripts/health-check.sh        # Check if healthy
```

### Device Configurations

Pre-configured setups for different hardware. Choose one based on your device:

**For Raspberry Pi 5 (16GB):**
```bash
# Option 1: Use the dedicated Pi 5 compose file
podman-compose -f podman-compose.pi5.yml up -d

# Option 2: Copy the config file
cp config/pi5-16gb.yml podman-compose.yml
podman-compose up -d
```

**For Raspberry Pi 4 (8GB or less):**
```bash
cp config/pi4-8gb.yml podman-compose.yml
podman-compose up -d
```

**Configuration files available:**
- **podman-compose.pi5.yml** - Optimized for Pi 5 (12GB limit, supports Mistral)
- **config/pi5-16gb.yml** - Equivalent config file for Pi 5
- **config/pi4-8gb.yml** - Conservative settings for Pi 4 (5GB limit)
- **device-constraints.json** - Device capability reference

### Testing

Integration and performance tests in `tests/`:

```bash
./tests/test-api.sh          # API functionality tests
./tests/test-performance.sh  # Measure generation speed
```

---

## Documentation

Comprehensive guides available in `docs/`:

- **[Architecture](docs/architecture.md)** - System design and principles
- **[Performance Tuning](docs/performance-tuning.md)** - Optimization for Pi models
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Capability Contract Spec](docs/capability-contract-spec.md)** - Contract schema details

---

## Project Structure

```
ezansi-capability-llm-ollama/
├── capability.json           # Capability contract
├── podman-compose.yml        # Main deployment configuration
├── README.md                 # This file
├── CHANGELOG.md              # Version history
├── LICENSE                   # License information
├── scripts/                  # Helper scripts
│   ├── deploy.sh
│   ├── validate-deployment.sh
│   ├── pull-model.sh
│   └── health-check.sh
├── config/                   # Device-specific configs
│   ├── pi5-16gb.yml
│   ├── pi4-8gb.yml
│   └── device-constraints.json
├── tests/                    # Integration tests
│   ├── test-api.sh
│   ├── test-performance.sh
│   └── README.md
├── docs/                     # Documentation
│   ├── architecture.md
│   ├── performance-tuning.md
│   ├── troubleshooting.md
│   ├── capability-contract-spec.md
│   └── README.md
└── notes/                    # Research and planning
    └── research.md
```

---

## Next Steps

Once the base capability is validated:

1. **Build additional capabilities:** Speech-to-text, vision, retrieval, embeddings
2. **Implement capability registry:** Central discovery service for available capabilities
3. **Build orchestrator:** Wire capabilities into learning stacks (study-buddy, podcast generator, etc.)
4. **Add UI shell:** Web interface for end-users to compose and run stacks

See [notes/research.md](notes/research.md) for the complete roadmap.

---

## References

- [Ollama Official Docs](https://github.com/ollama/ollama)
- [Podman Documentation](https://docs.podman.io/)
- [Raspberry Pi 5 Specifications](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [eZansiEdgeAI Research](notes/research.md)
- [Deployment & Portability Guide](docs/deployment-guide.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Performance Tuning](docs/performance-tuning.md)

---

## License

See [LICENSE](LICENSE) file.
