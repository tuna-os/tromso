kind: manual
description: Uncomplicated Firewall, an iptables frontend

sources:
- kind: tar
  url: tar_https:deb.debian.org/debian/pool/main/u/ufw/ufw_0.36.2.orig.tar.gz
  ref: 2a57a99eecef6b44db3537ed2520b30bae3759f8465456e22e404cd643838bf5

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-python-setuptools.bst
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

depends:
- freedesktop-sdk.bst:components/python3.bst
- freedesktop-sdk.bst:components/iptables.bst

config:
  build-commands:
  - python3 setup.py build

  install-commands:
  - python3 setup.py install --prefix=%{prefix} --root %{install-root}
  - install -Dm755 src/ufw-init %{install-root}%{sbindir}/ufw-init
  - install -Dm644 conf/ufw.conf %{install-root}%{sysconfdir}/ufw/ufw.conf
  - install -Dm644 conf/before.rules %{install-root}%{sysconfdir}/ufw/before.rules
  - install -Dm644 conf/after.rules %{install-root}%{sysconfdir}/ufw/after.rules
  - install -Dm644 conf/before6.rules %{install-root}%{sysconfdir}/ufw/before6.rules
  - install -Dm644 conf/after6.rules %{install-root}%{sysconfdir}/ufw/after6.rules
  - |
    # setup.py hardcodes /usr/sbin and /lib; move for usrmerge
    if [ -d "%{install-root}/usr/sbin" ]; then
      find "%{install-root}/usr/sbin" -maxdepth 1 -not -type d \
        -exec mv {} "%{install-root}/usr/bin/" \;
      rmdir "%{install-root}/usr/sbin"
    fi
    if [ -d "%{install-root}/lib" ] && [ ! -L "%{install-root}/lib" ]; then
      cp -a "%{install-root}/lib/." "%{install-root}/usr/lib/"
      rm -rf "%{install-root}/lib"
    fi
