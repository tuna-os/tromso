kind: script
description: Prefer KDE Linux Noto font defaults for generic font families

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ''

config:
  commands:
  - |
    mkdir -p "%{install-root}/usr/lib"
    ln -snf ../share/fonts "%{install-root}/usr/lib/fonts"
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/fonts/conf.d/56-kde-linux-noto.conf" <<'EOF'
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <!--
      Adapted from invent.kde.org/kde-linux/kde-linux
      mkosi.extra/usr/share/fontconfig/conf.default/56-kde-linux-noto.conf
    -->
    <fontconfig>
      <alias>
        <family>serif</family>
        <prefer>
          <family>Tinos</family>
          <family>Noto Serif</family>
          <family>Noto Serif CJK SC</family>
          <family>Noto Naskh Arabic</family>
          <family>Noto Serif Thai</family>
          <family>Noto Serif Armenian</family>
          <family>Noto Serif Georgian</family>
          <family>Noto Serif Devanagari</family>
          <family>Noto Serif Hebrew</family>
          <family>Noto Serif Bangali</family>
          <family>Noto Serif Gujarati</family>
          <family>Noto Serif Kannada</family>
          <family>Noto Serif Malayalam</family>
          <family>Noto Serif Tamil</family>
          <family>Noto Serif Telugu</family>
          <family>Lohit Punjabi</family>
          <family>Lohit Oriya</family>
          <family>Noto Serif Khmer</family>
          <family>Noto Serif Lao</family>
          <family>Noto Serif Ethiopic</family>
          <family>Noto Serif Myanmar</family>
          <family>Noto Serif Sinhala</family>
          <family>Jomolhari</family>
          <family>Noto Color Emoji</family>
          <family>Noto Sans Symbols</family>
          <family>Noto Sans Symbols2</family>
          <family>DejaVu Serif</family>
        </prefer>
      </alias>
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Arimo</family>
          <family>Noto Sans</family>
          <family>Noto Sans CJK SC</family>
          <family>Noto Sans Arabic</family>
          <family>Noto Sans Thai</family>
          <family>Noto Sans Devanagari</family>
          <family>Noto Sans Tamil</family>
          <family>Noto Sans Hebrew</family>
          <family>Noto Sans Bengali</family>
          <family>Noto Sans Telugu</family>
          <family>Noto Sans Kannada</family>
          <family>Noto Sans Malayalam</family>
          <family>Noto Sans Gurmukhi</family>
          <family>Noto Sans Gujarati</family>
          <family>Noto Sans Oriya</family>
          <family>Noto Sans Armenian</family>
          <family>Noto Sans Georgian</family>
          <family>Noto Sans Khmer</family>
          <family>Noto Sans Lao</family>
          <family>Noto Sans Ethiopic</family>
          <family>Noto Sans Myanmar</family>
          <family>Noto Sans Sinhala</family>
          <family>Jomolhari</family>
          <family>Noto Sans Coptic</family>
          <family>Noto Sans Deseret</family>
          <family>Noto Sans TaiTham</family>
          <family>Noto Sans CanadianAboriginal</family>
          <family>Noto Sans Yi</family>
          <family>Noto Sans Tifinagh</family>
          <family>Noto Sans Adlam</family>
          <family>Noto Sans Cherokee</family>
          <family>Noto Sans Chakma</family>
          <family>Noto Sans Osage</family>
          <family>Noto Color Emoji</family>
          <family>Noto Sans Symbols</family>
          <family>Noto Sans Symbols2</family>
          <family>DejaVu Sans</family>
        </prefer>
      </alias>
      <alias>
        <family>monospace</family>
        <prefer>
          <family>Cousine</family>
          <family>Noto Sans Mono</family>
          <family>Noto Sans Mono CJK SC</family>
          <family>Noto Naskh Arabic</family>
          <family>Noto Sans Thai</family>
          <family>Noto Sans Devanagari</family>
          <family>Noto Sans Tamil</family>
          <family>Noto Sans Bengali</family>
          <family>Noto Sans Telugu</family>
          <family>Noto Sans Kannada</family>
          <family>Noto Sans Malayalam</family>
          <family>Noto Sans Gurmukhi</family>
          <family>Noto Sans Gujarati</family>
          <family>Noto Sans Oriya</family>
          <family>Noto Sans Armenian</family>
          <family>Noto Sans Georgian</family>
          <family>Noto Sans Ethiopic</family>
          <family>Noto Sans Myanmar</family>
          <family>Noto Sans Sinhala</family>
          <family>Noto Sans Tibetan</family>
          <family>Noto Sans Coptic</family>
          <family>Noto Sans Deseret</family>
          <family>Noto Sans TaiTham</family>
          <family>Noto Sans Cherokee</family>
          <family>Noto Sans Chakma</family>
          <family>Noto Sans Osage</family>
          <family>Noto Color Emoji</family>
          <family>Noto Sans Symbols</family>
          <family>Noto Sans Symbols2</family>
          <family>Droid Sans Fallback</family>
          <family>DejaVu Sans Mono</family>
        </prefer>
      </alias>
      <alias>
        <family>ui-sans</family>
        <prefer>
          <family>Noto Sans UI</family>
          <family>Noto Sans CJK SC</family>
          <family>Noto Naskh Arabic UI</family>
          <family>Noto Sans Thai UI</family>
          <family>Noto Sans Devanagari UI</family>
          <family>Noto Sans Tamil UI</family>
          <family>Noto Sans Hebrew</family>
          <family>Noto Sans Bengali UI</family>
          <family>Noto Sans Telugu UI</family>
          <family>Noto Sans Kannada UI</family>
          <family>Noto Sans Malayalam UI</family>
          <family>Noto Sans Gurmukhi UI</family>
          <family>Noto Sans Gujarati UI</family>
          <family>Noto Sans Oriya UI</family>
          <family>Noto Sans Armenian</family>
          <family>Noto Sans Georgian</family>
          <family>Noto Sans Khmer UI</family>
          <family>Noto Sans Lao UI</family>
          <family>Noto Sans Ethiopic</family>
          <family>Noto Sans Myanmar UI</family>
          <family>Noto Color Emoji</family>
          <family>Noto Symbols</family>
          <family>Droid Sans Fallback</family>
          <family>DejaVu Sans</family>
        </prefer>
      </alias>
    </fontconfig>
    EOF

public:
  bst:
    split-rules:
      runtime:
        (>):
        - '%{libdir}/fonts'
        - '%{sysconfdir}/fonts/conf.d/56-kde-linux-noto.conf'
