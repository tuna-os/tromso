kind: cmake
description: Aurora KCM for Universal Blue image rebasing

environment:
  LD_LIBRARY_PATH: /usr/lib

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qttools.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kwidgetsaddons.bst
- boards/common/libgtest.bst

runtime-depends:
- freedesktop-sdk.bst:components/jq.bst
- freedesktop-sdk.bst:components/libnotify.bst

config:
  install-commands:
    (>):
    - |
      install -Dm644 system/usr/share/polkit-1/actions/org.ublue.rebase.policy \
        "%{install-root}%{datadir}/polkit-1/actions/org.ublue.rebase.policy"
    - |
      install -Dm644 system/usr/share/polkit-1/rules.d/21-ublue-rebase.rules \
        "%{install-root}%{datadir}/polkit-1/rules.d/21-ublue-rebase.rules"
    - |
      install -Dm644 system/usr/share/polkit-1/rules.d/22-ublue-rebase-systemd.rules \
        "%{install-root}%{datadir}/polkit-1/rules.d/22-ublue-rebase-systemd.rules"
    - |
      install -Dm644 system/usr/lib/systemd/system/ublue-rebase@.service \
        "%{install-root}%{indep-libdir}/systemd/system/ublue-rebase@.service"
    - |
      install -Dm755 system/usr/libexec/ublue-rebase \
        "%{install-root}%{libexecdir}/ublue-rebase"

sources:
- kind: git_repo
  url: github:ledif/kcm_ublue.git
  track: v[0-9]*
  ref: 75cc31f81f5284bef7a31ff9b8219aae612dff0d
