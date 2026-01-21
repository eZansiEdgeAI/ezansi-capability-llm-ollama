# The Story of ezansi-capability-llm-ollama

## The Chronicles: A Year in Numbers

This repository’s history is a concentrated “capability bring-up” sprint rather than a long-lived maintenance stream:

- **Total commits (all time):** 23
- **Commits in the last year:** 23
- **Merges in the last year:** 1 (`Merge pull request #2 from eZansiEdgeAI/chore/amd64-support`)
- **Most active month:** January 2026 (23 commits)

The pace and shape of commits suggests an intentional push to make Ollama the first reliable “LEGO brick” capability for the wider platform.

## Cast of Characters

- **McSquirrel** (11 commits, last year)
  - Speciality: platform narrative + architecture documentation; keeping the capability aligned with the “contract-first” ecosystem.

- **McFuzzySquirrel** (6 commits, last year)
  - Speciality: operational hardening, device realities (Pi vs AMD64), and integration-level fixes.

- **Nabeel Prior** (4 commits, last year)
  - Speciality: comprehensive documentation upgrades (streaming usage, model switching, issue templates, changelog).

- **GitHub Copilot** (2 commits, last year)
  - Speciality: fast-turnaround fixes during live integration (compose repair, health checks, networking).

## Seasonal Patterns

There is no multi-month cadence in the last year:

- **2026-01:** 23 commits

This “single-month spike” pattern typically indicates either an early-stage repository or a milestone-driven push (demo-readiness, first capability rollout, or hardware validation window).

## The Great Themes

### 1) Establish the contract and deployment envelope

The opening act is about defining what this capability *is* and how it runs:

- `302a41d` — Create capability.json for ollama-llm
- `dfc01bb` — Add podman-compose.yml for Ollama service setup
- `4643943` — feat: implement v1 ollama capability with deployment validation

This sequence sets the ecosystem contract (`capability.json`) and locks in “how to run it” under Podman with a repeatable shape.

### 2) Docs-as-product for edge deployment reality

The most frequently changed file is `README.md` (16 touches in the last year). The repo repeatedly invests in making “first run on a Pi” succeed:

- cgroups v2 and memory controller enablement
- rootless Podman guidance and linger/socket setup
- troubleshooting checklists and performance notes

This suggests the capability’s hardest problems are operational, not algorithmic.

### 3) AMD64 support as a first expansion

The merge of `chore/amd64-support` marks a major compatibility broadening:

- `6f4b177` — Merge pull request #2 from eZansiEdgeAI/chore/amd64-support

Alongside it are new compose presets and docs that treat AMD64 as a first-class target.

### 4) Demo-breaker fixes: health checks and networking

The most recent commits read like integration hardening discovered when wiring this capability into a larger system:

- `819e970` — fix: ollama healthcheck without curl
  - Motivation: the upstream `ollama/ollama` image doesn’t include `curl`, so container health checks that rely on `curl` fail even when the service is fine.
  - Direction: use `ollama list` as a health signal.

- `a51f961` — fix: repair compose + use host network for pulls
  - Motivation: avoid DNS/bridge issues that can block model pulls inside containers.
  - Direction: prefer `network_mode: host` for straightforward connectivity in constrained environments.

These are “demo killers” because they show up as unhealthy services or failed pulls; fixing them improves reliability dramatically.

## Plot Twists and Turning Points

- **The shift from “it runs” to “it can be adopted”** is visible in how quickly docs become dominant. After the contract and compose exist, the repository invests heavily in making the capability usable by others.

- **The AMD64 merge** is the first expansion beyond the Pi-first narrative and signals that the project expects heterogeneous edge deployments.

- **The late healthcheck/networking fixes** indicate real-world integration (and likely platform-core routing/health aggregation) exposed assumptions that didn’t hold in the upstream image and default container networking.

## The Current Chapter

Today, the repository stands as a strong reference capability:

- A clear contract (`capability.json`) for `text-generation`
- Multiple compose presets for Pi and AMD64
- Validation and testing scripts to confirm the service is healthy and generating
- A documentation suite that anticipates common edge failures

The logical next evolution (implied by the docs and broader eZansiEdgeAI direction) is tighter alignment between the contract’s `api.health_check` and the container health check, plus continuous integration that exercises “pull model + generate” across target architectures.
