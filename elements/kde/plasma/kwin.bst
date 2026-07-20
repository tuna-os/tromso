kind: cmake
description: kwin

depends:
- freedesktop-sdk.bst:components/libinput.bst
- core-deps/libdisplay-info.bst
- freedesktop-sdk.bst:components/xorg-lib-xcvt.bst

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- kde/frameworks/kdoctools.bst
- kde/frameworks/krunner.bst
- kde/frameworks/plasma-wayland-protocols.bst
# Wayland / graphics / input
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/libinput.bst
- freedesktop-sdk.bst:components/libdrm.bst
- freedesktop-sdk.bst:components/libcap.bst
- freedesktop-sdk.bst:components/systemd-libs.bst
- freedesktop-sdk.bst:components/pipewire-daemon.bst
- core-deps/libdisplay-info.bst
# Plasma inter-deps
- kde/qt6/qt6-qt5compat.bst
- kde/qt6/qt6-qtsvg.bst
- kde/plasma/kdecoration.bst
- kde/plasma/kscreenlocker.bst
- kde/plasma/kwayland.bst
- kde/plasma/libplasma.bst
- kde/plasma/plasma-activities.bst
- kde/plasma/kglobalacceld.bst

- kde/frameworks/kirigami.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtwayland.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kidletime.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kservice.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/kdeclarative.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/karchive.bst
- kde/frameworks/kio.bst
- kde/frameworks/breeze-icons.bst
- kde/libs/libqaccessibilityclient.bst
- kde/plasma/libkscreen.bst
- kde/plasma/aurorae.bst
- kde/plasma/breeze.bst
- kde/plasma/knighttime.bst
# X11 libraries needed by kwin's X11 integration
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xorg-lib-xfixes.bst
- freedesktop-sdk.bst:components/xcb-util.bst
- freedesktop-sdk.bst:components/xcb-util-cursor.bst
- freedesktop-sdk.bst:components/xcb-util-wm.bst
- freedesktop-sdk.bst:components/xcb-util-keysyms.bst
# GPU buffer management and mode computation
- freedesktop-sdk.bst:components/dummy-gbm.bst
- freedesktop-sdk.bst:components/xorg-lib-xcvt.bst
- freedesktop-sdk.bst:components/xwayland.bst
# Vulkan support
- freedesktop-sdk.bst:components/vulkan-headers.bst
variables:
  cmake-local: >-
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6DocTools=ON
    -DBUILD_TESTING=OFF
    -DBUILD_HTML_DOCS=OFF
    -DBUILD_MAN_DOCS=OFF
    -DBUILD_QTHELP_DOCS=OFF
    -DBUILD_DOC=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DKF_SKIP_PO_PROCESSING=ON
    -DBUILD_QT5=OFF
    -DBUILD_WITH_QT6=ON
    -DQT_MAJOR_VERSION=6
    -DKWIN_BUILD_X11=ON
    -DBUILD_WINDOW_KILLER=OFF

sources:
- kind: git_repo
  url: kde:plasma/kwin.git
  track: master
  ref: v6.5.90-429-g36a51bdf68aa263a4871d9128ff976ea04e7e70f
