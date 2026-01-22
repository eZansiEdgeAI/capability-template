# Documentation Index

Welcome to the eZansiEdgeAI Capability Template documentation.

## Mental model (LEGO bricks)

If you’re building capabilities for teaching/learning, think of eZansiEdgeAI like LEGO:

- **Your capability = one brick**
- **`capability.json` = the studs** (what the brick provides and how to call it)
- **Platform Core = the baseplate** (one gateway that discovers bricks and routes requests)

Start here: **[Quickstart Manual Test](quickstart-manual-test.md)** (cold start, then invoke via the gateway).

## 📚 Documentation Structure

### Getting Started
- **[Main README](../README.md)** - Quick start guide and overview
- **[Quickstart Manual Test](quickstart-manual-test.md)** - Cold-start checklist (standalone + via Platform Core gateway)
- **[Deployment Guide](deployment-guide.md)** - General deployment strategies
- **[AMD64 Deployment Guide](deployment-guide-amd64.md)** - AMD64-specific deployment

### Architecture & Design
- **[Architecture Overview](architecture.md)** - eZansiEdgeAI architecture and design philosophy
- **[Capability Contract Specification](capability-contract-spec.md)** - Complete contract schema and validation

### Operations & Maintenance
- **[Performance Tuning](performance-tuning.md)** - ARM64 vs AMD64 optimization guide
- **[Troubleshooting](troubleshooting.md)** - Platform-specific troubleshooting guide

### Testing
- **[Testing Guide](../tests/README.md)** - API and performance testing documentation

## 🎯 Quick Navigation

### For New Users
1. Start with the [Main README](../README.md) for quick start
2. Review [Architecture Overview](architecture.md) to understand the design
3. Follow [Deployment Guide](deployment-guide.md) for your platform

### For Developers
1. Read [Capability Contract Specification](capability-contract-spec.md)
2. Review [Architecture Overview](architecture.md)
3. Check [Performance Tuning](performance-tuning.md) for optimization

### For Troubleshooting
1. Check [Troubleshooting Guide](troubleshooting.md)
2. Review platform-specific sections
3. Use diagnostic commands provided

## 🔍 Documentation by Topic

### Multi-Architecture Support
- ARM64 vs AMD64 comparison: [Architecture Overview](architecture.md)
- Platform-specific configurations: [Deployment Guide](deployment-guide.md)
- Performance expectations: [Performance Tuning](performance-tuning.md)

### Capability Development
- Contract specification: [Capability Contract Specification](capability-contract-spec.md)
- Standard service types: [Capability Contract Specification](capability-contract-spec.md#standard-service-types)
- Endpoint definitions: [Capability Contract Specification](capability-contract-spec.md#endpoints)

### Deployment & Operations
- Deployment strategies: [Deployment Guide](deployment-guide.md)
- Resource allocation: [Performance Tuning](performance-tuning.md)
- Health monitoring: [Troubleshooting Guide](troubleshooting.md)

## 📖 Documentation Conventions

### Platform Markers
Throughout the documentation, you'll see platform-specific markers:

- 🍓 **ARM64** - Raspberry Pi 4/5 specific information
- 💻 **AMD64** - x86-64 specific information
- 🌐 **Both** - Applies to both platforms

### Code Blocks
- `inline code` - Commands, file paths, configuration values
- ```bash code blocks``` - Shell commands and scripts
- ```json code blocks``` - JSON configuration examples
- ```yaml code blocks``` - YAML configuration examples

## 🤝 Contributing to Documentation

To improve this documentation:

1. **Fork the repository**
2. **Update the relevant documentation file**
3. **Test any commands or examples**
4. **Submit a pull request**

### Documentation Standards
- Use clear, concise language
- Include platform markers (🍓 💻 🌐)
- Provide working examples
- Test all commands before documenting
- Keep consistency with existing docs

## 📝 Documentation Updates

This documentation is versioned along with the template. See [CHANGELOG.md](../CHANGELOG.md) for documentation changes.

**Last Updated:** v1.0.0 (Initial Release)

## 🔗 External Resources

- [eZansiEdgeAI Organization](https://github.com/eZansiEdgeAI)
- [Podman Documentation](https://docs.podman.io/)
- [Podman Compose Documentation](https://github.com/containers/podman-compose)
- [Capability Contract Specification](capability-contract-spec.md)

## ❓ Need Help?

If you can't find what you're looking for:

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Search the documentation using your IDE/editor
3. Review the [Main README](../README.md)
4. Check the example scripts in `scripts/`
5. Review test examples in `tests/`

---

**Part of the [eZansiEdgeAI](https://github.com/eZansiEdgeAI) platform**
