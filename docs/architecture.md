# eZansiEdgeAI Architecture

## Overview

eZansiEdgeAI is a lightweight, modular edge-AI platform where small capability containers are composed into learning experiences using simple configuration instead of complex code.

## Core Principles

### The LEGO Brick Philosophy

Instead of one monolithic AI stack, eZansiEdgeAI provides small, independent capability modules that can be combined in different ways to create learning tools, assistants, and experiments on low-power devices.

**Build once, compose many times.**

### Three Logical Layers

```
┌─────────────────────────────────────┐
│   Experience Stacks (Composable)    │  ← YAML definitions
├─────────────────────────────────────┤
│   Capability Modules (Replaceable)  │  ← Containers with contracts
├─────────────────────────────────────┤
│   Platform Core (Stable)            │  ← Orchestration & discovery
└─────────────────────────────────────┘
```

#### Layer 1: Platform Core (Stable)

- Runs on the device
- Handles startup, configuration, discovery, and routing
- Knows nothing about AI models
- Changes rarely

**Components:**
- Registry: Tracks available capabilities
- Orchestrator: Connects capabilities into pipelines
- Gateway: Single entry point for requests

#### Layer 2: Capability Modules (Replaceable)

- Each module does one thing well
- Exposes a standard capability contract
- Declares its resource needs (RAM, CPU)
- Can be swapped without breaking the system

**Examples:**
- `capability-llm-ollama` - Text generation
- `capability-stt-whisper` - Speech-to-text
- `capability-tts-piper` - Text-to-speech
- `capability-vision-basic` - Image analysis
- `capability-retrieval-faiss` - Vector search

#### Layer 3: Experience Stacks (Composable)

- Defined in simple YAML files
- Describe what capabilities are needed, not how they work
- Can be created or modified by students and educators

**Example:** Voice assistant = speech-to-text → text-generation → text-to-speech

## Contracts Over Code

All modules follow a standard capability contract defining:

- What they provide (service type)
- How to call them (API endpoints)
- What resources they need (RAM, CPU, storage)

This enables:

- ✅ Easy swapping of models
- ✅ Hardware-aware deployment
- ✅ Safe experimentation
- ✅ Automatic discovery and composition

## v1 Architecture (Current)

### Minimal System

```
Raspberry Pi
└── Podman
    ├── platform-registry      (tiny)
    ├── platform-orchestrator  (very thin)
    └── capability-llm-ollama  (actual AI)
```

Three containers. That's it.

### Component Responsibilities

**Registry (v1 - File-Based)**
- Stores available capabilities and endpoints
- Simple JSON: `{"text-generation": "http://ollama:11434"}`
- No service discovery yet

**Orchestrator (v1 - Validator)**
- Loads device constraints
- Checks resource availability
- Says "yes" or "no" to stack requests
- No AI logic, no hardcoding

**Ollama Capability**
- Runs Ollama as a discoverable service
- Exposes capability contract
- Enforces resource limits
- Provides text-generation service

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **One capability per repo** | Clear ownership boundaries, independent versioning |
| **Standard contract in every capability** | Enables discovery and composition without hardcoding |
| **Podman instead of Docker** | Better for rootless, Pi-friendly deployment |
| **File-based registry (v1)** | Simple, debuggable, works offline |
| **Ollama as first capability** | Widely supported, low-resource, proven on Pi |
| **Resource limits at container level** | Prevents runaway processes, enables multi-stack |
| **YAML stacks (not code)** | Accessible to students, separates intent from implementation |

## Key Principles (Don't Break These)

1. **Capabilities must be dumb** — No orchestration logic inside containers
2. **Stacks must be declarative** — Define intent, not implementation
3. **Orchestration must be minimal** — Small, stateless, composable

**Break this rule and the system collapses.**

## Future Architecture (v2+)

### Multiple Capabilities

```
Raspberry Pi
└── Podman
    ├── platform-core/
    │   ├── registry
    │   ├── orchestrator
    │   └── gateway
    └── capabilities/
        ├── llm-ollama
        ├── stt-whisper
        ├── tts-piper
        ├── vision-basic
        └── retrieval-faiss
```

### Stack Composition

```yaml
name: voice-assistant
description: Voice-based learning assistant
pipeline:
  - speech-to-text
  - text-generation
  - text-to-speech
constraints:
  max_ram_mb: 7000
```

Orchestrator matches pipeline steps to available capabilities automatically.

## Repository Structure

```
eZansiEdgeAI/
├── platform-core/          # Registry, orchestrator, gateway
├── capabilities/           # Individual capability repos
│   ├── llm-ollama/
│   ├── stt-whisper/
│   ├── tts-piper/
│   ├── vision-basic/
│   └── retrieval-faiss/
├── stacks/                 # Stack definitions (YAML)
│   ├── voice-assistant.yaml
│   ├── rag-search.yaml
│   └── vision-lab.yaml
└── docs/                   # Platform documentation
    ├── capability-contract-spec.md
    └── stack-design.md
```

## References

- [Capability Contract Specification](capability-contract-spec.md)
- [Performance Tuning Guide](performance-tuning.md)
- [Troubleshooting Guide](troubleshooting.md)
