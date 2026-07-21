kind: cmake
description: plasma-workspace

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/baloo.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/networkmanager-qt.bst
- kde/frameworks/plasma-wayland-protocols.bst
- kde/libs/qcoro.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtlocation.bst
- kde/qt6/qt6-qtpositioning.bst
- kde/qt6/qt6-qtsvg.bst
# X11 libs needed by ksmserver (ICE/SM for session management)
- freedesktop-sdk.bst:components/xorg-lib-ice.bst
- freedesktop-sdk.bst:components/xorg-lib-sm.bst
# System libs
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/pipewire-daemon.bst
- freedesktop-sdk.bst:components/linux-pam-base.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/libxslt.bst
- freedesktop-sdk.bst:components/docbook-xml.bst
- freedesktop-sdk.bst:components/docbook-xsl.bst
# Plasma inter-deps (kwin brings X11 support via its dependencies)
- kde/plasma/kwin.bst
- kde/plasma/kscreenlocker.bst
- kde/plasma/layer-shell-qt.bst
- kde/plasma/libkscreen.bst
- kde/plasma/libplasma.bst
- kde/plasma/kwayland.bst
- kde/plasma/plasma-activities.bst
- kde/plasma/plasma-activities-stats.bst
- kde/plasma/plasma5support.bst
- kde/plasma/libksysguard.bst
- kde/plasma/kpipewire.bst
- kde/plasma/knighttime.bst
- kde/plasma/breeze.bst
- kde/libs/libcanberra.bst
- kde/libs/polkit-qt-1.bst

- kde/frameworks/kirigami.bst
- kde/libs/kirigami-addons.bst
- kde/frameworks/kquickcharts.bst
- kde/frameworks/kuserfeedback.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtshadertools.bst
- kde/qt6/qt6-qtwayland.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kdeclarative.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kholidays.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/breeze-icons.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kded.bst
- kde/frameworks/kio.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kparts.bst
- kde/frameworks/prison.bst
- kde/frameworks/krunner.bst
- kde/frameworks/kstatusnotifieritem.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/ktexteditor.bst
- kde/frameworks/ktextwidgets.bst
- kde/frameworks/kwallet.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kxmlgui.bst

variables:
  cmake-local: >-
    -DCMAKE_INSTALL_LIBEXECDIR=lib
    -DGLIBC_LOCALE_GEN=OFF
    -DBUILD_TESTING=OFF
    -DBUILD_X11=OFF
    -DDocBookXML4_DTD_DIR=/usr/share/xml/docbook/xml-dtd/4.5
    -DDocBookXSL_DIR=/usr/share/xml/docbook/xml/xsl-stylesheets

sources:
- kind: git_repo
  url: kde:plasma/plasma-workspace.git
  track: master
  ref: v6.5.90-473-g851b49ff898ed108d5890af42d0f6e2be50a8ac4
- kind: patch
  path: patches/plasma-workspace/0001-make-qt6location-optional.patch
- kind: patch
  path: patches/plasma-workspace/0002-make-kf6-texteditor-textwidgets-optional.patch
- kind: patch
  path: patches/plasma-workspace/0003-skip-kwin-virtualkeyboard-dbus-interface.patch
- kind: patch
  path: patches/plasma-workspace/0004-make-breeze-optional.patch
- kind: patch
  path: patches/plasma-workspace/0005-make-baloo-optional.patch
- kind: patch
  path: patches/plasma-workspace/0006-make-interactiveconsole-optional.patch
- kind: patch
  path: patches/plasma-workspace/0007-make-shellprivate-textwidgets-optional.patch
