kind: script
description: Aurora KDE Linux OCI image (layered on KDE Linux OS)

build-depends:
  - kde-build-meta.bst:freedesktop-sdk.bst:components/fakecap.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/oci-builder.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/glib.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/sed.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:vm/prepare-image.bst
  - filename: kde-build-meta.bst:oci/kde-linux/image.bst
    config:
      location: /parent
  - filename: oci/layers/tromso.bst
    config:
      location: /layer

environment:
  LD_PRELOAD: /usr/libexec/fakecap/fakecap.so
  FAKECAP_DB: /fakecap

variables:
  sysroot-seed: a1b2c3d4-e5f6-7890-abcd-ef1234567890
  (?):
  - arch == "x86_64":
      go-arch: amd64
  - arch == "aarch64":
      go-arch: arm64

config:
  commands:
    - mkdir /fakecap
    - |
      # depmod treats every entry in lib/modules/ as a kernel version string;
      # remove stray JSON files (e.g. KWin effect configs) before it runs.
      find /layer/lib/modules/ -name "*.json" -delete 2>/dev/null || true
    - |
      prepare-image.sh \
         --sysroot /layer \
         --initscripts /initial_scripts \
         --seed "%{sysroot-seed}" \
         --noroot --noboot

    - |
      systemd-sysusers --root /layer

    - |
      if [ -d /layer/usr/share/glib-2.0/schemas ]; then
        glib-compile-schemas /layer/usr/share/glib-2.0/schemas
      fi

    - |
      systemctl --root=/layer enable sshd.service || true

    - |
      if [ -d /layer/usr/etc ]; then
        mkdir -p /layer/etc
        cp -a /layer/usr/etc/. /layer/etc/
        rm -rf /layer/usr/etc
      fi
    - |
      # The shadow package seeds empty subordinate ID files; populate them
      # after /usr/etc has been materialized into /etc so rootless podman in
      # the greeter session gets a real range.
      for dir in /layer/etc /layer/usr/share/factory/etc; do
        mkdir -p "$dir"
        printf '%s\n' 'sddm:100000:65536' >"$dir/subuid"
        printf '%s\n' 'sddm:100000:65536' >"$dir/subgid"
        chmod 0644 "$dir/subuid" "$dir/subgid"
      done
      # Compose/export loses the capability applied earlier in the stack, so
      # restore it on the final filesystem that bootc installs.
      setcap cap_sys_nice+ep /layer/usr/bin/kwin_wayland
      setcap cap_setuid+ep /layer/usr/bin/newuidmap
      setcap cap_setgid+ep /layer/usr/bin/newgidmap
      # Refresh linker cache in the composed rootfs so SDDM can resolve Qt6
      # libraries installed under /usr/lib at first boot.
      # Qt6 core libs live in /parent/usr/lib (KDE Linux base image); chrooting
      # only into /layer misses them.  Mount parent+layer as an overlay so
      # ldconfig sees the full merged /usr/lib and writes the correct cache into
      # /layer/etc/ld.so.cache (overlay upper-dir write-back).
      if [ ! -f /layer/etc/ld.so.conf ]; then
        printf 'include /etc/ld.so.conf.d/*.conf\n' > /layer/etc/ld.so.conf
      fi
      mkdir -p /ld-work /ld-merged
      if timeout 30 mount -t overlay overlay \
           -o "lowerdir=/parent,upperdir=/layer,workdir=/ld-work" \
           /ld-merged 2>/dev/null; then
        timeout 60 chroot /ld-merged ldconfig || true
        umount /ld-merged || true
      else
        timeout 60 chroot /layer ldconfig || true
      fi
      rm -rf /ld-merged /ld-work 2>/dev/null || true
    - |
      # Force an explicit font family in the SDDM/Breeze QML that renders the
      # greeter text. Live guest testing showed this changes the framebuffer,
      # while rebuilding font cache alone did not.
      for login_qml in \
        /layer/usr/share/sddm/themes/01-breeze-aurora/Login.qml \
        /layer/usr/share/sddm/themes/breeze/Login.qml; do
        if [ -f "$login_qml" ]; then
          sed -i 's|^\([[:space:]]*font\.pointSize: fontSize + 1\)$|\1\
              font.family: "Noto Sans"|' "$login_qml"
        fi
      done
      action_button_qml=/layer/usr/lib/qml/org/kde/breeze/components/ActionButton.qml
      if [ -f "$action_button_qml" ]; then
        sed -i 's|^\([[:space:]]*font\.pointSize: Kirigami\.Theme\.defaultFont\.pointSize + 1\)$|\1\
            font.family: "Noto Sans"|' "$action_button_qml"
      fi
      user_delegate_qml=/layer/usr/lib/qml/org/kde/breeze/components/UserDelegate.qml
      if [ -f "$user_delegate_qml" ]; then
        sed -i 's|^\([[:space:]]*font\.pointSize: wrapper\.fontSize + 4\)$|\1\
              font.family: "Noto Sans"|' "$user_delegate_qml"
      fi
      session_management_qml=/layer/usr/lib/qml/org/kde/breeze/components/SessionManagementScreen.qml
      if [ -f "$session_management_qml" ]; then
        sed -i 's|^\([[:space:]]*font\.pointSize: root\.fontSize\)$|\1\
                  font.family: "Noto Sans"|' "$session_management_qml"
      fi
      clock_qml=/layer/usr/lib/qml/org/kde/breeze/components/Clock.qml
      if [ -f "$clock_qml" ]; then
        sed -i 's|^\([[:space:]]*font\.pointSize: Math\.round(Kirigami\.Theme\.defaultFont\.pointSize \* 7\.2)\)$|\1\
              font.family: "Noto Sans"|' "$clock_qml"
        sed -i 's|^\([[:space:]]*font\.pointSize: Math\.round(Kirigami\.Theme\.defaultFont\.pointSize \* 2\.4)\)$|\1\
              font.family: "Noto Sans"|' "$clock_qml"
      fi
      battery_qml=/layer/usr/lib/qml/org/kde/breeze/components/Battery.qml
      if [ -f "$battery_qml" ]; then
        sed -i 's|^\([[:space:]]*font\.pointSize: root\.fontSize\)$|\1\
              font.family: "Noto Sans"|' "$battery_qml"
      fi

    - |
      cd "%{install-root}"
      build-oci <<EOF
      mode: oci
      gzip: gzip
      images:
      - os: linux
        architecture: "%{go-arch}"
        parent:
          image: /parent
        layer: /layer
        comment: "Aurora Tromso - KDE Plasma desktop (layered on KDE Linux)"
        config:
          Labels:
            'com.github.containers.toolbox': 'true'
            'org.opencontainers.image.title': 'Aurora Tromso'
            'org.opencontainers.image.description': 'Aurora Tromso KDE Plasma desktop, layered on KDE Linux'
            'org.opencontainers.image.vendor': 'TunaOS'
            'org.opencontainers.image.licenses': 'Apache-2.0'
            'org.opencontainers.image.url': 'https://github.com/tuna-os/tromso'
            'org.opencontainers.image.source': 'https://github.com/tuna-os/tromso'
            'containers.bootc': '1'
        index-annotations:
          'org.opencontainers.image.ref.name': 'ghcr.io/tuna-os/tromso:latest'
      EOF
