# Documentation

Comprehensive documentation for the Ollama LLM Capability.

## Core Documentation

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
Optimize Ollama for different Raspberry Pi models.

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

## Documentation Structure

```
docs/
├── README.md                        # This file
├── architecture.md                  # System architecture
├── capability-contract-spec.md      # Contract specification
├── performance-tuning.md            # Optimization guide
└── troubleshooting.md               # Problem solving
```

## Contributing to Documentation

When adding or updating documentation:

1. **Follow Markdown best practices**
2. **Include code examples** where appropriate
3. **Link between related documents**
4. **Keep content Pi-focused** - this is edge hardware
5. **Update this README** when adding new docs

## External Resources

- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs)
- [Podman Documentation](https://docs.podman.io/)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [eZansiEdgeAI Research](../notes/research.md)
