# Ollama LLM Capability Tests

This directory contains integration and performance tests for the Ollama LLM capability.

## Test Scripts

### test-api.sh
Basic API integration tests that verify:
- Health check endpoint
- Model listing
- Text generation functionality

**Usage:**
```bash
./tests/test-api.sh
```

### test-performance.sh
Performance testing for measuring:
- Response time
- Generation speed
- Throughput

**Usage:**
```bash
# Test with default model (mistral)
./tests/test-performance.sh

# Test with specific model
TEST_MODEL=llama2 ./tests/test-performance.sh

# Test with custom prompt
TEST_PROMPT="Explain quantum computing" ./tests/test-performance.sh
```

## Environment Variables

- `OLLAMA_URL` - Ollama API endpoint (default: `http://localhost:11434`)
- `TEST_MODEL` - Model to use for testing (default: `mistral`)
- `TEST_PROMPT` - Prompt for generation tests

## Running All Tests

```bash
# Run API tests
./tests/test-api.sh

# Run performance tests
./tests/test-performance.sh
```

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed
