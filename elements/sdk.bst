# Process for adding components to SDK:
# https://gitlab.gnome.org/GNOME/gnome-build-meta/-/wikis/home#process-to-add-components-to-the-sdk
#
# Process for removing components from SDK:
# https://gitlab.gnome.org/GNOME/gnome-build-meta/-/wikis/home#process-to-remove-components-from-sdk
kind: stack
depends:
- sdk-platform.bst
- gnome-build-meta.bst:sdk/gi-docgen.bst
- gnome-build-meta.bst:sdk/gtk-doc.bst
- gnome-build-meta.bst:sdk/sysprof-agent.bst
- gnome-build-meta.bst:sdk/sysprof-minimal.bst
- gnome-build-meta.bst:sdk/vala.bst
- gnome-build-meta.bst:sdk/yelp-tools.bst
- freedesktop-sdk.bst:components/appstream.bst
- freedesktop-sdk.bst:components/libabigail.bst
- freedesktop-sdk.bst:components/ruby.bst
- freedesktop-sdk.bst:sdk.bst
