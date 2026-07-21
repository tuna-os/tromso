kind: cmake
description: sddm - Simple Desktop Display Manager

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qttools.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/xorg-lib-xau.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst

depends:
- freedesktop-sdk.bst:components/dejavu-fonts.bst
- freedesktop-sdk.bst:components/fontconfig.bst
- freedesktop-sdk.bst:components/linux-pam-base.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/xorg-lib-xau.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst

variables:
  cmake-local: >-
    -DBUILD_TESTING=OFF
    -DENABLE_JOURNALD=ON
    -DNO_SYSTEMD=OFF
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DBUILD_WITH_QT6=ON
    -DQt6_DIR=/usr/lib/cmake/Qt6
    -DUID_MIN=1000
    -DUID_MAX=60513
    -DQt5_FIND_QUIETLY=ON
    -DCMAKE_FIND_DEBUG_MODE=FALSE

sources:
- kind: git_repo
  url: github:sddm/sddm.git
  track: v0.21.0
  ref: 63780fcd79f1dbf81a30eef48c28c699ab15aded

config:
  install-commands:
    (>):
    - |
      rewrite_pam_includes() {
        pam_file="$1"
        [ -f "$pam_file" ] || return 0

        tmp_file="${pam_file}.tmp"
        : > "$tmp_file"
        while IFS= read -r line || [ -n "$line" ]; do
          line=${line//system-local-login/system-auth}
          line=${line//system-login/system-auth}
          printf '%s\n' "$line" >> "$tmp_file"
        done < "$pam_file"

        install -m 0644 "$tmp_file" "$pam_file"
        rm -f "$tmp_file"
      }

      for pam_file in "%{install-root}%{sysconfdir}/pam.d/sddm" "%{install-root}%{sysconfdir}/pam.d/sddm-autologin"; do
        rewrite_pam_includes "$pam_file"
      done
