# Changelog

All notable changes to the Ollama LLM Capability will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- AMD64 (x86-64) deployment presets: `config/amd64-24gb.yml`, `config/amd64-32gb.yml`
- Dedicated AMD64 deployment guide (`docs/deployment-guide-amd64.md`)
- AMD64 device profiles in `config/device-constraints.json`

### Changed
- Capability contract now supports multi-architecture metadata via `target_platforms` and `supported_architectures`
- Documentation updated to reflect Raspberry Pi (ARM64) and AMD64 support across deployment, tuning, and architecture docs

### Fixed
- Documentation references to a non-existent `Containerfile` rebuild path
- General troubleshooting guidance for environments missing `curl`

## [1.0.0] - 2026-01-14

### Added
- Initial release of Ollama LLM capability for eZansiEdgeAI
- Complete capability contract specification (`capability.json`)
- Podman Compose configuration with resource limits and health checks
- Automated deployment validation script
- Comprehensive README with deployment plan and instructions
- User-level Podman access configuration guide
- Helper scripts for deployment validation
- Configuration presets for different Raspberry Pi models
- Integration tests for API validation
- Performance tuning documentation
- Troubleshooting guide

### Features
- Text generation via Ollama API
- Resource constraints (6GB RAM, 4 CPU cores)
- Persistent model storage
- Health check monitoring
- Auto-restart on failure
- Support for Raspberry Pi 4 (8GB) and Pi 5 (16GB)

### Documentation
- Architecture documentation
- Performance tuning guide
- Capability contract specification
- Testing procedures
- Deployment roadmap

[1.0.0]: https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama/releases/tag/v1.0.0
[Unreleased]: https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama/compare/v1.0.0...HEAD
