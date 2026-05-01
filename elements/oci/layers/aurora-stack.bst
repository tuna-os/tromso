kind: stack
description: Aurora layer — KDE Linux base stack plus Aurora-specific additions

depends:
  # Full KDE Linux base — included here so build-oci does not generate
  # whiteout entries for any KDE Linux files missing from the Aurora layer
  - kde-build-meta.bst:oci/kde-linux/stack.bst
  # Aurora additions and overrides (os-release last so it wins over KDE Linux)
  - aurora/deps.bst
  - oci/os-release.bst
