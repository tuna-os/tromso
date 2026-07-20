kind: manual

config:
  build-commands: []

  install-commands:
  - |
    install -dm 755 %{install-root}%{sysconfdir}/security/limits.d
    cat > %{install-root}%{sysconfdir}/security/limits.d/10-realtime.conf << 'EOF'
    @realtime   -   rtprio     98
    @realtime   -   memlock    unlimited
    EOF
  - |
    install -dm 755 %{install-root}%{prefix}/lib/sysusers.d
    echo 'g realtime - -' > %{install-root}%{prefix}/lib/sysusers.d/realtime-privileges.conf
  - |
    install -dm 755 %{install-root}%{prefix}/lib/systemd/system-preset
    echo 'enable realtime-privileges.service' > %{install-root}%{prefix}/lib/systemd/system-preset/90-realtime-privileges.preset

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''
