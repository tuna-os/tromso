# Gemini Project Mandates

## Build and Diagnostics
- **ALWAYS** use the `Justfile` for running `bst` (BuildStream) and diagnostic commands.
- The `Justfile` wraps BuildStream inside a specific container (`bst2`) with correct volume mounts and permissions.
- **Example Usage:**
  - `just bst build oci/tromso.bst`
  - `just bst show oci/tromso.bst`
  - `just bst shell oci/tromso.bst`
- Avoid running `bst` directly on the host or via `pipx` unless explicitly instructed, as the containerized environment is the source of truth for reproducibility.
