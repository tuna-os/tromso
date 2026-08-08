#!/bin/bash
# Dracut module: override the default Plymouth theme symlink from text to
# breeze-bgrt, and include the breeze-bgrt theme files in the initramfs.
#
# The stock 50plymouth module in --no-hostonly mode only installs text +
# details themes.  This module runs later (priority 96 > 50) and:
#   1. Installs the breeze-bgrt theme files
#   2. Points default.plymouth at breeze-bgrt/breeze-bgrt.plymouth
#
# Together with `splash` on the kernel cmdline (in build-iso.sh) and the
# plymouth + breeze-bgrt theme copied from tromso-ref (Containerfile stage 2),
# this gives the live ISO the same branded splash + graphical LUKS prompt as
# a bootc-installed system (tromso#84).

check() {
    return 0
}

depends() {
    echo plymouth
    return 0
}

install() {
    local theme_dir="/usr/share/plymouth/themes/breeze-bgrt"
    if [[ -d "$dracutsysrootdir$theme_dir" ]]; then
        for f in "$dracutsysrootdir$theme_dir"/*; do
            [[ -f "$f" ]] || continue
            inst "$f"
        done
        # Override the text-theme symlink set by 50plymouth in non-hostonly mode
        rm -f "${initdir}/usr/share/plymouth/themes/default.plymouth"
        ln -sf "breeze-bgrt/breeze-bgrt.plymouth" "${initdir}/usr/share/plymouth/themes/default.plymouth"
    fi
}
