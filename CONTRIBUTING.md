# Contributing

Thanks for your interest in contributing! This project is part of the [TunaOS](https://tunaos.org) ecosystem.

## Getting Started

1. Fork the repo and clone it locally.
2. Read the [project README](README.md) and
   [CI and ISO pipeline guide](docs/ci-and-iso-pipeline.md).
3. Open an issue to discuss your change before submitting a PR.

BuildStream must run through the repository's pinned container wrapper. Do
not invoke `bst` directly on the host:

```bash
just bst show --deps all oci/tromso.bst
```

## Validation

Run the checks relevant to your change before opening a pull request:

```bash
# Parse all Just recipes
just --summary >/dev/null
just --evaluate >/dev/null

# Unit tests (requires bats and pytest)
just test
# Or directly: bats tests/bats/*.bats && pytest tests/pytest/ -v --tb=short

# Container linting (requires built image)
just lint

# Validate the shipping BuildStream graph in the pinned container
just bst --no-interactive show --deps all oci/tromso.bst
```

Changes to shell scripts, YAML, or GitHub Actions should also run
ShellCheck, yamllint with `.yamllint.yml`, or actionlint respectively.

## Pull Requests

- Keep PRs focused — one change per PR.
- Follow the existing code style and conventions.
- Update docs if your change affects usage.

## Questions?

- [TunaOS Documentation](https://tunaos.org)
- [Tromso GitHub Issues](https://github.com/tuna-os/tromso/issues)
