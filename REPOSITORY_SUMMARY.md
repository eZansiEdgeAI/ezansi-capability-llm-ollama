# Repository Analysis: ezansi-capability-llm-ollama

## Overview

`ezansi-capability-llm-ollama` packages Ollama as a deployable **text-generation capability** in the eZansiEdgeAI ecosystem. Its job is to make “run a local LLM on edge hardware” reproducible via Podman, and describable via a capability contract (`capability.json`) so platform tooling (like platform-core) can discover and route to it.

The repository emphasizes:

- **Portability** across Raspberry Pi 4/5 (ARM64) and AMD64 hosts
- **Operational clarity** (prereqs, cgroups/memory controller guidance, troubleshooting)
- **Composable contracts** (standard fields for `provides`, API endpoint, health check, and resource requirements)

## Architecture

This repo is intentionally “thin” on application code: Ollama itself is the upstream service. The value here is the contract + deployment envelope + validation.

Core architectural elements:

- **Contract-first interface**: `capability.json` describes what is provided and how to call it.
- **Deployment envelope**: `podman-compose.yml` (plus presets) defines how to run the container reliably with resource limits and persistent storage.
- **Validation and testing**: scripts and tests verify the service is reachable and can generate text.
- **Docs-as-product**: extensive documentation guides users through common edge pitfalls (rootless Podman, cgroups v2, memory controller).

## Key Components

- **Capability Contract** ([capability.json](capability.json))
  - Declares `provides: ["text-generation"]`.
  - Defines API location and health check (`api.endpoint`, `api.health_check`).
  - Declares resource needs (RAM/CPU/storage).
  - Provides targeting metadata (platforms and architectures).

- **Podman Compose Definitions**
  - Default compose: [podman-compose.yml](podman-compose.yml)
    - Runs `docker.io/ollama/ollama`
    - Uses a persistent volume (`ollama-data:/root/.ollama`)
    - Enforces resource constraints via compose `deploy.resources`
    - Uses a health check (currently `ollama list`)
    - Uses `network_mode: host` for straightforward host access and to avoid bridge DNS failures during model pulls.
  - Device presets:
    - [podman-compose.pi5.yml](podman-compose.pi5.yml) (Pi 5 / higher RAM limits)
    - [podman-compose.amd64.yml](podman-compose.amd64.yml) (AMD64 / higher CPU+RAM, `platform: linux/amd64`)
  - Config presets under [config/](config/)
    - Example: [config/amd64-24gb.yml](config/amd64-24gb.yml), [config/pi5-16gb.yml](config/pi5-16gb.yml)

- **Scripts (operator ergonomics)**
  - [scripts/deploy.sh](scripts/deploy.sh): wrapper that runs compose then validates.
  - [scripts/validate-deployment.sh](scripts/validate-deployment.sh): checks Podman availability, container status, API reachability, and basic resource inspection.
  - [scripts/pull-model.sh](scripts/pull-model.sh): pulls a model via Ollama’s API.
  - [scripts/health-check.sh](scripts/health-check.sh): quick API liveness check.

- **Tests (lightweight smoke checks)**
  - [tests/test-api.sh](tests/test-api.sh): validates `/api/tags` and a basic `/api/generate` call.
  - [tests/test-performance.sh](tests/test-performance.sh): measures performance and supports model selection.
  - [tests/README.md](tests/README.md): documents test usage.

- **Documentation**
  - High-level docs: [README.md](README.md), [CHANGELOG.md](CHANGELOG.md)
  - Reference docs under [docs/](docs/):
    - [docs/architecture.md](docs/architecture.md)
    - [docs/capability-contract-spec.md](docs/capability-contract-spec.md)
    - [docs/deployment-guide.md](docs/deployment-guide.md)
    - [docs/deployment-guide-amd64.md](docs/deployment-guide-amd64.md)
    - [docs/performance-tuning.md](docs/performance-tuning.md)
    - [docs/troubleshooting.md](docs/troubleshooting.md)
    - [docs/development-roadmap.md](docs/development-roadmap.md)

## Technologies Used

- **Ollama** (upstream model runtime)
- **Podman + podman-compose** (deployment)
- **YAML / JSON** (compose and contract)
- **Shell scripts** (deployment validation, operational helpers)
- **curl** (API calls in scripts/tests)

## Data Flow

### Deployment

1. Operator runs `podman-compose up -d` (or a preset compose file).
2. Podman starts the `ollama-llm-capability` container and attaches a persistent volume for models.
3. Health checks verify the service is ready.

### Model Management

1. Operator pulls a model (e.g. via [scripts/pull-model.sh](scripts/pull-model.sh) which calls `POST /api/pull`).
2. Models persist in the `ollama-data` volume.

### Inference (Text Generation)

1. Client calls the Ollama HTTP API on `http://localhost:11434`.
2. Typical endpoints:
   - `GET /api/tags` (list models)
   - `POST /api/generate` (generate or stream tokens)
3. In the broader eZansiEdgeAI platform, platform-core routes requests to this capability by the service type `text-generation` using the contract information.

## Team and Ownership

Recent authorship shows a split between platform builders and documentation/enablement:

- **McSquirrel** and **McFuzzySquirrel**: primary maintainers pushing platform direction, deployment reality, and fixes.
- **Nabeel Prior**: significant documentation contributions (README and docs refreshes).
- **GitHub Copilot**: targeted fixes for operational issues discovered during integration (health checks and networking).
