kind: manual
description: Aurora common branding (sourced from get-aurora-dev/{common,branding})

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: v2026.07-13-g61a8a34481fdf654ab69e21dab035fffb8c196ea
- kind: git_module
  url: github:get-aurora-dev/branding/
  path: branding
  ref: 0063d5ca18e2b7dfddd8af05af86e63604dbb737

depends:
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

public:
  bst:
    overlap-whitelist:
    - /etc/environment
    - /etc/containers/policy.json

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    if [ -d system_files/shared/usr ]; then
      cp -r system_files/shared/usr/./ "%{install-root}%{prefix}/"
    fi
    if [ -d system_files/shared/etc ]; then
      mkdir -p "%{install-root}%{sysconfdir}"
      cp -r system_files/shared/etc/./ "%{install-root}%{sysconfdir}/"
    fi
    if [ -d branding/system_files/etc ]; then
      mkdir -p "%{install-root}%{sysconfdir}"
      cp -r branding/system_files/etc/./ "%{install-root}%{sysconfdir}/"
    fi
    if [ -d branding/system_files/usr ]; then
      cp -r branding/system_files/usr/./ "%{install-root}%{prefix}/"
    fi
    main_qml="%{install-root}%{datadir}/sddm/themes/01-breeze-aurora/Main.qml"
    if [ -f "$main_qml" ]; then
      sed -i '/^[[:space:]]*VirtualKeyboardLoader[[:space:]]*{/,/^[[:space:]]*}[[:space:]]*$/c\
        QtObject {\
            id: inputPanel\
            property bool keyboardActive: false\
            function showHide() {}\
        }' "$main_qml"
    fi
  - "%{install-extra}"
