# ISO assembly builder image (Debian-based)
#
# Used by: just iso-sd-boot tromso
#
# All tools needed to assemble a systemd-boot UEFI live ISO from a
# clean Tromso rootfs tarball (produced by `podman export`).
FROM debian:sid

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xorriso \
        isomd5sum \
        squashfs-tools \
        dosfstools \
        mtools \
    && rm -rf /var/lib/apt/lists/*

COPY src/build-iso.sh /build-iso.sh
RUN chmod +x /build-iso.sh

ENTRYPOINT ["/build-iso.sh"]
