kind: stack
description: >-
  Non-Fedora Aurora analogue of the multimedia override stack: use the
  freedesktop-sdk codecs-extra and mesa-extra extensions that match GNOME OS.

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:extensions/codecs-extra/ffmpeg.bst
- kde-build-meta.bst:freedesktop-sdk.bst:extensions/codecs-extra/libheif.bst
- kde-build-meta.bst:freedesktop-sdk.bst:extensions/codecs-extra/gstreamer-plugins-ugly-x264.bst
- kde-build-meta.bst:freedesktop-sdk.bst:extensions/mesa/mesa-extra.bst
