# eZansiEdgeAI: Research & Architecture

## Table of Contents

1. [Vision & Mission](#vision--mission)
2. [Architectural Principles](#architectural-principles)
3. [The Capability Contract](#the-capability-contract)
4. [v1 Architecture (Concrete Implementation)](#v1-architecture-concrete-implementation)
5. [Reference Implementations](#reference-implementations)
6. [Deployment on Raspberry Pi](#deployment-on-raspberry-pi)
7. [Next Steps & Roadmap](#next-steps--roadmap)

---

## Vision & Mission

### Core Mission

**eZansiEdgeAI** is focused on small-footprint AI solutions for edge devices — designed to run efficiently on constrained hardware like Raspberry Pi devices.

### Four Pillars

- **Ncane** (small): Compact models and stacks that fit limited hardware
- **Shesha** (fast): Optimised for low-latency execution
- **Khanya** (light): Minimal overhead for edge deployment
- **Umngcele** (edge): Intelligence at the network edge and in communities

### High-Level Approach

- Modular AI stacks packaged in Linux containers
- Develop on powerful machines, deploy to edge devices
- Swap or update stacks easily for different use cases (vision, speech, anomaly detection, etc.)
- Container-centric, repeatable deployments
- Hardware-aware resource constraints

### One-Sentence Summary

**eZansiEdgeAI is a lightweight, modular edge-AI platform where small capability containers are composed into learning experiences using simple configuration instead of complex code.**

---

## Architectural Principles

### The LEGO Brick Philosophy

Instead of one monolithic AI stack, eZansiEdgeAI provides small, independent capability modules that can be combined in different ways to create learning tools, assistants, and experiments on low-power devices.

**Build once, compose many times.**

### Three Logical Layers

#### 🧱 Platform Core (Stable)

- Runs on the device
- Handles startup, configuration, discovery, and routing
- Knows nothing about AI models
- *Changes rarely*

#### 🧱 Capability Modules (Replaceable)

- Each module does one thing well
- Exposes a standard capability contract
- Declares its resource needs (RAM, CPU)
- Can be swapped without breaking the system

#### 🧱 Experience Stacks (Composable)

- Defined in simple YAML files
- Describe what capabilities are needed, not how they work
- Can be created or modified by students and educators
- Example: "Take speech → generate text → speak the answer"

### Contracts Over Code

All modules follow a standard capability contract defining:

- What they provide
- How to call them
- What resources they need

This enables:

- Easy swapping of models
- Hardware-aware deployment
- Safe experimentation

### Lightweight Orchestration

A small orchestrator:

- Discovers available capabilities
- Connects them into pipelines
- Ensures the device can support the requested stack

**No hard-coded models. No fixed stacks.**

---

## The Capability Contract

### What Is a Capability Contract?

The `capability.json` file is a **capability contract** — a standardized interface that defines:

- What service this provides (e.g., `text-generation`)
- How to reach it (endpoint URL, API path)
- What resources it needs (RAM, CPU, storage)
- What container implements it

This contract enables the eZansiEdgeAI platform to:

1. **Discover** capabilities available on a device
2. **Check** if a device has enough resources
3. **Wire together** multiple capabilities into learning stacks
4. **Orchestrate** workflows without hardcoding service addresses

### Standard Capability Contract (v1 Schema)

Every capability exposes this contract:

```json
{
  "name": "capability-name",
  "version": "1.0",
  "type": "capability",
  "description": "What this capability does",
  "provides": ["service-type"],
  "requires": [],
  "resources": {
    "ram_mb": 2000,
    "cpu_cores": 2,
    "storage_mb": 1000
  },
  "endpoints": {
    "service-name": {
      "method": "POST",
      "path": "/api/endpoint",
      "input": "application/json",
      "output": "application/json"
    }
  }
}
```

### Five Core Capability Types

Do not invent more yet.

| Capability | Provides | Examples |
|-----------|----------|----------|
| **llm** | `text-generation` | llama.cpp, Ollama, Phi |
| **stt** | `speech-to-text` | Whisper |
| **tts** | `text-to-speech` | Piper |
| **vision** | `image-analysis` | OpenCV, YOLO |
| **retrieval** | `vector-search` | FAISS |

Everything else builds on these.

### Why Contracts Work

✅ Human readable  
✅ Machine discoverable  
✅ Hardware aware  
✅ Versionable  
✅ Stack-agnostic  

**🔒 Rule:** If a container doesn't expose this contract → it doesn't belong in eZansiEdgeAI.

---

## v1 Architecture (Concrete Implementation)

### What You Are Building First (v1)

A minimal platform + one capability:

> A Raspberry Pi–ready platform core that can run an Ollama LLM as a discoverable, constrained capability.

**Not yet:**
- Speech capabilities
- UI
- Multi-stack orchestration

**Just:**
- ✅ Platform core (minimal)
- ✅ Ollama LLM capability
- ✅ Resource constraints
- ✅ Clear separation

### The v1 Architecture (Smallest Useful System)

```
Raspberry Pi
└── Podman
    ├── platform-registry      (tiny)
    ├── platform-orchestrator  (very thin)
    └── capability-llm-ollama  (actual AI)
```

Three containers. That's it.

### Component 1: Platform Registry (v1 = Dumb & File-Based)

**Purpose:** Store available capabilities and their endpoints

**File:** `registry.json`

```json
{
  "text-generation": "http://ollama:11434"
}
```

No service discovery yet. Keep it stupid.

### Component 2: Platform Orchestrator (v1 = Validator, Not Brain)

**Responsibilities:**

- Load device constraints
- Load registry
- Check resource availability
- Say "yes" or "no"

**Pseudocode:**

```python
device = yaml.safe_load(open("device.yaml"))
registry = json.load(open("registry.json"))

def can_run(capability):
    return capability["resources"]["ram_mb"] < device["ram_mb"]
```

That's all it does for now. No AI logic. No hardcoding. No model knowledge.

### Component 3: Ollama Capability (Where AI Lives)

**Repo:** `capability-llm-ollama`

**Purpose:** Run Ollama as a discoverable, constrained capability

#### Contract Definition

```json
{
  "name": "ollama-llm",
  "version": "1.0",
  "provides": ["text-generation"],
  "description": "Local LLM using Ollama",
  "resources": {
    "ram_mb": 6000,
    "cpu_cores": 4
  },
  "endpoints": {
    "generate": {
      "method": "POST",
      "path": "/api/generate",
      "input": "application/json",
      "output": "application/json"
    }
  }
}
```

#### Container Specification

```yaml
services:
  ollama:
    image: docker.io/ollama/ollama
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    deploy:
      resources:
        limits:
          memory: 6g
        cpus: "4"
    environment:
      - OLLAMA_NUM_PARALLEL=4
    restart: unless-stopped

volumes:
  ollama-data:
```

**Key Design Decisions:**

- Constraints live with the capability, not in platform core
- Resource limits match Raspberry Pi 5 16GB specifications
- Persistent volume for model data
- Auto-restart on failure
- Health checks to verify availability

---

## Reference Implementations

### Stack: Speech-to-Text + Generation + Speech

**Capabilities needed:**

| Container | Capability |
|-----------|------------|
| whisper-stt | `speech-to-text` |
| ollama-llm | `text-generation` |
| piper-tts | `text-to-speech` |

**Stack definition:**

```yaml
name: voice-assistant
description: Take speech, generate response, speak it back
pipeline:
  - speech-to-text
  - text-generation
  - text-to-speech
constraints:
  max_ram_mb: 7000
```

### Stack: Vision Analysis

**Capabilities needed:**

| Container | Capability |
|-----------|------------|
| vision-basic | `image-analysis` |
| ollama-llm | `text-generation` |

**Contract example:**

```json
{
  "name": "vision-basic",
  "provides": ["image-analysis"],
  "resources": {
    "ram_mb": 2000,
    "cpu_cores": 2
  },
  "endpoints": {
    "analyze": {
      "method": "POST",
      "path": "/analyze",
      "input": "image/jpeg",
      "output": "application/json"
    }
  }
}
```

### Stack: Retrieval-Augmented Generation (RAG)

**Capabilities needed:**

| Container | Capability |
|-----------|------------|
| faiss-retrieval | `vector-search` |
| ollama-llm | `text-generation` |

**Pipeline logic:**

```
Input Query → Vector Search (FAISS) → Retrieval Results → LLM Context → Generated Response
```

---

## Deployment on Raspberry Pi

### Prerequisites

#### 1. Install Podman

```bash
sudo apt update
sudo apt install -y podman podman-compose

# Verify installation
podman --version
podman-compose --version
```

#### 2. Enable User-Level Podman Access

```bash
# Enable lingering (allow containers to survive logout/reboot)
loginctl enable-linger $USER

# Start Podman socket service
systemctl --user start podman.socket

# Enable on boot
systemctl --user enable podman.socket

# Verify it's running
systemctl --user status podman.socket
```

#### 3. Verify Podman Access

```bash
# Test basic commands (no sudo)
podman ps
podman images
```

### Deploying Ollama Capability

#### Quick Start

```bash
# Clone the repo
git clone https://github.com/your-org/ezansi-capability-llm-ollama.git
cd ezansi-capability-llm-ollama

# Start container
podman-compose up -d

# Validate deployment
./scripts/validate-deployment.sh

# Pull a model
curl -X POST http://localhost:11434/api/pull -d '{"name":"mistral"}'

# Test generation
curl -X POST http://localhost:11434/api/generate \
  -d '{"model":"mistral","prompt":"Hello"}' \
  -H "Content-Type: application/json"
```

#### Full Registry Configuration

If running platform registry:

```bash
# Register the capability
curl -X POST http://registry:9090/register \
  -d @capability.json \
  -H "Content-Type: application/json"

# Verify registration
curl http://registry:9090/capabilities
```

### Testing & Validation

#### Health Check

```bash
curl http://localhost:11434/api/tags
```

Expected response:

```json
{
  "models": [
    {
      "name": "mistral:latest",
      "modified_at": "2024-01-14T10:30:00Z",
      "size": 4000000000
    }
  ]
}
```

#### Monitor Resource Usage

```bash
# View container stats
podman stats ollama

# Check logs
podman logs ollama

# Follow logs in real-time
podman logs -f ollama
```

#### Troubleshooting

**Podman daemon not running:**

```bash
systemctl --user restart podman.socket
systemctl --user status podman.socket
```

**Container won't start:**

```bash
# Check logs
podman logs ollama

# Restart
podman restart ollama

# Recreate if needed
podman-compose down
podman-compose up -d
```

**Image pull fails:**

```bash
# Use fully qualified image name
podman pull docker.io/ollama/ollama

# Or configure default registry
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee -a /etc/containers/registries.conf
```

---

## Next Steps & Roadmap

### v1 Exit Criteria (You Are Here)

✅ Ollama runs on the Pi  
✅ Memory is capped at 6GB  
✅ Capability is described via `capability.json`  
✅ Platform knows it provides `text-generation`  
✅ You can curl Ollama through the platform  

**Test:**

```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"mistral","prompt":"Hello"}' \
  -H "Content-Type: application/json"
```

### v2 Work (In Strict Order)

1. **Add Whisper STT capability**
   - Second capability = validate modularity works
   - Container: `capability-stt-whisper`

2. **Build platform-core repo**
   - Lightweight registry
   - Resource tracker
   - Basic orchestrator

3. **Add stack.yaml support**
   - Define pipeline declaratively
   - Orchestrator connects capabilities

4. **Add Whisper → Ollama → Piper pipeline**
   - Validate multi-capability composition
   - Test resource constraints

5. **Add basic API gateway**
   - Single entry point for all capabilities
   - Request routing to correct service

6. **Add student-facing UI shell**
   - Web interface for testing
   - Stack definition UI
   - Model management

### Repository Structure

```
eZansiEdgeAI/
├── platform-core/
│   ├── registry/
│   ├── orchestrator/
│   └── gateway/
├── capabilities/
│   ├── llm-ollama/
│   ├── stt-whisper/
│   ├── tts-piper/
│   ├── vision-basic/
│   └── retrieval-faiss/
├── stacks/
│   ├── voice-assistant.yaml
│   ├── rag-search.yaml
│   └── vision-lab.yaml
└── docs/
    ├── capability-contract-spec.md
    ├── stack-design.md
    └── student-guide.md
```

### Why This Order Matters

1. **v1 (now):** Validate single capability works
2. **v2 (next):** Validate multiple capabilities work
3. **v3:** Validate composition works
4. **v4:** Validate education use cases work

Each step validates modularity assumptions before building the next layer.

### Key Principles (Don't Break These)

- **Capabilities must be dumb** — No orchestration logic inside containers
- **Stacks must be declarative** — Define intent, not implementation
- **Orchestration must be minimal** — Small, stateless, composable

**Break this rule and the system collapses.**

---

## Design Decisions Summary

| Decision | Rationale |
|----------|-----------|
| **One capability per repo** | Clear ownership boundaries, independent versioning |
| **Standard contract in every capability** | Enables discovery and composition without hardcoding |
| **Podman instead of Docker** | Better for rootless, Pi-friendly deployment |
| **File-based registry (v1)** | Simple, debuggable, works offline |
| **Ollama as first capability** | Widely supported, low-resource, proven on Pi |
| **Resource limits at container level** | Prevents runaway processes, enables multi-stack |
| **YAML stacks (not code)** | Accessible to students, separates intent from implementation |

---

## References

- [Ollama Official Docs](https://github.com/ollama/ollama)
- [Podman Documentation](https://docs.podman.io/)
- [Raspberry Pi 5 Specifications](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [Whisper (OpenAI)](https://github.com/openai/whisper)
- [Piper TTS](https://github.com/rhasspy/piper)

---

*Last updated: 14 January 2026*

