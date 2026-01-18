# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Future enhancements will be listed here

## [1.0.0] - 2024-01-18

### Added
- Initial multi-architecture capability template release
- Core configuration files:
  - `capability.json` - Generic capability contract with placeholders
  - `podman-compose.yml` - Default ARM64/Pi configuration
  - `podman-compose.pi5.yml` - Pi 5 16GB optimized configuration
  - `podman-compose.amd64.yml` - AMD64 default configuration
- Device-specific configuration files:
  - `config/pi4-8gb.yml` - Conservative Raspberry Pi 4 configuration
  - `config/amd64-24gb.yml` - AMD64 with 24GB RAM
  - `config/amd64-32gb.yml` - AMD64 with 32GB+ RAM
  - `config/device-constraints.json` - Platform capabilities reference
- Generic automation scripts:
  - `scripts/deploy.sh` - Multi-arch deployment with auto-detection
  - `scripts/validate-deployment.sh` - Deployment validation
  - `scripts/health-check.sh` - Quick health verification
- Testing framework:
  - `tests/test-api.sh` - Generic API tests
  - `tests/test-performance.sh` - Architecture-aware performance tests
  - `tests/README.md` - Testing documentation
- Comprehensive documentation:
  - `README.md` - Complete template README with multi-arch support
  - `docs/README.md` - Documentation index
  - `docs/architecture.md` - eZansiEdgeAI architecture overview
  - `docs/capability-contract-spec.md` - Complete contract specification
  - `docs/performance-tuning.md` - ARM64 vs AMD64 optimization guide
  - `docs/troubleshooting.md` - Platform-specific troubleshooting
  - `docs/deployment-guide.md` - General deployment strategies
  - `docs/deployment-guide-amd64.md` - AMD64-specific deployment guide
- Project management files:
  - `.gitignore` - Standard exclusions
  - `LICENSE` - MIT License
  - `CHANGELOG.md` - This file
  - `notes/research.md` - Development notes template
- Multi-architecture support:
  - ARM64 (Raspberry Pi 4/5) configurations
  - AMD64 (x86-64) configurations
  - Platform detection and auto-configuration
- Contract-driven design:
  - All scripts read from `capability.json`
  - Generic, reusable automation
  - Standard endpoint definitions
- Resource optimization:
  - Platform-specific memory and CPU limits
  - Device-aware configurations
  - Performance tuning guidelines

### Design Decisions
- **LEGO brick philosophy** - Self-contained, composable capabilities
- **Contract-first approach** - Standard interface for all capabilities
- **Platform independence** - Same contract, different resource allocations
- **Container-first** - All capabilities run in containers
- **Edge-optimized** - Efficient resource usage for ARM64
- **Generic by design** - No capability-specific logic in template
- **Placeholder-based** - Easy customization with find/replace

### Template Features
- ✅ Multi-architecture support (ARM64 + AMD64)
- ✅ Contract-driven deployment scripts
- ✅ Platform auto-detection
- ✅ Generic testing framework
- ✅ Comprehensive documentation
- ✅ All scripts executable
- ✅ No hardcoded values (all use placeholders)
- ✅ Works for ANY capability type (LLM, STT, TTS, Vision, etc.)

### Breaking Changes
- None (initial release)

### Migration Guide
- Not applicable (initial release)

---

## Template Usage

When using this template to create a new capability:

1. **Replace placeholders** in all files:
   - `{{CAPABILITY_NAME}}` → Your capability name
   - `{{CAPABILITY_DESCRIPTION}}` → Description
   - `{{SERVICE_TYPE}}` → Service type (llm, stt, tts, etc.)
   - `{{CONTAINER_IMAGE}}` → Your container image
   - `{{PORT}}` → Your service port
   - `{{HEALTH_PATH}}` → Health endpoint path
   - `{{MAIN_ENDPOINT_PATH}}` → Main endpoint path
   - `{{RAM_MB}}` → Required RAM in MB
   - `{{CPU_CORES}}` → Required CPU cores
   - `{{STORAGE_MB}}` → Required storage in MB

2. **Update this CHANGELOG** with your capability-specific changes

3. **Follow semantic versioning** for your capability releases

---

## Version History

- **v1.0.0** (2024-01-18) - Initial multi-architecture template release

---

**Template maintained by:** [eZansiEdgeAI](https://github.com/eZansiEdgeAI)

**Based on patterns from:** [ezansi-capability-llm-ollama](https://github.com/eZansiEdgeAI/ezansi-capability-llm-ollama)
