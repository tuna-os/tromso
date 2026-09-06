kind: stack
description: Tromso layer — KDE Linux base stack plus Tromso-specific additions

depends:
  # Full KDE Linux base — included here so build-oci does not generate
  # whiteout entries for any KDE Linux files missing from the Tromso layer
  - oci/kde-linux/stack.bst
  # Tromso additions and overrides (os-release last so it wins over KDE Linux)
  - tromso/deps.bst
  - oci/os-release.bst
