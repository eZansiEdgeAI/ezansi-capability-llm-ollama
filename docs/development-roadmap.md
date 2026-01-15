# Development Roadmap

This document outlines the multi-phase plan for building the eZansiEdgeAI capability ecosystem, starting with this LLM capability as the foundation.

## Phase 1: Validate Base Capability ✓ (Current)

**Status:** Base Ollama capability is deployed and tested on Pi 5

1. **Pull a model and test text generation**
   ```bash
   ./scripts/pull-model.sh mistral
   curl -X POST http://localhost:11434/api/generate \
     -d '{"model":"mistral","prompt":"Hello"}' \
     -H "Content-Type: application/json"
   ```

2. **Run test suite**
   ```bash
   ./tests/test-api.sh          # Verify API
   ./tests/test-performance.sh  # Measure speed
   ```

**Deliverables:**
- ✓ Capability contract (`capability.json`)
- ✓ Production-ready Podman compose configuration
- ✓ Automated deployment validation
- ✓ Deployment documentation
- ✓ Multi-device support (Pi 4, Pi 5)
- ✓ Interactive model selection in tests
- ✓ Model switching documentation

## Phase 2: Expand Ecosystem (Soon)

3. **Create second capability** (Whisper STT or Piper TTS)
   - Follow same pattern as capability-llm-ollama
   - Own capability.json contract
   - Separate repository
   - Target device: Raspberry Pi 5

### New Capability Repository Structure

When creating a Phase 2 capability (e.g., `ezansi-capability-stt-whisper`), follow this template:

```
ezansi-capability-stt-whisper/
├── capability.json           # Contract: defines service interface
├── podman-compose.yml        # Deployment: container configuration
├── podman-compose.pi5.yml    # Device-specific: optimized for Pi 5
├── README.md                 # Quick start & overview
├── CHANGELOG.md              # Version history
├── LICENSE                   # License
├── scripts/
│   ├── deploy.sh             # Full deployment
│   ├── validate-deployment.sh # Health checks
│   ├── pull-model.sh         # Download models (if applicable)
│   └── health-check.sh       # Quick status
├── config/
│   ├── pi5-16gb.yml          # Pi 5 constraints
│   ├── pi4-8gb.yml           # Pi 4 constraints
│   └── device-constraints.json
├── tests/
│   ├── test-api.sh           # API functionality
│   ├── test-performance.sh   # Latency/throughput
│   └── README.md
├── docs/
│   ├── deployment-guide.md   # How to deploy
│   ├── architecture.md       # Design details
│   ├── performance-tuning.md # Optimization
│   ├── troubleshooting.md    # Common issues
│   └── images/               # Screenshots
└── notes/
    └── research.md           # Design notes
```

**Key files to adapt from LLM capability:**

1. **capability.json** - Update `provides`, `port`, `resources`, `container.image`
   ```json
   {
     "name": "capability-stt-whisper",
     "version": "1.0",
     "provides": ["speech-to-text"],
     "api": {
       "endpoint": "http://localhost:9000",
       "type": "REST",
       "health_check": "/health"
     },
     "resources": {
       "ram_mb": 3000,
       "cpu_cores": 2,
       "storage_mb": 2000
     }
   }
   ```

2. **podman-compose.yml** - Adapt container, port, env vars, resource limits
   ```yaml
   services:
     whisper:
       image: docker.io/openai/whisper  # Example
       container_name: whisper-stt-capability
       ports:
         - "9000:9000"
       deploy:
         resources:
           limits:
             memory: 6g
   ```

3. **README.md** - Follow same structure:
   - What it does
   - Prerequisites & setup
   - Deployment instructions
   - Health checks
   - API examples
   - Testing

4. **Tests** - Mirror API and performance tests for your service

5. **Deployment guide** - Container portability (export/import, registry, rebuild)

4. **Build platform-core repo** (foundation layer)
   - Registry service (capability discovery)
   - Request router (route to appropriate capability)
   - Resource validator (check device constraints)
   - Gateway (single entry point)

5. **Implement basic registry**
   - File-based v1 (simple, debuggable)
   - Capability auto-discovery (via `capability.json`)
   - Auto-registration on startup
   - JSON response API

### Platform-Core Architecture (Phase 2)

The platform-core repo orchestrates all capabilities. Key components:

**1. Capability Registry** - Discovers and catalogs available capabilities
```
┌─────────────────────────────────────┐
│   Capability Registry Service       │
├─────────────────────────────────────┤
│ • Scans /capabilities for JSON      │
│ • Registers service endpoints       │
│ • Validates resource contracts      │
│ • Returns: {name, provides, port}   │
└─────────────────────────────────────┘
```

Implementation:
- Scan local filesystem for `capability.json` files
- Parse contract (resource requirements, API endpoint, etc.)
- Store in-memory registry or JSON file
- Provide REST API: `GET /registry` → list all capabilities

**2. Request Router** - Routes requests to appropriate capability
```
Client Request
    ↓
┌─────────────────────┐
│  Request Router     │
├─────────────────────┤
│ • Parse request     │
│ • Check required    │
│   capability type   │
│ • Find available    │
│   provider          │
└──────────┬──────────┘
    ↓
Capability Endpoint (e.g., Ollama, Whisper, etc.)
```

Implementation:
- Accept requests like: `POST /generate` with `{"type":"text-generation", "prompt":"..."}`
- Query registry for capability matching that type
- Proxy request to endpoint from registry
- Return response

**3. Resource Validator** - Checks if device has enough resources
```
Deploy Request
    ↓
┌──────────────────────────────┐
│  Resource Validator          │
├──────────────────────────────┤
│ • Parse capability.json      │
│ • Read device constraints    │
│ • Check: RAM, CPU, Storage   │
│ • Return: compatible / error │
└──────────────────────────────┘
```

Implementation:
- Load `device-constraints.json` from device
- Read capability's resource requirements from `capability.json`
- Compare: required <= available
- Block deployment if insufficient resources

**4. Gateway** - Single entry point for all requests
```
┌────────────────────────────────┐
│  API Gateway (port 8000)       │
├────────────────────────────────┤
│ • Accept requests              │
│ • Validate against schema      │
│ • Rate limiting (optional)     │
│ • Route to appropriate service │
└────────────────────────────────┘
```

Implementation:
- Single HTTP server listening on port 8000
- Routes:
  - `GET /health` - Gateway status
  - `GET /registry` - List available capabilities
  - `POST /validate` - Check resource compatibility
  - `/generate`, `/transcribe`, etc. - Proxy to capabilities

**Platform-Core Repository Structure:**

```
ezansi-platform-core/
├── README.md                      # Overview & quick start
├── capability-registry.py         # Service registry
├── request-router.py              # Route requests
├── resource-validator.py          # Check device constraints
├── api-gateway.py                 # Main HTTP server
├── docker-compose.yml             # Run platform-core + all capabilities
├── config/
│   └── device-constraints.json    # Device resource limits
├── tests/
│   ├── test-registry.sh           # Verify discovery
│   ├── test-routing.sh            # Verify request routing
│   ├── test-stack.sh              # Full stack test
│   └── README.md
├── examples/
│   ├── stack-voice-assistant.yml  # STT → LLM → TTS
│   └── stack-document-qa.yml      # LLM RAG example
├── docs/
│   ├── architecture.md            # System design
│   ├── capability-discovery.md    # How registry works
│   ├── request-routing.md         # How router works
│   ├── composition-guide.md       # How to create stacks
│   └── deployment-guide.md        # Multi-capability deployment
└── scripts/
    ├── deploy-stack.sh            # Deploy capability set
    ├── validate-stack.sh          # Test composition
    └── health-check.sh            # System status
```

**Phase 2 Deliverables:**

1. ✓ Second capability (`ezansi-capability-stt-whisper` or similar)
2. ✓ Platform-core with registry + router + validator
3. ✓ Gateway accepting requests for multiple capabilities
4. ✓ Auto-discovery of capabilities via `capability.json`
5. ✓ Example stack: Voice Assistant (STT → LLM → TTS)
6. ✓ Comprehensive testing & documentation

6. **Create example stack composition**
   - Voice assistant: STT → LLM → TTS
   - Document composition pattern in `stack.yaml` format
   - Show how platform-core wires capabilities together
   - Demonstrate end-to-end inference

## Phase 3: Orchestration & Composition (Future)

- **Multi-stack management** - Deploy and manage multiple stacks simultaneously
- **Resource constraint checking** - Validate device has enough resources before deploying
- **Dynamic capability wiring** - Hot-swap capabilities without restart
- **Learning stack templates** - Pre-configured stacks for common use cases
- **Student-facing UI shell** - Web interface to compose and run stacks

## Phase 4: Production & Scale (Long-term)

- **Distributed deployment** - Deploy across multiple Raspberry Pis
- **Capability marketplace** - Community-contributed capabilities
- **Version management** - Handle capability updates and compatibility
- **Monitoring & logging** - Central observability across fleet
- **Performance optimization** - Fine-tune for constrained hardware

---

## Architecture Evolution

### Phase 1: Single Capability (Current)
```
┌─────────────────────────┐
│  Ollama LLM Capability  │
│   (This Repository)     │
└─────────────────────────┘
```

### Phase 2: Capability Ecosystem
```
┌──────────────────────────────────────┐
│       Platform Core (Registry)       │
├──────────────────────────────────────┤
│  Ollama   │  Whisper  │  Piper TTS   │
│  (LLM)    │   (STT)   │  (Text→Voice)│
└──────────────────────────────────────┘
```

### Phase 3+: Full Orchestration
```
┌─────────────────────────────────────────────┐
│  eZansiEdgeAI Platform (UI + Orchestrator)  │
├─────────────────────────────────────────────┤
│        Registry & Resource Manager          │
├─────────────────────────────────────────────┤
│ Capabilities: LLM │ STT │ TTS │ Vision │ ... │
└─────────────────────────────────────────────┘
```

---

## Key Principles

1. **Modular by Design** - Each capability is a self-contained "LEGO brick"
2. **Contract-Driven** - `capability.json` defines the interface
3. **Edge-First** - Optimize for constrained hardware (Raspberry Pi)
4. **Composable** - Stack capabilities into learning experiences
5. **Discoverable** - Platform auto-discovers and wires capabilities

---

## Success Criteria

**Phase 1 (Current):**
- [x] Deploy Ollama on Pi 5 with full resource limits
- [x] Pass API integration tests
- [x] Measure performance on different models
- [ ] Document deployment patterns

**Phase 2:**
- [ ] Deploy 2+ capabilities side-by-side
- [ ] Platform-core auto-discovers and routes requests
- [ ] Create first full example stack (voice assistant)
- [ ] Document capability creation pattern

**Phase 3:**
- [ ] Multi-device deployment (master + worker Pis)
- [ ] UI for stack composition
- [ ] Performance metrics on real-world workloads

---

## Contributing

To build a new capability:

1. Create a new repository: `ezansi-capability-<name>`
2. Follow the pattern in [ezansi-capability-llm-ollama](https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama)
3. Include a `capability.json` contract
4. Provide Podman compose configuration
5. Submit PR to link in platform-core registry

See [Platform Core](https://github.com/eZansiEdgeAI/ezansi-platform-core) for registry details.
