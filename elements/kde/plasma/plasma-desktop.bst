kind: cmake
description: plasma-desktop

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-cmake.bst
- freedesktop-sdk.bst:components/libinput.bst
- kde/frameworks/extra-cmake-modules.bst
- kde/qt6/qt6-qtbase.bst
- kde/qt6/qt6-qtsvg.bst
- kde/qt6/qt6-qt5compat.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- kde/frameworks/kdoctools.bst
- freedesktop-sdk.bst:components/libpulse.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/xorg-lib-xkbfile.bst
- freedesktop-sdk.bst:components/libwacom.bst
- kde/plasma/kwin.bst
- kde/plasma/kscreenlocker.bst
- kde/plasma/plasma-workspace.bst
- kde/plasma/libplasma.bst
- kde/plasma/plasma-activities.bst
- kde/plasma/plasma-activities-stats.bst
- kde/plasma/plasma5support.bst
- kde/plasma/libksysguard.bst
- kde/plasma/powerdevil.bst
- kde/plasma/systemsettings.bst
- kde/libs/libcanberra.bst
- kde/frameworks/solid.bst

- kde/frameworks/kirigami.bst
- kde/frameworks/kitemmodels.bst
- kde/frameworks/kded.bst
- kde/frameworks/baloo.bst
- kde/qt6/qt6-qtdeclarative.bst
- kde/qt6/qt6-qtwayland.bst
- kde/frameworks/kauth.bst
- kde/frameworks/kcrash.bst
- kde/frameworks/kconfig.bst
- kde/frameworks/ki18n.bst
- kde/frameworks/kcmutils.bst
- kde/frameworks/kconfigwidgets.bst
- kde/frameworks/knewstuff.bst
- kde/frameworks/kio.bst
- kde/frameworks/knotifications.bst
- kde/frameworks/knotifyconfig.bst
- kde/frameworks/attica.bst
- kde/frameworks/krunner.bst
- kde/frameworks/kglobalaccel.bst
- kde/frameworks/kcoreaddons.bst
- kde/frameworks/kguiaddons.bst
- kde/frameworks/kdbusaddons.bst
- kde/frameworks/kwidgetsaddons.bst
- kde/frameworks/kcodecs.bst
- kde/frameworks/sonnet.bst
- kde/frameworks/kpackage.bst
- kde/frameworks/kiconthemes.bst
- kde/frameworks/kwindowsystem.bst
- kde/frameworks/ksvg.bst
- kde/frameworks/kcolorscheme.bst
- kde/frameworks/kxmlgui.bst
- kde/frameworks/kdeclarative.bst
- kde/frameworks/kservice.bst
- kde/frameworks/kbookmarks.bst
- kde/frameworks/kcompletion.bst
- kde/frameworks/kitemviews.bst
- kde/frameworks/kjobwidgets.bst

- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xcb.bst
- freedesktop-sdk.bst:components/xorg-lib-xcursor.bst
- freedesktop-sdk.bst:components/xorg-lib-xi.bst
- freedesktop-sdk.bst:components/xcb-util-keysyms.bst
- freedesktop-sdk.bst:components/xdg-user-dirs.bst
- core-deps/xvfb.bst
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
    -DBUILD_X11=OFF
    -DBUILD_KCM_MOUSE_X11=OFF
    -DBUILD_KCM_TOUCHPAD_X11=OFF
    -DBUILD_KCM_TABLET=OFF

sources:
- kind: git_repo
  url: kde:plasma/plasma-desktop.git
  track: master
  ref: v6.5.90-330-gdaa8621dfef57ea2a187ef6fc006f6d577322ff8
- kind: patch
  path: patches/plasma-desktop/0001-fix-libinput-pkgconfig.patch
