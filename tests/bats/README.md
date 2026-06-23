# BATS Tests for tuna-os/tromso

This directory contains [BATS](https://github.com/bats-core/bats-core) (Bash Automated
Testing System) tests for the Tromso OS build scripts.

## Running

```bash
# Install BATS
sudo apt-get install bats

# Run all tests
bats tests/bats/*.bats

# Run a single test file
bats tests/bats/test_build_iso.bats
```

## Adding Tests

1. Create `tests/bats/test_<script-name>.bats`
2. Use `setup()` to prepare the test environment
3. Test error paths, argument validation, and usage messages
4. Avoid running expensive build operations
