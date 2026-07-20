kind: manual

sources:
- kind: git_repo
  url: github:kdave/btrfsmaintenance.git
  track: '[0-9]*.[0-9]*'
  ref: v0.5.2-0-gbeb9e2d166cbd856297fe8d28e89e8b36961a723

config:
  build-commands: []

  install-commands:
  - |
    install -Dm 755 btrfs-scrub.sh %{install-root}%{datadir}/btrfsmaintenance/btrfs-scrub.sh
    install -Dm 755 btrfs-balance.sh %{install-root}%{datadir}/btrfsmaintenance/btrfs-balance.sh
    install -Dm 755 btrfs-trim.sh %{install-root}%{datadir}/btrfsmaintenance/btrfs-trim.sh
    install -Dm 755 btrfs-defrag.sh %{install-root}%{datadir}/btrfsmaintenance/btrfs-defrag.sh
    for f in btrfsmaintenance-refresh.service btrfs-scrub.service btrfs-scrub.timer btrfs-balance.service btrfs-balance.timer btrfs-trim.service btrfs-trim.timer btrfs-defrag.service btrfs-defrag.timer; do
      if [ -f "$f" ]; then
        install -Dm 644 "$f" %{install-root}%{libdir}/systemd/system/"$f"
      fi
    done
    install -Dm 644 sysconfig.btrfsmaintenance %{install-root}%{sysconfdir}/sysconfig/btrfsmaintenance

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/btrfs-progs.bst

variables:
  strip-binaries: ''
