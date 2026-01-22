# Copilot Instructions: ezansi-capability-llm-ollama

## Repository Overview

**Purpose:** Provides a containerized Ollama LLM capability for text generation in the eZansiEdgeAI platform.

**Type:** Infrastructure/Deployment repository (container orchestration, not application code)

**Size:** ~50 files, primarily shell scripts, YAML configs, and documentation

**Languages/Frameworks:**
- Shell scripts (bash) for deployment automation
- YAML for Podman Compose configurations
- JSON for capability contract specification
- No application source code (uses upstream Ollama container)

**Target Platforms:**
- Raspberry Pi 4/5 (ARM64) - primary target
- AMD64 (x86-64) Linux servers/workstations - secondary target

**Runtime:** Podman (rootless container runtime) with podman-compose

---

## Critical Build & Validation Information

### Prerequisites (ALWAYS Required)

**On local development machine or CI:**
- Podman installed (`sudo apt install -y podman`)
- **podman-compose is NOT required** - this repo has no automated podman-compose tests because podman-compose is not available in GitHub Actions. Tests use direct curl commands instead.
- curl installed (`sudo apt install -y curl`)
- jq for JSON parsing (optional but helpful)
- yamllint for YAML validation

**On target deployment systems (Raspberry Pi/AMD64):**
- Podman and podman-compose installed
- User-level Podman access configured (loginctl enable-linger, podman.socket)
- Memory controller enabled in cgroups (Raspberry Pi only - requires boot params)

### Build Commands (Sequential Order)

**Important:** This repository has NO traditional build process. It's a deployment configuration repository.

1. **Validate configuration files:**
   ```bash
   # Validate all YAML files
   yamllint -d relaxed podman-compose*.yml config/*.yml
   
   # Validate JSON capability contract
   jq empty capability.json
   ```

2. **Syntax check shell scripts:**
   ```bash
   bash -n scripts/*.sh tests/*.sh
   ```

3. **Deployment test (if Podman available):**
   ```bash
   # Start container
   podman-compose up -d
   
   # Wait for startup (30+ seconds)
   sleep 30
   
   # Validate deployment
   ./scripts/validate-deployment.sh
   
   # Cleanup
   podman-compose down
   ```

**Time Requirements:**
- YAML/JSON validation: <5 seconds
- Script syntax check: <2 seconds
- Container deployment (if tested): 30-60 seconds for container start

### Testing Commands

**API Integration Tests:**
```bash
# Prerequisite: Ollama container must be running
./tests/test-api.sh
# Exit code 0 = pass, 1 = fail
# Takes ~5-10 seconds (or longer if model needs to generate text)
```

**Performance Tests:**
```bash
# Prerequisite: Container running + model pulled
./tests/test-performance.sh
# Interactive - prompts for model selection
# Takes 10-60 seconds depending on model
```

**Important:** Tests CANNOT run in CI/CD without a running Ollama instance. Tests are meant for manual validation on deployment targets.

### Linting

**Shell Scripts:**
```bash
# Use shellcheck if available
shellcheck scripts/*.sh tests/*.sh

# Fallback: bash syntax check (already covered above)
bash -n scripts/*.sh tests/*.sh
```

**YAML Files:**
```bash
yamllint -d relaxed podman-compose*.yml config/*.yml
```

**JSON Files:**
```bash
jq empty capability.json config/device-constraints.json
```

### Deployment Validation Workflow

**Complete validation sequence (manual, not CI):**
```bash
# 1. Validate configs
yamllint -d relaxed podman-compose.yml
jq empty capability.json

# 2. Deploy container
podman-compose up -d

# 3. Wait for readiness
sleep 30

# 4. Run validation script
./scripts/validate-deployment.sh
# Expected: All checks pass with green OK indicators

# 5. Pull a test model (takes 5-10 minutes)
./scripts/pull-model.sh mistral

# 6. Run API tests
./tests/test-api.sh

# 7. Cleanup
podman-compose down
```

---

## Project Layout & Architecture

### Root Files (Important)

- **capability.json** - Capability contract defining service interface (text-generation API)
- **podman-compose.yml** - Default deployment config (6GB RAM, 4 CPU - Raspberry Pi optimized)
- **podman-compose.pi5.yml** - Pi 5 preset (12GB RAM, 4 CPU)
- **podman-compose.amd64.yml** - AMD64 preset (20GB RAM, 8 CPU)
- **README.md** - Primary documentation (deployment guide, prerequisites, usage)
- **CHANGELOG.md** - Version history and release notes

### Directory Structure

```
/
├── .github/
│   ├── ISSUE_TEMPLATE/          # Issue templates only (no workflows)
│   └── copilot-instructions.md  # This file
├── config/                       # Device-specific presets
│   ├── amd64-24gb.yml           # AMD64 with 24GB RAM
│   ├── amd64-32gb.yml           # AMD64 with 32GB+ RAM
│   ├── pi4-8gb.yml              # Raspberry Pi 4 (8GB)
│   ├── pi5-16gb.yml             # Raspberry Pi 5 (16GB)
│   └── device-constraints.json  # Device capability reference
├── scripts/                      # Deployment automation
│   ├── deploy.sh                # Full deployment (compose + validation)
│   ├── validate-deployment.sh   # Post-deployment health checks
│   ├── pull-model.sh            # Download Ollama models
│   └── health-check.sh          # Quick API liveness check
├── tests/                        # Integration tests
│   ├── test-api.sh              # API functionality tests
│   ├── test-performance.sh      # Performance benchmarks
│   └── README.md                # Test documentation
└── docs/                         # Extended documentation
    ├── architecture.md           # Platform design principles
    ├── capability-contract-spec.md
    ├── deployment-guide.md
    ├── deployment-guide-amd64.md
    ├── performance-tuning.md
    └── troubleshooting.md
```

### Key Configuration Patterns

**Podman Compose Files Structure:**
All compose files follow this pattern:
```yaml
version: '3.8'
services:
  ollama:
    image: docker.io/ollama/ollama
    container_name: ollama-llm-capability
    network_mode: host                    # IMPORTANT: Avoids DNS issues during model pulls
    volumes:
      - ollama-data:/root/.ollama         # Persistent model storage
    deploy:
      resources:
        limits:
          memory: <DEVICE_SPECIFIC>       # 6g (Pi), 12g (Pi5), 20g (AMD64)
          cpus: '<CORES>'                 # 4 (Pi), 8 (AMD64)
        reservations:
          memory: <RESERVED>              # 4g (Pi), 8g (Pi5), 16g (AMD64)
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "ollama", "list"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s                  # Container needs time to initialize
    environment:
      - OLLAMA_NUM_PARALLEL=<PARALLEL>   # 4 (Pi), 8 (AMD64)
      - OLLAMA_MAX_LOADED_MODELS=<MAX>   # Optional: 1-4 depending on RAM
```

**Capability Contract (capability.json):**
Defines service interface for platform discovery:
- `provides`: ["text-generation"]
- `api.endpoint`: "http://localhost:11434"
- `api.health_check`: "/api/tags"
- `resources`: RAM/CPU/storage requirements
- `container.image`: "docker.io/ollama/ollama"

---

## Common Issues & Workarounds

### Issue 1: podman-compose not available in CI/CD

**Problem:** GitHub Actions doesn't have podman-compose pre-installed.

**Workaround:** This repository does NOT run container deployment tests in CI. All testing is manual on actual deployment targets. If adding CI workflows in the future, use:
```yaml
# Don't use podman-compose in CI
# Instead: validate configs only
- yamllint podman-compose.yml
- jq empty capability.json
```

### Issue 2: Container health check uses "ollama list" (not HTTP)

**Problem:** Initial health check used HTTP endpoint which could fail during startup.

**Current Implementation:** Uses `["CMD", "ollama", "list"]` which checks internal service readiness.

**Note:** API tests use curl to check HTTP endpoint separately.

### Issue 3: network_mode: host is REQUIRED

**Problem:** Bridge networking causes DNS resolution failures when Ollama pulls models from huggingface.co.

**Solution:** ALWAYS use `network_mode: host` in all compose files. Do not change this.

**Why:** Ollama needs to download models from external sources. Bridge networking on Podman can have DNS issues.

### Issue 4: Memory controller required on Raspberry Pi

**Problem:** Resource limits in compose files fail silently if memory controller not enabled in cgroups.

**Detection:**
```bash
cat /sys/fs/cgroup/cgroup.controllers
# Should include "memory" in output
```

**Solution (Raspberry Pi only):**
Edit `/boot/firmware/cmdline.txt`, add to END of existing line:
```
cgroup_enable=memory cgroup_memory=1
```
Then reboot.

**AMD64:** Usually works by default, no boot params needed.

### Issue 5: Validation script can timeout on slow devices

**Problem:** `validate-deployment.sh` waits max 30 seconds for API, but Pi 4 can take longer.

**Current Implementation:** Script has 30 attempts with 1 second sleep = adequate for most cases.

**If timeout occurs:** Increase `MAX_ATTEMPTS` in validate-deployment.sh or add explicit sleep before running script.

---

## Validation Checklist for Code Changes

Before submitting PR, ALWAYS verify:

### Configuration Changes
- [ ] Run `yamllint -d relaxed <modified.yml>` (must pass)
- [ ] Run `jq empty <modified.json>` (must pass)
- [ ] Check that `network_mode: host` is preserved
- [ ] Verify memory limits are appropriate for target device
- [ ] Ensure health check uses `["CMD", "ollama", "list"]`

### Script Changes
- [ ] Run `bash -n <script.sh>` (syntax check must pass)
- [ ] If available, run `shellcheck <script.sh>`
- [ ] Verify script has execute permissions (`chmod +x`)
- [ ] Test script manually if possible

### Documentation Changes
- [ ] Update CHANGELOG.md if functionality changes
- [ ] Update README.md if deployment steps change
- [ ] Check markdown syntax (use markdownlint if available)

### Testing Changes
- [ ] Test scripts must handle "no model installed" gracefully
- [ ] Use environment variables for configuration (OLLAMA_URL, TEST_MODEL)
- [ ] Return proper exit codes (0=pass, 1=fail)
- [ ] Include colored output for readability (GREEN/RED/YELLOW)

---

## Architecture Notes

### This is NOT a Code Repository

**Important:** There is NO application code to compile or build. This repository provides:
1. Container orchestration configuration (podman-compose.yml variants)
2. Capability contract specification (capability.json)
3. Deployment automation scripts (shell scripts)
4. Integration tests (shell scripts using curl)
5. Documentation

**Upstream Service:** Ollama (docker.io/ollama/ollama) provides the actual LLM runtime.

### Modular Capability Pattern

This capability follows the eZansiEdgeAI "LEGO brick" pattern:
- **Contract-first interface** (capability.json declares what it provides)
- **Platform-agnostic** (works on ARM64 and AMD64)
- **Composable** (can be wired with other capabilities like speech-to-text)
- **Resource-aware** (declares RAM/CPU needs for platform scheduling)

### API Endpoints

Ollama exposes REST API on port 11434:
- `GET /api/tags` - List installed models (health check)
- `POST /api/pull` - Download a model
- `POST /api/generate` - Generate text from prompt
- `POST /api/chat` - Chat completion

**Examples in scripts:**
- `scripts/pull-model.sh` - Uses /api/pull
- `tests/test-api.sh` - Uses /api/tags and /api/generate

---

## Making Changes: Key Principles

### When Modifying Compose Files

1. **ALWAYS preserve `network_mode: host`** - Required for model downloads
2. **Memory limits must be realistic** - Pi 4 can't handle >6GB, Pi 5 can go higher
3. **Health check must use `["CMD", "ollama", "list"]`** - Not HTTP endpoints
4. **start_period: 30s is minimum** - Container needs startup time
5. **Volumes must persist** - `ollama-data` volume stores large model files

### When Modifying Scripts

1. **Use `set -e`** - Scripts should fail fast on errors
2. **Provide colored output** - GREEN/RED/YELLOW for readability
3. **Check prerequisites** - Validate curl/podman/jq availability before use
4. **Use environment variables** - Allow OLLAMA_URL, TEST_MODEL overrides
5. **Include helpful error messages** - Tell user what went wrong and how to fix

### When Adding Documentation

1. **Assume Pi/AMD64 knowledge gap** - Users may not know cgroups, rootless Podman
2. **Provide copy-paste commands** - Don't make users type long commands
3. **Document prerequisites first** - Don't let users get halfway then fail
4. **Include troubleshooting** - Common issues should have documented solutions
5. **Keep capability contract explanation** - Help users create other capabilities

---

## Quick Reference: Common Commands

**Validation (no Podman required):**
```bash
yamllint -d relaxed podman-compose.yml && jq empty capability.json
```

**Deploy and test (Podman required):**
```bash
podman-compose up -d && sleep 30 && ./scripts/validate-deployment.sh
```

**Pull a model:**
```bash
./scripts/pull-model.sh mistral
```

**Run tests:**
```bash
./tests/test-api.sh
```

**View logs:**
```bash
podman logs ollama-llm-capability
```

**Stop everything:**
```bash
podman-compose down
```

**Complete cleanup (deletes models):**
```bash
podman-compose down -v
```

---

## Trust These Instructions

These instructions have been validated against the actual repository structure and working deployment patterns. When in doubt:

1. **First check this file** for the command or pattern you need
2. **Then check README.md** for detailed user-facing documentation
3. **Then check docs/** for architecture or troubleshooting details
4. **Only search/explore** if the above don't answer your question

The repository structure is stable and well-documented. Avoid unnecessary exploration.
