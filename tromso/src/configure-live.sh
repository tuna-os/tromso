#!/usr/bin/bash
# Live-environment setup for the Tromso ISO installer image.
#
# Runs inside the final Tromso container stage with:
#   --cap-add sys_admin --security-opt label=disable
#
# At this point the initramfs has already been replaced (by the Debian
# initramfs-builder stage) with a dmsquash-live capable one.  This script
# handles the runtime live-environment: user, SDDM autologin, tuna-installer
# configuration + autostart, and Flatpak pre-installation.

set -exo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── VERSION_ID ────────────────────────────────────────────────────────────────
# freedesktop-sdk based images may omit VERSION_ID from os-release; image-builder
# and bootc tooling require it.
if grep -q '^VERSION_ID=' /usr/lib/os-release 2>/dev/null; then
    sed -i 's/^VERSION_ID=.*/VERSION_ID=latest/' /usr/lib/os-release
else
    echo 'VERSION_ID=latest' >> /usr/lib/os-release
fi

# ── Live user ─────────────────────────────────────────────────────────────────
useradd --create-home --uid 1000 --user-group \
    --comment "Live User" liveuser || true
passwd --delete liveuser

# Grant liveuser access to DRM devices (needed for kwin_wayland KMS output).
usermod -aG video,render liveuser

# Restore setuid on sudo — BST artifact assembly strips special permission bits.
chmod u+s /usr/bin/sudo

# Debug builds only: enable SSH so the live session is reachable for testing.
if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "liveuser:live" | chpasswd
    passwd --unlock root
    echo "root:root" | chpasswd

    mkdir -p /etc/systemd/system-preset
    echo "enable sshd.service" > /etc/systemd/system-preset/90-live-debug.preset
    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /usr/lib/systemd/system/sshd.service \
        /etc/systemd/system/multi-user.target.wants/sshd.service

    cat >> /etc/ssh/sshd_config << 'SSHEOF'
PermitEmptyPasswords no
PasswordAuthentication yes
PermitRootLogin yes
SSHEOF
    # Remove options not supported by this OpenSSH build (prevents sshd startup failure).
    sed -i '/GSSAPIAuthentication/d' /etc/ssh/sshd_config
    # Generate host keys (not pre-generated in image to avoid key reuse).
    ssh-keygen -A

    mkdir -p /etc/firewalld/zones
    cat > /etc/firewalld/zones/public.xml << 'FWEOF'
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <service name="ssh"/>
  <service name="mdns"/>
  <service name="dhcpv6-client"/>
</zone>
FWEOF

    cat > /usr/lib/systemd/system/debug-ssh-banner.service << 'BANNEREOF'
[Unit]
Description=Print SSH connection info to serial console
After=sshd.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '\
  IP=$(hostname -I | awk "{print \\$1}"); \
  echo ""; \
  echo "========================================"; \
  echo " DEBUG SSH READY"; \
  echo " ssh liveuser@${IP:-<no-ip>}  (password: live)"; \
  echo " ssh root@${IP:-<no-ip>}      (password: root)"; \
  echo "========================================"; \
  echo ""'
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
BANNEREOF
    systemctl enable debug-ssh-banner.service
fi

# Give liveuser passwordless sudo
echo 'liveuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/liveuser
chmod 0440 /etc/sudoers.d/liveuser

# ── Wayland platform default ──────────────────────────────────────────────────
# Force Qt applications to the Wayland backend.  Without this, Qt services
# activated via systemd --user (kded6, powerdevil, etc.) default to XCB and
# crash with "could not connect to display" when WAYLAND_DISPLAY is not in the
# systemd environment yet.
echo 'QT_QPA_PLATFORM=wayland' >> /etc/environment

# ── SDDM autologin — Wayland mode ────────────────────────────────────────────
# Use the Wayland display server path; Aurora has no Xorg.
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/live-autologin.conf << 'SDDMEOF'
[General]
DisplayServer=wayland
CompositorCommand=kwin_wayland --no-lockscreen

[Autologin]
User=liveuser
Session=plasma
Relogin=false
SDDMEOF

# ── KDE screen lock — disabled for live session ───────────────────────────────
mkdir -p /etc/xdg
cat > /etc/xdg/kscreenlockerrc << 'LOCKEOF'
[Daemon]
Autolock=false
LockOnResume=false
LOCKEOF

# ── KDE power management — no sleep in live session ──────────────────────────
cat > /etc/xdg/powermanagementprofilesrc << 'POWEREOF'
[AC][SuspendSession]
idleTime=0
suspendType=0

[Battery][SuspendSession]
idleTime=0
suspendType=0

[LowBattery][SuspendSession]
idleTime=0
suspendType=0
POWEREOF

# Mask systemd sleep/suspend targets belt-and-suspenders
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ── Disable kmscon virtual terminals ─────────────────────────────────────────
# kmsconvt@.service (installed as autovt@.service alias) opens /dev/dri/card0
# for GPU-accelerated VT rendering, which prevents kwin_wayland from claiming
# the DRM device.  On a live desktop we do not need kmscon VTs; mask it so
# regular getty handles text consoles and the DRM device stays free for kwin.
systemctl mask kmsconvt@.service

# ── /var/tmp tmpfs ────────────────────────────────────────────────────────────
cat > /usr/lib/systemd/system/var-tmp.mount << 'UNITEOF'
[Unit]
Description=Large tmpfs for /var/tmp in the live environment

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=8G,nr_inodes=1m

[Install]
WantedBy=local-fs.target
UNITEOF
systemctl enable var-tmp.mount

# ── Live-ready marker service ─────────────────────────────────────────────────
# Prints TROMSO_LIVE_READY to the serial console after display-manager.service
# (SDDM) starts.  CI boot verification greps for this token in the serial log.
cat > /usr/lib/systemd/system/live-ready.service << 'LREOF'
[Unit]
Description=Live environment ready marker
After=display-manager.service
Requires=display-manager.service

[Service]
Type=oneshot
ExecStart=/bin/echo TROMSO_LIVE_READY
StandardOutput=tty
TTYPath=/dev/ttyS0

[Install]
WantedBy=multi-user.target
LREOF
systemctl enable live-ready.service

# fisherman (tuna-installer backend) creates /var/fisherman-tmp
mkdir -p /var/fisherman-tmp

# ── Installer configuration ───────────────────────────────────────────────────
mkdir -p /etc/bootc-installer
cp "$SCRIPT_DIR/etc/bootc-installer/images.json" /etc/bootc-installer/images.json
cp "$SCRIPT_DIR/etc/bootc-installer/recipe.json" /etc/bootc-installer/recipe.json
touch /etc/bootc-installer/live-iso-mode

# ── Installer autostart ───────────────────────────────────────────────────────
# XDG autostart works on KDE Plasma; the installer launches automatically.
INSTALLER_APP_ID="org.bootcinstaller.Installer"
[[ "${INSTALLER_CHANNEL:-stable}" == "dev" ]] && INSTALLER_APP_ID="org.bootcinstaller.Installer.Devel"

mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/tuna-installer.desktop << DTEOF
[Desktop Entry]
Name=Tromso Installer
Exec=flatpak run --env=VANILLA_CUSTOM_RECIPE=/run/host/etc/bootc-installer/recipe.json ${INSTALLER_APP_ID}
Icon=tromso
Type=Application
X-KDE-autostart-phase=2
DTEOF

# Application entry for the KDE task switcher / taskbar
mkdir -p /usr/share/applications
cat > /usr/share/applications/tromso-installer.desktop << DTEOF
[Desktop Entry]
Name=Tromso Installer
Comment=Install Tromso KDE Linux to your computer
Exec=flatpak run --env=VANILLA_CUSTOM_RECIPE=/run/host/etc/bootc-installer/recipe.json ${INSTALLER_APP_ID}
Icon=tromso
Type=Application
Categories=System;
NoDisplay=false
DTEOF

# ── Polkit rules for live installer ──────────────────────────────────────────
INSTALLER_APP_DIR=$(find /var/lib/flatpak/app/${INSTALLER_APP_ID} -name fisherman -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || true)
if [ -n "$INSTALLER_APP_DIR" ]; then
    mkdir -p /usr/local/bin
    ln -sf "${INSTALLER_APP_DIR}/fisherman" /usr/local/bin/fisherman
fi

mkdir -p /usr/share/polkit-1/actions
cat > /usr/share/polkit-1/actions/org.bootcinstaller.Installer.policy << 'POLICYEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
  "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="org.tunaos.Installer.install">
    <description>Install an operating system to disk</description>
    <message>Authentication is required to install an operating system</message>
    <icon_name>drive-harddisk</icon_name>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>yes</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/fisherman</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
  </action>
</policyconfig>
POLICYEOF

mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/99-live-installer.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id === "org.freedesktop.policykit.exec" ||
         action.id === "org.tunaos.Installer.install") &&
            subject.user === "liveuser" && subject.local) {
        return polkit.Result.YES;
    }
});
EOF

# ── VFS containers-storage ────────────────────────────────────────────────────
cat > /etc/containers/storage.conf << 'STOREOF'
[storage]
driver = "vfs"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"
STOREOF

# ── Live network defaults ─────────────────────────────────────────────────────
mkdir -p /usr/lib/tmpfiles.d
echo 'f /etc/hostname 0644 - - - tromso-live' > /usr/lib/tmpfiles.d/live-hostname.conf
