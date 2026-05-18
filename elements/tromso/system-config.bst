kind: script
description: >-
  System configuration required for the Aurora OCI image to boot correctly:
  - dbus.service + dbus.socket systemd units (freedesktop-sdk dbus provides
    the binary but not the systemd activation units)
  - sysusers.d entries for system accounts: messagebus (dbus), sshd, rtkit, polkitd
  - sshd.service with Type=simple (avoids sd_notify dependency)
  - systemd-networkd DHCP config for virtio-net (ens3/eth0) — REPLACED by NetworkManager
  - sysctl drop-in: disable IPv6 autoconf on non-loopback interfaces
  - unix_chkpwd setuid so KDE screen locker PAM auth works as non-root
  - KDE PAM service configs (kde, kde-fingerprint, kde-smartcard)
  - kscreenlockerrc: screen lock disabled by default (auto-lock off)

build-depends:
- kde-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- kde-build-meta.bst:freedesktop-sdk.bst:components/linux-pam.bst

variables:
  strip-binaries: ''

config:
  commands:
  # ── D-Bus systemd activation units ──────────────────────────────────
  # freedesktop-sdk's dbus component ships the daemon binary and config
  # but not the systemd .socket / .service activation units. Without these,
  # systemd-logind and any service that depends on the system bus will fail.
  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/systemd/system/dbus.socket" <<'EOF'
    [Unit]
    Description=D-Bus System Message Bus Socket
    Before=sockets.target

    [Socket]
    ListenStream=/run/dbus/system_bus_socket

    [Install]
    WantedBy=sockets.target
    EOF

  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/systemd/system/dbus.service" <<'EOF'
    [Unit]
    Description=D-Bus System Message Bus
    Documentation=man:dbus-daemon(1)
    Requires=dbus.socket
    After=dbus.socket
    # Avoid conflict with dbus-broker if it gets added later
    Conflicts=dbus-daemon.service

    [Service]
    Type=notify
    ExecStart=/usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
    ExecReload=/usr/bin/dbus-send --print-reply --system --type=method_call \
      --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig
    OOMScoreAdjust=-900

    [Install]
    Also=dbus.socket
    EOF

  # Enable dbus.socket in multi-user.target (via sockets.target preset)
  - |
    install -d "%{install-root}/usr/lib/systemd/system/sockets.target.wants"
    ln -sf ../dbus.socket "%{install-root}/usr/lib/systemd/system/sockets.target.wants/dbus.socket"

  # ── System users via sysusers.d ──────────────────────────────────────
  # These accounts are required by their respective services.  In an ostree
  # image systemd-sysusers runs at first-boot; the entries here ensure they
  # are created before the services that need them start.
  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/sysusers.d/aurora-system.conf" <<'EOF'
    # messagebus: required by dbus-daemon (runs as this user)
    u messagebus - "D-Bus Message Daemon" /run/dbus /usr/sbin/nologin

    # sshd: privilege-separation user for OpenSSH
    u sshd - "OpenSSH privilege separation user" /var/empty/sshd /usr/sbin/nologin

    # rtkit: real-time policy daemon
    u rtkit - "RealtimeKit" / /usr/sbin/nologin

    # polkitd: PolicyKit daemon
    u polkitd - "User for polkitd" /etc/polkit-1 /usr/sbin/nologin
    EOF

  # ── sshd.service ─────────────────────────────────────────────────────
  # The upstream openssh systemd service uses Type=notify which requires
  # openssh to be compiled with --with-systemd.  freedesktop-sdk's openssh
  # build does not include that flag, so we use Type=simple to avoid
  # a startup timeout that causes systemd to mark the service as failed.
  # ExecStartPre generates any missing host keys (ostree images ship no keys).
  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/systemd/system/sshd.service" <<'EOF'
    [Unit]
    Description=OpenSSH Server Daemon
    Documentation=man:sshd(8) man:sshd_config(5)
    After=network.target

    [Service]
    Type=simple
    ExecStartPre=-/usr/bin/ssh-keygen -A
    ExecStart=/usr/bin/sshd -D -e
    Restart=on-failure
    RestartSec=5s
    RuntimeDirectory=sshd
    RuntimeDirectoryMode=0755

    [Install]
    WantedBy=multi-user.target
    EOF

  # Enable sshd in multi-user.target
  - |
    install -d "%{install-root}/usr/lib/systemd/system/multi-user.target.wants"
    ln -sf ../sshd.service "%{install-root}/usr/lib/systemd/system/multi-user.target.wants/sshd.service"

  # ── ld.so.conf ───────────────────────────────────────────────────────
  # Without /etc/ld.so.conf, ldconfig ignores /etc/ld.so.conf.d/*.conf
  # and the Qt6 libs in /usr/lib/ are never registered in the linker
  # cache.  Qt6 ships in the KDE Linux parent OCI layer (not this Aurora
  # layer), so the cache must be rebuilt on the merged image at OCI
  # assembly time (see oci/tromso.bst).
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/ld.so.conf" <<'EOF'
    include /etc/ld.so.conf.d/*.conf
    EOF

  # ── sddm.service ─────────────────────────────────────────────────────
  # KDE Linux is Wayland-native; Xorg is not installed.  SDDM must use
  # Wayland mode with kwin_wayland as the greeter compositor.
  # QT_QUICK_BACKEND=software enables Mesa software rasterizer for the
  # QML greeter UI in virtualised environments (virtio-vga / llvmpipe).
  # ── sddm.service drop-in ─────────────────────────────────────────────
  - |
    install -d "%{install-root}/usr/lib/systemd/system/sddm.service.d"
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/systemd/system/sddm.service.d/debug.conf" <<'EOF'
    [Service]
    Environment=QT_QUICK_BACKEND=software
    Environment=QT_LOGGING_RULES=*.debug=true
    StandardOutput=journal+console
    StandardError=journal+console
    EOF

  # ── SDDM Wayland configuration ────────────────────────────────────────
  - |
    install -d "%{install-root}/etc/sddm.conf.d"
    install -Dm644 /dev/stdin "%{install-root}/etc/sddm.conf.d/wayland.conf" <<'EOF'
    [General]
    DisplayServer=wayland
    GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QT_QUICK_BACKEND=software

    [Wayland]
    CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1
    EOF

  # Enable SDDM as the default display manager
  - |
    install -d "%{install-root}/usr/lib/systemd/system/graphical.target.wants"
    ln -sf ../sddm.service "%{install-root}/usr/lib/systemd/system/display-manager.service"
    ln -sf ../sddm.service "%{install-root}/usr/lib/systemd/system/graphical.target.wants/sddm.service"

  # ── systemd default target ──────────────────────────────────────────
  - |
    ln -sf graphical.target "%{install-root}/usr/lib/systemd/system/default.target"

  # ── PAM sshd config ──────────────────────────────────────────────────
  # Without /etc/pam.d/sshd, sshd falls back to /etc/pam.d/other which
  # includes system-auth; system-auth has pam_deny.so in the auth stack,
  # causing all SSH password and keyboard-interactive auth to fail.
  # This explicit sshd PAM config bypasses that and uses pam_unix directly.
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/pam.d/sshd" <<'EOF'
    auth       required    pam_env.so
    auth       required    pam_unix.so shadow nullok
    account    required    pam_nologin.so
    account    required    pam_unix.so
    password   required    pam_unix.so shadow nullok
    session    required    pam_loginuid.so
    session    optional    pam_keyinit.so force revoke
    session    required    pam_unix.so
    session    optional    pam_umask.so silent
    EOF

  # ── sshd_config ──────────────────────────────────────────────────────
  # A minimal default sshd_config.  Without this sshd refuses to start.
  # PermitRootLogin is enabled for the initial Aurora image; users should
  # create a regular account and disable root SSH in production.
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/ssh/sshd_config" <<'EOF'
    # Aurora default sshd configuration
    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_ecdsa_key
    HostKey /etc/ssh/ssh_host_ed25519_key

    SyslogFacility AUTHPRIV
    AuthorizedKeysFile .ssh/authorized_keys
    PasswordAuthentication yes
    PermitRootLogin yes
    ChallengeResponseAuthentication no
    GSSAPIAuthentication no
    UsePAM yes
    X11Forwarding no
    PrintMotd no
    AcceptEnv LANG LC_*
    Subsystem sftp /usr/libexec/sftp-server
    EOF

  # ── PAM fallback configs ─────────────────────────────────────────────
  # freedesktop-sdk linux-pam ships factory defaults in
  # /usr/share/factory/etc/pam.d/ but never copies them to /etc/pam.d/.
  # Without /etc/pam.d/other (or /usr/lib/pam.d/other as fallback) every
  # service without its own PAM config fails with "Critical error - abort".
  # PAM reads /usr/lib/pam.d/ as a fallback for per-service configs.
  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/pam.d/other" <<'EOF'
    # Default PAM stack for services without their own /etc/pam.d/ entry.
    auth     include system-auth
    account  include system-auth
    password include system-auth
    session  include system-auth
    EOF

  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/pam.d/system-auth" <<'EOF'
    # Shared auth stack used by other, login, su, etc.
    -auth     [success=done authtok_err=bad perm_denied=bad maxtries=bad default=ignore] pam_systemd_home.so
    auth      sufficient pam_unix.so
    auth      required   pam_deny.so

    account   required   pam_nologin.so
    -account  [success=done authtok_expired=bad new_authtok_reqd=bad maxtries=bad acct_expired=bad default=ignore] pam_systemd_home.so
    account   required   pam_unix.so

    -password sufficient pam_systemd_home.so
    password  sufficient pam_unix.so sha512 shadow try_first_pass
    password  required   pam_deny.so

    -session  optional   pam_keyinit.so revoke
    -session  optional   pam_loginuid.so
    -session  optional   pam_systemd_home.so
    -session  optional   pam_systemd.so
    session   required   pam_unix.so
    EOF

  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/lib/pam.d/login" <<'EOF'
    # PAM config for local terminal (agetty/login) sessions.
    auth     optional   pam_faildelay.so  delay=3000000
    auth     include    system-auth
    account  required   pam_nologin.so
    account  include    system-auth
    password include    system-auth
    session  required   pam_loginuid.so
    -session optional   pam_keyinit.so force revoke
    -session optional   pam_systemd.so
    session  include    system-auth
    EOF

  # ── PAM namespace config ─────────────────────────────────────────────
  # pam_namespace.so in the systemd-user PAM stack requires this file.
  # An empty file means "no namespace bindings" which lets user@N.service
  # start cleanly.  Without it, PAM fails and all user sessions break.
  - |
    install -Dm644 /dev/stdin "%{install-root}/usr/share/pam/security/namespace.conf" <<'EOF'
    # Aurora: no PAM namespace bindings configured
    EOF

  # ── unix_chkpwd setuid ───────────────────────────────────────────────
  # pam_unix.so calls unix_chkpwd to verify passwords when running as a
  # non-root process (e.g. kscreenlocker_greet runs as the user, not root).
  # Without setuid, unix_chkpwd cannot read /etc/shadow and PAM auth fails.
  # freedesktop-sdk builds linux-pam without setuid on unix_chkpwd; this
  # overlay installs it with 4755 (setuid + rwxr-xr-x) so the screen locker
  # password prompt works correctly.
  - |
    if [ -x /usr/bin/unix_chkpwd ]; then
      install -Dm 4755 /usr/bin/unix_chkpwd "%{install-root}/usr/bin/unix_chkpwd"
    elif [ -x /usr/sbin/unix_chkpwd ]; then
      install -Dm 4755 /usr/sbin/unix_chkpwd "%{install-root}/usr/bin/unix_chkpwd"
    else
      echo "unix_chkpwd not found in /usr/bin or /usr/sbin" >&2
      exit 1
    fi

  # ── KDE PAM service configs ──────────────────────────────────────────
  # kscreenlocker_greet uses three PAM services in order: kde-fingerprint,
  # kde-smartcard, and kde (password fallback).  Without /etc/pam.d/kde
  # the screen locker falls back to /etc/pam.d/other which uses pam_deny.
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/pam.d/kde" <<'EOF'
    auth     include  system-auth
    account  include  system-auth
    password include  system-auth
    session  include  system-auth
    EOF

  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/pam.d/kde-fingerprint" <<'EOF'
    auth     [success=done ignore=ignore default=die] pam_fprintd.so
    auth     required pam_deny.so
    account  include  system-auth
    password include  system-auth
    session  include  system-auth
    EOF

  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/pam.d/kde-smartcard" <<'EOF'
    auth     [success=done ignore=ignore default=die] pam_pkcs11.so
    auth     required pam_deny.so
    account  include  system-auth
    password include  system-auth
    session  include  system-auth
    EOF

  # ── KDE screen locker default: auto-lock disabled ────────────────────
  # ── kde-settings profile activation ────────────────────────────────────
  # On Fedora, the kde-settings RPM ships /etc/xdg/plasma-workspace/env/env.sh
  # which adds /usr/share/kde-settings/kde-profile/default/xdg to XDG_CONFIG_DIRS,
  # making Plasma read the system-wide kdeglobals, kcm-about-distrorc, ksplashrc
  # etc. that aurora/common ships there.  We don't have that RPM, so we ship the
  # activation script ourselves.
  - |
    install -Dm644 /dev/stdin \
      "%{install-root}/etc/xdg/plasma-workspace/env/kde-settings.sh" <<'EOF'
    # Activate Aurora system-wide KDE defaults profile (mirrors Fedora kde-settings RPM)
    export XDG_CONFIG_DIRS=/usr/share/kde-settings/kde-profile/default/xdg${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}
    EOF

  # Ship a system-wide default kscreenlockerrc that disables the auto-lock
  # timer.  Users can override this in their own ~/.config/kscreenlockerrc.
  # Without this the screen locks after 5 minutes by default, which breaks
  # first-boot experience since unix_chkpwd requires a known password.
  - |
    install -Dm644 /dev/stdin "%{install-root}/etc/xdg/kscreenlockerrc" <<'EOF'
    [Daemon]
    Autolock=false
    LockOnResume=false
    Timeout=0
    EOF

  # ── Mask unused services ────────────────────────────────────────────
  # Masking in /usr/lib is insufficient because freedesktop-sdk layers can
  # overwrite it during OCI layer merging.
  - |
    install -d "%{install-root}/etc/systemd/system"
    # systemd-homed: Aurora does not use LUKS home dirs; fails on early D-Bus race
    ln -sf /dev/null "%{install-root}/etc/systemd/system/systemd-homed.service"
    # debug-shell: ttyS1 early root shell — only needed during development
    ln -sf /dev/null "%{install-root}/etc/systemd/system/debug-shell.service"
    # sddm-themes-workaround: recursive overlay might hide themes
    ln -sf /dev/null "%{install-root}/etc/systemd/system/usr-share-sddm-themes.mount"
    # flatpak-preinstall: requires Flatpak infrastructure not present in base image
    ln -sf /dev/null "%{install-root}/etc/systemd/system/flatpak-preinstall.service"

  # ── NetworkManager enable ────────────────────────────────────────────
  # NetworkManager is the standard network manager for Aurora (same as
  # gnome-build-meta / Dakota).  systemd-networkd is explicitly disabled
  # (as in gnome-build-meta's 80-network.preset) to avoid conflicts.
  - |
    install -d "%{install-root}/usr/lib/systemd/system/multi-user.target.wants"
    ln -sf ../NetworkManager.service \
      "%{install-root}/usr/lib/systemd/system/multi-user.target.wants/NetworkManager.service"
    # Disable systemd-networkd so it does not conflict with NetworkManager
    install -d "%{install-root}/etc/systemd/system"
    ln -sf /dev/null "%{install-root}/etc/systemd/system/systemd-networkd.service"
    ln -sf /dev/null "%{install-root}/etc/systemd/system/systemd-networkd.socket"
    ln -sf /dev/null "%{install-root}/etc/systemd/system/systemd-networkd-wait-online.service"

  # ── dconf database directories ───────────────────────────────────────
  # dconf-update.service compiles profile fragments in /etc/dconf/db/*.d/
  # into binary databases.  These directories must exist or dconf exits
  # with an error at boot.
  - |
    install -d "%{install-root}/etc/dconf/db/distro.d"
    install -d "%{install-root}/etc/dconf/db/site.d"

public:
  bst:
    split-rules:
      runtime:
        (>):
        - '%{indep-libdir}/systemd/system/dbus.socket'
        - '%{indep-libdir}/systemd/system/dbus.service'
        - '%{indep-libdir}/systemd/system/sockets.target.wants/dbus.socket'
        - '%{indep-libdir}/systemd/system/sshd.service'
        - '%{indep-libdir}/systemd/system/multi-user.target.wants/sshd.service'
        - '%{sysconfdir}/ssh/sshd_config'
        - '%{sysconfdir}/pam.d/sshd'
        - '%{indep-libdir}/sysusers.d/aurora-system.conf'
        - '%{indep-libdir}/systemd/system/multi-user.target.wants/NetworkManager.service'
        - '%{sysconfdir}/systemd/system/systemd-networkd.service'
        - '%{sysconfdir}/systemd/system/systemd-networkd.socket'
        - '%{sysconfdir}/systemd/system/systemd-networkd-wait-online.service'
        - '%{sysconfdir}/dconf/db/distro.d'
        - '%{sysconfdir}/dconf/db/site.d'
        - '%{indep-libdir}/pam.d/other'
        - '%{indep-libdir}/pam.d/system-auth'
        - '%{indep-libdir}/pam.d/login'
        - '%{datadir}/pam/security/namespace.conf'
        - '%{sysconfdir}/systemd/system/systemd-homed.service'
        - '%{sysconfdir}/systemd/system/debug-shell.service'
        - '%{sysconfdir}/systemd/system/flatpak-preinstall.service'
        - '%{sysconfdir}/ld.so.conf'
        - '%{indep-libdir}/systemd/system/sddm.service.d/debug.conf'
        - '%{sysconfdir}/sddm.conf.d/wayland.conf'
        - '%{indep-libdir}/systemd/system/display-manager.service'
        - '%{indep-libdir}/systemd/system/graphical.target.wants/sddm.service'
        - '%{indep-libdir}/systemd/system/default.target'
        - '%{bindir}/unix_chkpwd'
        - '%{sysconfdir}/pam.d/kde'
        - '%{sysconfdir}/pam.d/kde-fingerprint'
        - '%{sysconfdir}/pam.d/kde-smartcard'
        - '%{sysconfdir}/xdg/kscreenlockerrc'
        - '%{sysconfdir}/xdg/plasma-workspace/env/kde-settings.sh'
