# Capability Contract Specification

## Overview

The capability contract is a standardized JSON schema that all eZansiEdgeAI capabilities must expose. It enables automatic discovery, resource validation, and service composition.

## Contract Location

Every capability must expose its contract at:

```
GET /.well-known/capability.json
```

Or include it as `capability.json` in the repository root.

## Schema Definition

This repo supports both Raspberry Pi (ARM64) and AMD64 (x86-64) deployments. For that reason, newer contracts MAY declare multiple targets and architectures.

- Prefer `target_platforms` + `supported_architectures` for new capabilities.
- `target_platform` remains supported for backwards compatibility, but is treated as deprecated.

### v1.0 Contract

```json
{
  "name": "string",              // Required: Unique capability identifier
  "version": "string",           // Required: Semantic version (e.g., "1.0")
  "type": "capability",          // Required: Always "capability"
  "description": "string",       // Required: Human-readable description
  "provides": ["string"],        // Required: Service types this capability offers
  "requires": ["string"],        // Optional: Dependencies on other capabilities
  "resources": {                 // Required: Resource requirements
    "ram_mb": number,            // Required: RAM in megabytes
    "cpu_cores": number,         // Required: CPU cores needed
    "storage_mb": number,        // Optional: Storage in megabytes
    "accelerator": "string"      // Optional: "none", "gpu", "npu"
  },
  "endpoints": {                 // Required: API endpoints
    "endpoint-name": {
      "method": "string",        // Required: HTTP method
      "path": "string",          // Required: URL path
      "input": "string",         // Required: Content-Type for input
      "output": "string"         // Required: Content-Type for output
    }
  },
  "container": {                 // Optional: Container details
    "image": "string",           // Container image name
    "port": number,              // Exposed port
    "restart_policy": "string"   // Restart policy
  },
  "target_platform": "string",   // Optional (deprecated): Intended hardware
  "target_platforms": ["string"], // Optional: Intended hardware targets
  "supported_architectures": ["string"], // Optional: e.g. ["arm64", "amd64"]
  "notes": "string"              // Optional: Additional information
}
```

## Standard Service Types

Capabilities MUST use one of these standard `provides` values:

| Service Type | Description | Examples |
|-------------|-------------|----------|
| `text-generation` | Generate text from prompts | LLMs (Ollama, llama.cpp) |
| `speech-to-text` | Transcribe audio to text | Whisper, Vosk |
| `text-to-speech` | Synthesize speech from text | Piper, Coqui TTS |
| `image-analysis` | Analyze images | YOLO, OpenCV |
| `vector-search` | Semantic search | FAISS, ChromaDB |
| `embedding` | Generate embeddings | Sentence transformers |
| `translation` | Translate between languages | NLLB, MarianMT |

## Example Contracts

### Text Generation (Ollama)

```json
{
  "name": "ollama-llm",
  "version": "1.0",
  "type": "capability",
  "description": "Local LLM using Ollama. Provides text generation for prompt-based AI tasks.",
  "provides": ["text-generation"],
  "requires": [],
  "resources": {
    "ram_mb": 6000,
    "cpu_cores": 4,
    "storage_mb": 8000
  },
  "endpoints": {
    "generate": {
      "method": "POST",
      "path": "/api/generate",
      "input": "application/json",
      "output": "application/json"
    },
    "tags": {
      "method": "GET",
      "path": "/api/tags",
      "input": "none",
      "output": "application/json"
    }
  },
  "container": {
    "image": "docker.io/ollama/ollama",
    "port": 11434,
    "restart_policy": "unless-stopped"
  },
  "target_platforms": ["Raspberry Pi 5 (16GB)", "Raspberry Pi 4 (8GB)", "AMD64 (24GB+)"],
  "supported_architectures": ["arm64", "amd64"]
}
```

### Speech-to-Text (Whisper)

```json
{
  "name": "whisper-stt",
  "version": "1.0",
  "type": "capability",
  "description": "Speech recognition using OpenAI Whisper",
  "provides": ["speech-to-text"],
  "requires": [],
  "resources": {
    "ram_mb": 2000,
    "cpu_cores": 2,
    "storage_mb": 3000
  },
  "endpoints": {
    "transcribe": {
      "method": "POST",
      "path": "/transcribe",
      "input": "audio/wav",
      "output": "application/json"
    }
  },
  "container": {
    "image": "onerahmet/openai-whisper-asr-webservice",
    "port": 9000,
    "restart_policy": "unless-stopped"
  },
  "target_platform": "Raspberry Pi 5"
}
```

### Text-to-Speech (Piper)

```json
{
  "name": "piper-tts",
  "version": "1.0",
  "type": "capability",
  "description": "Fast neural text-to-speech using Piper",
  "provides": ["text-to-speech"],
  "requires": [],
  "resources": {
    "ram_mb": 500,
    "cpu_cores": 1,
    "storage_mb": 1000
  },
  "endpoints": {
    "synthesize": {
      "method": "POST",
      "path": "/synthesize",
      "input": "application/json",
      "output": "audio/wav"
    }
  },
  "container": {
    "image": "rhasspy/piper",
    "port": 10200,
    "restart_policy": "unless-stopped"
  },
  "target_platform": "Raspberry Pi 4/5"
}
```

## Resource Constraints

### RAM Allocation

Resource declarations should be realistic for target hardware:

| Platform | Total RAM | OS Overhead | Available for Capabilities |
|----------|-----------|-------------|---------------------------|
| Pi 5 (16GB) | 16GB | ~2GB | ~14GB |
| Pi 5 (8GB) | 8GB | ~1.5GB | ~6.5GB |
| Pi 4 (8GB) | 8GB | ~1.5GB | ~6.5GB |
| AMD64 (32GB) | 32GB | ~2-4GB | ~28-30GB |

### CPU Cores

All Raspberry Pi 4 and 5 models have 4 cores. Capabilities should declare realistic CPU needs:

- **Lightweight:** 1-2 cores (TTS, simple APIs)
- **Medium:** 2-3 cores (STT, vision)
- **Heavy:** 4 cores (LLMs, complex models)

### Storage

Declare typical storage needs:

- Model files
- Temporary files
- Cache requirements

## Validation Rules

### Required Fields

All capabilities MUST include:

- `name` - Unique identifier
- `version` - Semantic version
- `description` - What it does
- `provides` - At least one service type
- `resources.ram_mb` - RAM requirement
- `resources.cpu_cores` - CPU requirement
- `endpoints` - At least one endpoint

### Naming Conventions

**Capability names:**
- Use kebab-case: `ollama-llm`, `whisper-stt`
- Format: `[technology]-[type]`
- Be descriptive and specific

**Service types:**
- Use kebab-case
- Follow standard types (see table above)
- Don't invent new types without platform approval

**Endpoint names:**
- Use lowercase
- Be action-oriented: `generate`, `transcribe`, `analyze`

## Contract Versioning

Contracts use semantic versioning:

- **Major version** (1.x.x): Breaking changes to contract structure
- **Minor version** (x.1.x): New optional fields added
- **Patch version** (x.x.1): Documentation or clarification updates

## Discovery Process

The platform discovers capabilities through:

1. **Static registration:** Reading `capability.json` from repository
2. **Dynamic registration:** HTTP GET to `/.well-known/capability.json`
3. **Registry lookup:** Querying platform registry service

## Contract Usage

### By Platform Orchestrator

```python
# Load capability contract
contract = load_contract("capability.json")

# Check resource availability
if device.ram_mb >= contract["resources"]["ram_mb"]:
    deploy_capability(contract)
```

### By Stack Composer

```yaml
# Stack definition references service types
pipeline:
  - speech-to-text    # Orchestrator finds capability providing this
  - text-generation   # Matches to any LLM capability
  - text-to-speech    # Finds TTS capability
```

### By Students/Developers

```json
// Create new capability by following contract spec
{
  "name": "my-custom-capability",
  "provides": ["image-analysis"],
  "resources": { "ram_mb": 1000, "cpu_cores": 2 },
  ...
}
```

## Best Practices

1. **Be honest about resources** - Declare realistic requirements
2. **Use standard service types** - Don't create custom types unnecessarily
3. **Document endpoints clearly** - Include input/output specs
4. **Version carefully** - Breaking changes need major version bump
5. **Test on target hardware** - Validate resource claims on actual Pi
6. **Keep contracts simple** - Only include necessary information
7. **Follow naming conventions** - Makes discovery easier

## References

- [Architecture Documentation](architecture.md)
- [Example Capabilities](https://github.com/eZansiEdgeAI)
- [Platform Registry Spec](https://github.com/eZansiEdgeAI/platform-core)
