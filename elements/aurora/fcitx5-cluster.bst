kind: stack
description: >-
  Reference-backed fcitx5 subset currently available in this BuildStream stack:
  the GNOME/Dakota fcitx5-gtk override that enables GTK input method modules.

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:components/fcitx5-gtk.bst
