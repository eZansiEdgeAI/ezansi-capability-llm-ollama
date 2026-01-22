# Quickstart Manual Test (Cold Start)

This is a manual test checklist for the `ezansi-capability-llm-ollama` capability.

Goal: prove the capability works standalone, then prove it can be invoked via the `ezansi-platform-core` gateway.

## Prerequisites

- `podman`, `podman-compose`
- `curl`

## 1) Cold start: deploy Ollama

From the repo root:

```bash
podman-compose up -d
```

Verify Ollama API is reachable:

```bash
curl -fsS http://localhost:11434/api/tags
```

## 2) Pull a model (first run)

On a cold machine, you must download at least one model:

```bash
./scripts/pull-model.sh mistral
```

## 3) Standalone request (direct to Ollama)

```bash
curl -fsS -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model":"mistral","prompt":"Hello from Ollama","stream":false}'
```

Success looks like: JSON containing `response`.

## 4) Invoke via ezansi-platform-core gateway (integration)

This requires:

- `ezansi-platform-core` running on `http://localhost:8000`
- the capability contract copied into the platform registry folder

Example (from the platform-core repo root):

```bash
mkdir -p capabilities/ollama-llm
cp ../ezansi-capability-llm-ollama/capability.json capabilities/ollama-llm/capability.json
podman-compose up -d --build
```

Then call through the gateway:

```bash
curl -fsS -X POST http://localhost:8000/ \
  -H 'Content-Type: application/json' \
  -d '{"type":"text-generation","payload":{"endpoint":"generate","json":{"model":"mistral","prompt":"Hello via platform-core","stream":false}}}'
```

Success looks like: a JSON response containing generated text.

## Teardown

```bash
./scripts/stop.sh --down
```
