kind: manual
description: Aurora-layer packaging for the Glow CLI from upstream source

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:components/go.bst

depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

sources:
- kind: git_repo
  url: github:charmbracelet/glow.git
  track: 'v[0-9]*.[0-9]*.[0-9]*'
  ref: f57087499b407d420cdad1d76d0e1ed33c77a3d8

config:
  build-commands:
  - |
    export GOTOOLCHAIN=auto
    export GOPROXY=https://proxy.golang.org,direct
    go mod download
  - |
    export CGO_CPPFLAGS="${CPPFLAGS}"
    export CGO_CFLAGS="${CFLAGS}"
    export CGO_CXXFLAGS="${CXXFLAGS}"
    export CGO_LDFLAGS="${LDFLAGS}"
    export GOTOOLCHAIN=auto
    export GOPROXY=https://proxy.golang.org,direct
    export GOFLAGS="-buildmode=pie -trimpath -ldflags=-linkmode=external -mod=readonly -modcacherw"
    go build -v -ldflags "-X main.Version=v2.1.2" -o glow .
    ./glow completion bash > completion.bash
    ./glow completion fish > completion.fish
    ./glow completion zsh > completion.zsh

  install-commands:
  - |
    install -Dm755 glow "%{install-root}%{bindir}/glow"
  - |
    install -Dm644 completion.bash "%{install-root}%{datadir}/bash-completion/completions/glow"
  - |
    install -Dm644 completion.zsh "%{install-root}%{datadir}/zsh/site-functions/glow.zsh"
  - |
    install -Dm644 completion.fish "%{install-root}%{datadir}/fish/vendor_completions.d/glow.fish"
  - |
    install -Dm644 LICENSE "%{install-root}%{datadir}/licenses/glow/LICENSE"
  - |
    install -Dm644 README.md "%{install-root}%{datadir}/doc/glow/README.md"
  - |
    %{install-extra}
