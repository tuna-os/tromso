kind: manual
description: >-
  Configuration from Bazzite (sysctl, udev, modprobe, limits, zram) and the
  Flatpak list of the OGC variant

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - cp -r usr etc '%{install-root}/'

  # Steam, Lutris and the other launchers are Flatpaks: the image has no
  # 32-bit userspace (docs/OGC.md). The format is that of
  # flatpak-preinstall(1).
  - |
    install -d '%{install-root}%{datadir}/flatpak/preinstall.d'
    for app in \
      com.valvesoftware.Steam \
      net.lutris.Lutris \
      com.heroicgameslauncher.hgl \
      com.vysp3r.ProtonPlus \
      com.github.Matoking.protontricks \
      org.freedesktop.Platform.VulkanLayer.MangoHud//25.08 \
      org.freedesktop.Platform.VulkanLayer.gamescope//25.08 \
    ; do
      id="${app%%//*}"
      branch="${app#*//}"
      [ "${branch}" != "${app}" ] || branch=stable
      runtime=false
      case "${id}" in *.VulkanLayer.*) runtime=true ;; esac
      printf '[Flatpak Preinstall %s]\nBranch=%s\nIsRuntime=%s\n' \
        "${id}" "${branch}" "${runtime}" \
        >"%{install-root}%{datadir}/flatpak/preinstall.d/${id}.preinstall"
    done

public:
  bst:
    overlap-whitelist:
    - "%{datadir}/alsa/ucm2/USB-Audio/Sony/DualSense-PS5.conf"

sources:
# Copies from ublue-os/bazzite b42cdec64f91b8218ff710724099cce6245805e0
# (Apache-2.0). docs/OGC.md has the source of each file.
- kind: local
  path: files/ogc/config
