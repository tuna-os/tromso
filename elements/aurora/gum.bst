kind: manual
description: Aurora-layer packaging for the Gum CLI from upstream source

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:components/go.bst

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

sources:
- kind: git_repo
  url: github:charmbracelet/gum.git
  track: 'v[0-9]*.[0-9]*.[0-9]*'
  ref: 6045525ab92f75c169d3c69596844d8748437e37

config:
  build-commands:
  - |
    export GOPROXY=https://proxy.golang.org,direct
    go mod download
  - |
    export CGO_CPPFLAGS="${CPPFLAGS}"
    export CGO_CFLAGS="${CFLAGS}"
    export CGO_CXXFLAGS="${CXXFLAGS}"
    export GOPROXY=https://proxy.golang.org,direct
    export GOFLAGS="-buildmode=pie -trimpath -mod=readonly -modcacherw"
    go build -v \
      -ldflags "-compressdwarf=false -linkmode external -extldflags \"${LDFLAGS}\" -X main.Version=v0.17.0 -X main.CommitSHA=unknown -X main.CommitDate=unknown" \
      -o gum .
    ./gum man > gum.1
    ./gum completion bash > completion.bash
    ./gum completion fish > completion.fish
    ./gum completion zsh > completion.zsh

  install-commands:
  - |
    install -Dm755 gum "%{install-root}%{bindir}/gum"
  - |
    install -Dm644 completion.bash "%{install-root}%{datadir}/bash-completion/completions/gum"
  - |
    install -Dm644 completion.zsh "%{install-root}%{datadir}/zsh/site-functions/gum.zsh"
  - |
    install -Dm644 completion.fish "%{install-root}%{datadir}/fish/vendor_completions.d/gum.fish"
  - |
    install -Dm644 gum.1 "%{install-root}%{datadir}/man/man1/gum.1"
  - |
    install -Dm644 LICENSE "%{install-root}%{datadir}/licenses/gum/LICENSE"
  - |
    install -Dm644 README.md "%{install-root}%{datadir}/doc/gum/README.md"
  - |
    %{install-extra}
