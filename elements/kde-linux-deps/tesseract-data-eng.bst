kind: manual
description: Tesseract English OCR training data

sources:
- kind: remote
  url: tar_https:github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata
  ref: daa0c97d651c19fba3b25e81317cd697e9908c8208090c94c3905381c23fc047

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

config:
  strip-commands: []
  install-commands:
  - install -Dm644 eng.traineddata '%{install-root}%{datadir}/tessdata/eng.traineddata'
