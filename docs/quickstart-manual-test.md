# Quickstart Manual Test (Cold Start)

This is a manual, cold-start checklist for developers creating a new capability from this template.

Goal: prove your capability works standalone, then prove it can be invoked via the `ezansi-platform-core` gateway.

## Mental model (LEGO bricks)

- **Your capability = one LEGO brick** (a single responsibility service)
- **`capability.json` = the studs** (what your brick provides + how to call it)
- **Platform Core = the baseplate** (one gateway that discovers bricks and routes requests)

## Prerequisites

- `podman`, `podman-compose`
- `curl`
- Optional: `jq` (pretty-print JSON)

Install notes (Linux):

- Prefer distro packages when available (e.g. `sudo apt install podman podman-compose`).
- If your distro does not package `podman-compose`, you can fall back to `pip3 install --user podman-compose`.

## 1) Cold start: deploy

From the repo root:

```bash
# If you have a local Containerfile/build, include --build on cold start
podman-compose up -d --build

# Or use the template deploy helper (supports profile selection)
./scripts/deploy.sh --profile pi5 --build --yes
```

## 2) Standalone checks

Health check (adjust the port/path to match your capability):

```bash
curl -fsS http://localhost:8080/health
```

Contract self-hosting (recommended if you expose it):

```bash
curl -fsS http://localhost:8080/.well-known/capability.json | jq
```

If you don’t implement `/.well-known/capability.json`, remove that endpoint from `capability.json`.

## 3) Invoke via ezansi-platform-core gateway (integration)

This requires:

- `ezansi-platform-core` running on `http://localhost:8000`
- your contract copied into platform-core’s `./capabilities/**/capability.json`

Example (from the platform-core repo root):

```bash
mkdir -p capabilities/my-capability
cp ../my-capability-repo/capability.json capabilities/my-capability/capability.json
podman-compose up -d --build

# Sanity checks
curl -fsS http://localhost:8000/health
curl -fsS http://localhost:8000/registry | jq
```

### Call your capability through the gateway (preferred)

If your contract defines a named endpoint (recommended), call it via `payload.endpoint`.

```bash
curl -fsS -X POST http://localhost:8000/ \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "custom-service",
    "payload": {
      "endpoint": "main",
      "params": {},
      "json": {"example": "replace with your real request body"}
    }
  }' | jq
```

Notes:

- Platform Core prefers `payload.endpoint` (a named endpoint from `capability.json`).
- Use `payload.params` only if your endpoint path contains `{placeholders}`.
- Only use `payload.path` as a legacy escape hatch.

## Teardown

```bash
podman-compose down
```
