kind: script
description: Install /etc/containers/policy.json (insecureAcceptAnything default)
  needed by bootc at runtime. The containers-common package installs this file to
  the 'sysconf' split (%{sysconfdir}/**), which is excluded by the aurora-runtime
  compose (only 'runtime, bootc, ostree-boot' are included). Installing it here
  in a dedicated element ensures it lands in the 'runtime' split and is present
  in the final OCI image.

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  commands:
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/containers/policy.json" <<'EOF'
    {
        "default": [
            {
                "type": "insecureAcceptAnything"
            }
        ]
    }
    EOF

public:
  bst:
    split-rules:
      runtime:
        (>):
        - '%{sysconfdir}/containers/policy.json'
