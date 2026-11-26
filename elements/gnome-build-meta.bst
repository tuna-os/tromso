# gnome-build-meta is the source of the SDK layer (elements/sdk and
# elements/sdk-deps) and, in later steps, the GNOME OS boot elements.
#
# The junction is pinned to the same gnome-51 ref as Dakota so Tromsø and
# Dakota evolve against one upstream. Only the SDK elements are consumed
# today; the gnomeos/ and boot elements are available for steps 6 and 9.
#
# The nested freedesktop-sdk and plugin junctions are overridden so the image
# keeps one base SDK and one BuildStream plugin context. Dakota's
# patches/gnome-build-meta queue is not carried: Tromsø does not use the
# initramfs, recc or systemd paths those patches change yet.
kind: junction

sources:
- kind: git_repo
  url: gnome:gnome-build-meta.git
  track: gnome-51
  ref: 51.1-36-g8a89846df11e86cee57c728a86a247e61d604b84

config:
  options:
    arch: '%{arch}'
    x86_64_v3: false
    (?):
    - arch == 'x86_64' and x86_64_v3:
        x86_64_v3: true

  overrides:
    # One freedesktop-sdk junction for the whole graph.
    freedesktop-sdk.bst: freedesktop-sdk.bst

    # Keep the plugin junctions in one context.
    plugins/buildstream-plugins.bst: plugins/buildstream-plugins.bst
    plugins/buildstream-plugins-community.bst: plugins/buildstream-plugins-community.bst

    # The GNOME apps are not part of the Tromsø image. This keeps the
    # junction's gnomeos stack from pulling the vendored app elements if a
    # later step starts to use it.
    core/meta-gnome-core-apps.bst: core/meta-gnome-core-apps.bst
