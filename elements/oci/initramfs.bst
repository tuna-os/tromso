kind: script

build-depends:
- kde-linux-system/generate-initramfs.bst
- oci/initramfs/deps.bst
- oci/initramfs/initial-scripts.bst
- freedesktop-sdk.bst:components/fakecap.bst
- freedesktop-sdk.bst:vm/prepare-image.bst

variables:
  sysroot-seed: 9473a621-1617-4679-87e5-031afef28359

environment:
  LD_PRELOAD: /usr/libexec/fakecap/fakecap.so
  FAKECAP_DB: /fakecap
  ZSTDFLAGS: -T%{max-jobs}
  DLOPEN_NOTE_IGNORE: archive:fido2:qrencode:ip4tc
  INITRD_MODE: oci

environment-nocache:
- ZSTDFLAGS

config:
  commands:
  - mkdir -p /fakecap
  - |
    prepare-image.sh \
       --seed "%{sysroot-seed}" \
       --noroot --noboot >/dev/null

  - |
    version="$(ls -1 /lib/modules | head -n1)"
    generate-initramfs /initramfs-root "${version}" "%{libdir}" "%{libdir}/systemd"

  - |
    (
      cd /initramfs-root
      find . -print0 | sort -z | cpio --reproducible --null -H newc -o --quiet | zstd ${ZSTDFLAGS} >/initramfs.img
    )

  - |
    case '%{arch}' in
      x86_64)
        mkdir -p /microcode/kernel/x86/microcode
        if [ -f /usr/lib/firmware/amd-ucode/microcode_amd_fam17h.bin ]; then
          cat /usr/lib/firmware/amd-ucode/microcode_amd*.bin >/microcode/kernel/x86/microcode/AuthenticAMD.bin
        fi
        if [ -f /usr/lib/firmware/intel-ucode/06-8e-09 ]; then
          # Basic check for intel microcode existence, copy if found
          cp /usr/lib/firmware/intel-ucode/* /microcode/kernel/x86/microcode/ 2>/dev/null || true
        fi
        (
          cd /microcode
          find . -print0 | sort -z | cpio --reproducible --null -H newc -o --quiet >/microcode.img
        )
      ;;
    esac

  - |
    version="$(ls -1 /lib/modules | head -n1)"
    mkdir -p "%{install-root}%{indep-libdir}/modules/${version}"
    mkdir -p "%{install-root}%{indep-libdir}/ostree-boot"
    initrds=()
    case '%{arch}' in
      x86_64)
        if [ -f /microcode.img ]; then
          initrds+=(/microcode.img)
        fi
        ;;
    esac
    initrds+=(/initramfs.img)
    cat "${initrds[@]}" >"%{install-root}%{indep-libdir}/modules/${version}/initramfs.img"
    cat "${initrds[@]}" >"%{install-root}%{indep-libdir}/ostree-boot/initramfs-${version}.img"
