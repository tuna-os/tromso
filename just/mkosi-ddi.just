# Local-only Mkosi DDI experiment. This exports a GPT disk artifact but is not
# bootable until Tromso provides a non-OCI root/initrd contract; see docs/mkosi-ddi.md.
[group('build')]
build-mkosi-ddi:
    mkosi --directory mkosi/ddi build
