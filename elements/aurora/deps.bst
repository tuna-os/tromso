kind: stack
description: Aurora-specific additions over KDE Linux base (mirrors dakota/elements/bluefin/deps.bst)

depends:
  # KDE Linux base provides Plasma, Frameworks, Qt6, Apps, kernel, systemd, bootc,
  # pipewire, networkmanager, polkit, mesa, podman, skopeo, sshd, etc.
  # Only list what Aurora adds *on top* of the base image here.

  # Branding (sourced from get-aurora-dev/common + get-aurora-dev/branding)
  - aurora/common.bst

  # System infrastructure (hardware enablement, printing, CLI tools)
  - aurora/hardware-enablement.bst
  - aurora/printing.bst
  - aurora/system-cli-tools.bst

  # Developer tooling (Aurora ships these in addition to base)
  - kde-build-meta.bst:freedesktop-sdk.bst:components/buildstream2.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/debuginfod.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/bpf.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/vmlinuxh.bst
  - kde-build-meta.bst:core/sysprof-app.bst
