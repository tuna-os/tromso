# Contributing to Aurora Tromso

Thank you for contributing to Aurora Tromso — a BuildStream-based KDE Linux OCI/bootc image.

## Quick Start

### Prerequisites

- Podman (container runtime for BuildStream)
- [`just`](https://github.com/casey/just) (task runner)
- ~100 GB free disk space for build cache
- `git`

### Setup

```bash
git clone https://github.com/tuna-os/tromso.git
cd tromso
```

All BuildStream commands run inside a pinned container image for reproducibility.
**Always use `just` recipes** — never run `bst` directly on the host.

```bash
just --list              # show all available commands
```

## Build Workflow

### Building an image

```bash
# Background build with live log tailing (recommended)
just bst-build

# Foreground build + OCI export
just build

# View build logs
just log
```

Build logs are written to `/var/tmp/aurora-build.log`.

### Running a VM test

```bash
# Generate a bootable disk image (requires a completed build)
just generate-bootable-image

# Boot in QEMU (SSH on port 2222, serial console on port 4444)
just boot-vm
```

## Pre-Commit Checklist

Always run before every commit:

```bash
just fix && just check
```

- `just fix` — format YAML/JSON and check formatting
- `just check` — validate project.conf and element syntax

Commits must be signed with DCO:

```bash
git commit -s -m "description"
```

## Two-Repo Model

Aurora Tromso uses a two-repo model:

| Repo | Role |
|------|------|
| `tuna-os/tromso` | This repo — Aurora-specific layers, OCI composition, CI |
| `hanthor/kde-build-meta` | KDE `.bst` elements — Qt6, Frameworks, Plasma, Apps |

After committing to `kde-build-meta`, update the junction in `elements/kde-build-meta.bst`.
See [`AGENTS.md`](AGENTS.md) for the complete junction update workflow.

## When to Build

| Change type | Build required? |
|---|---|
| `elements/**/*.bst`, `project.conf` | **Yes — always** |
| `Justfile` | Sometimes (if build commands changed) |
| Docs, CI workflows, README | No |

## Pull Request Process

1. Fork the repository and create a feature branch
2. Run `just fix && just check` before pushing
3. Ensure your commits are signed (`git commit -s`)
4. Open a PR against the `main` branch
5. CI will verify the build
6. Address feedback from maintainers

## Architecture

See [`SPEC.md`](SPEC.md) for detailed technical architecture:
- Two-repo model and repository structure
- BuildStream project configuration
- OCI image composition
- Element dependency graph

For agent conventions, see [`AGENTS.md`](AGENTS.md).

## Fixing Build Failures

1. Check the build log: `just log`
2. Find the failed element and its detailed log in `~/.cache/buildstream/logs/`
3. Fix the `.bst` file in `hanthor/kde-build-meta`
4. Clear only the failed element's cache (never clear broadly):
   ```bash
   rm -rf ~/.cache/buildstream/artifacts/refs/gnome/kde-CATEGORY-ELEMENT/
   rm -rf ~/.cache/buildstream/logs/gnome/kde-CATEGORY-ELEMENT/
   ```
5. Commit + push `kde-build-meta`, update junction, restart build

## Documentation

- [SPEC.md](SPEC.md) — technical architecture
- [AGENTS.md](AGENTS.md) — agent conventions and reference rules
- [README.md](README.md) — project overview and quick start

## Community

- [GitHub Issues](https://github.com/tuna-os/tromso/issues)
- Matrix: [#tunaos:reilly.asia](https://matrix.to/#/%23tunaos:reilly.asia)

## License

Aurora Tromso is licensed under [Apache 2.0](LICENSE).
