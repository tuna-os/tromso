kind: stack
description: >-
  Stub: tuned-ppd power profile compatibility daemon
# NOTE: tuned-ppd is NOT a standalone package. It is a component of the
# `tuned` project (https://github.com/redhat-performance/tuned), available
# since tuned v2.21.0. It provides a D-Bus API compatible with
# power-profiles-daemon, backed by tuned profiles.
#
# To include tuned-ppd in Aurora, the full `tuned` package would need to be
# packaged as a BST element. tuned is a Python-based daemon with a large
# set of profiles; see:
#   https://github.com/redhat-performance/tuned/releases
#
# Alternatively, consider using power-profiles-daemon directly
# (freedesktop-sdk does not currently ship it; gnome-build-meta may have it).
# For KDE Plasma's PowerDevil, power-profiles-daemon is the preferred backend.
#
# This stub element exists to document the dependency intent.

depends: []
