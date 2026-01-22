# Documentation

Comprehensive documentation for the Ollama LLM Capability.

## Mental model (LEGO brick)

If you’re a teacher/lecturer or student, think of this capability as **one LEGO brick**.

- `capability.json` describes the “studs” (what this brick provides)
- [eZansi Platform Core](https://github.com/eZansiEdgeAI/ezansi-platform-core) is the “baseplate” (one gateway that discovers bricks and routes requests)

Start with the cold-start checklist: [Quickstart Manual Test](quickstart-manual-test.md)

## Core Documentation

### [Quickstart Manual Test](quickstart-manual-test.md)
Cold-start checklist: deploy, pull a model, and validate end-to-end (standalone + via platform-core).

### [Architecture](architecture.md)
System architecture, design principles, and component responsibilities.

**Topics:**
- LEGO brick philosophy
- Three-layer model (Platform, Capabilities, Stacks)
- v1 architecture (current implementation)
- Design decisions and rationale

### [Capability Contract Specification](capability-contract-spec.md)
Complete specification for the capability contract schema.

**Topics:**
- Contract structure and fields
- Standard service types
- Validation rules
- Naming conventions
- Example contracts

### [Performance Tuning](performance-tuning.md)
Optimize Ollama for different Raspberry Pi models and AMD64 systems.

**Topics:**
- Hardware-specific configurations
- Resource allocation strategies
- Model selection guide
- Storage and network optimization
- Thermal management

### [Troubleshooting](troubleshooting.md)
Common issues and solutions.

**Topics:**
- Container startup problems
- API connectivity issues
- Memory and performance problems
- Diagnostic commands
- Getting help

## Quick Links

- **Getting Started:** See main [README.md](../README.md)
- **Deployment:** Use [scripts/deploy.sh](../scripts/deploy.sh)
- **Testing:** Check [tests/README.md](../tests/README.md)
- **Configuration:** Browse [config/](../config/)

## AMD64

Running on an x86-64 workstation/server is supported.

- **Deployment (AMD64):** See [deployment-guide-amd64.md](deployment-guide-amd64.md)

## Documentation Structure

```
docs/
├── README.md                        # This file
├── architecture.md                  # System architecture
├── capability-contract-spec.md      # Contract specification
├── deployment-guide.md              # Portability and deployment patterns
├── deployment-guide-amd64.md        # AMD64 deployment (24GB+ RAM presets)
├── performance-tuning.md            # Optimization guide
└── troubleshooting.md               # Problem solving
```

## Contributing to Documentation

When adding or updating documentation:

1. **Follow Markdown best practices**
2. **Include code examples** where appropriate
3. **Link between related documents**
4. **Keep content edge-focused** - Raspberry Pi is the default target, but AMD64 is supported
5. **Update this README** when adding new docs

## External Resources

- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs)
- [Podman Documentation](https://docs.podman.io/)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [eZansiEdgeAI Research](../notes/research.md)
