kind: manual
description: Noto base UI fonts

sources:
- kind: git_repo
  url: github:notofonts/notofonts.github.io.git
  track: noto-monthly-release-2026.05.01
  ref: 66c4b351c58f99ace5a6265d329080d74b057909

depends:
- freedesktop-sdk.bst:components/fontconfig.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - |
    fontdir="%{install-root}%{datadir}/fonts/noto"
    install -d "$fontdir"
    install -m0644 -t "$fontdir" fonts/NotoSans/googlefonts/ttf/*.ttf
    install -m0644 -t "$fontdir" fonts/NotoSerif/googlefonts/ttf/*.ttf
    install -m0644 -t "$fontdir" fonts/NotoSansMono/googlefonts/ttf/*.ttf
    install -m0644 -t "$fontdir" fonts/NotoSansSymbols/googlefonts/ttf/*.ttf
    install -m0644 -t "$fontdir" fonts/NotoSansSymbols2/googlefonts/ttf/*.ttf

    confdir="%{install-root}%{sysconfdir}/fonts/conf.d"
    install -d "$confdir"
    cat > "$confdir/66-noto-base.conf" <<'EOF'
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>sans-serif</family>
        <prefer><family>Noto Sans</family></prefer>
      </alias>
      <alias>
        <family>serif</family>
        <prefer><family>Noto Serif</family></prefer>
      </alias>
      <alias>
        <family>monospace</family>
        <prefer><family>Noto Sans Mono</family></prefer>
      </alias>
    </fontconfig>
    EOF
  - |
    %{install-extra}
