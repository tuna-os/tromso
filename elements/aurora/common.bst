kind: manual
description: Aurora common branding (sourced from get-aurora-dev/{common,branding})

sources:
- kind: git_repo
  url: github:get-aurora-dev/common.git
  track: main
  ref: a40eb75e00df196d264e09cc9022f642be4304f0
- kind: git_module
  url: github:get-aurora-dev/branding/
  path: aurora-branding
  ref: a2609104f6b20da64a29b002b7bf0428b466e251

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:components/sed.bst
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

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
    if [ -d aurora-branding/system_files/etc ]; then
      mkdir -p "%{install-root}%{sysconfdir}"
      cp -r aurora-branding/system_files/etc/./ "%{install-root}%{sysconfdir}/"
    fi
    if [ -d aurora-branding/system_files/usr ]; then
      cp -r aurora-branding/system_files/usr/./ "%{install-root}%{prefix}/"
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
