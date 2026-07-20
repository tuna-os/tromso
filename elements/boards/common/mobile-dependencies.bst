kind: stack
description: generic common zone for dependencies related to the PinePhone Pro & PinePhone.

depends:
- kde-linux-deps/deps.bst
- kde-linux-system/os-release.bst

- core/meta-gnome-core-mobile.bst

- core-deps/ModemManager.bst
- core-deps/feedbackd.bst

- boards/common/alsa-utils.bst
- boards/common/atinout.bst
- boards/common/chatty.bst
- boards/common/eg25-manager.bst
- boards/common/iw.bst
