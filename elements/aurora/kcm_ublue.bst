kind: cmake
description: Aurora KCM for Universal Blue image rebasing

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde-build-meta.bst:kde/frameworks/extra-cmake-modules.bst
- kde-build-meta.bst:kde/qt6/qt6-qtbase.bst
- kde-build-meta.bst:kde/qt6/qt6-qtdeclarative.bst
- kde-build-meta.bst:kde/qt6/qt6-qttools.bst
- kde-build-meta.bst:kde/frameworks/kauth.bst
- kde-build-meta.bst:kde/frameworks/kcodecs.bst
- kde-build-meta.bst:kde/frameworks/kcolorscheme.bst
- kde-build-meta.bst:kde/frameworks/kconfig.bst
- kde-build-meta.bst:kde/frameworks/kconfigwidgets.bst
- kde-build-meta.bst:kde/frameworks/kcoreaddons.bst
- kde-build-meta.bst:kde/frameworks/ki18n.bst
- kde-build-meta.bst:kde/frameworks/kcmutils.bst
- kde-build-meta.bst:kde/frameworks/kservice.bst
- kde-build-meta.bst:kde/frameworks/kwidgetsaddons.bst
- kde-build-meta.bst:boards/common/libgtest.bst

runtime-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:components/jq.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/libnotify.bst

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
  track: v0.6.1
  ref: 75cc31f81f5284bef7a31ff9b8219aae612dff0d
