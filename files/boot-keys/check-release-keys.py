#!/usr/bin/env python3
"""Reject public development signing identities in release build inputs."""

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

KEY_TYPES = 'PK PK_MIC KEK KEK_MIC DB VENDOR MODULES SYSEXT'.split()
REQUIRED = [f'SECURE_BOOT_{key}_{kind}' for key in KEY_TYPES for kind in ('KEY', 'CRT')]
REQUIRED += ['SECURE_BOOT_TPM_PCR_KEY', 'SECURE_BOOT_FSTAB_TPM_PCR_KEY',
             'SECURE_BOOT_DISTRIBUTION_KEY']
CERTIFICATE = re.compile(rb'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', re.S)


def public_keys(data):
    """Compare public keys, also catching reissued certs and PEM formatting changes."""
    blocks = CERTIFICATE.findall(data)
    if not blocks:
        raise ValueError('invalid or empty PEM certificate')
    keys = []
    for block in blocks:
        result = subprocess.run(['openssl', 'x509', '-pubkey', '-noout'], input=block,
                                capture_output=True, check=True)
        keys.append(result.stdout)
    return keys


def check(directory, release, mode):
    if mode not in ('', 'import', 'local', 'snakeoil'):
        raise ValueError('unknown IMPORT_MODE')
    if release and mode in ('snakeoil', 'local'):
        raise ValueError(f'IMPORT_MODE={mode} uses public snakeoil keys; development only')
    if mode == 'import':
        missing = [name for name in REQUIRED if not os.environ.get(name, '').strip()]
        if missing:
            raise ValueError('missing import variables: ' + ', '.join(missing))
    if not release:
        return

    reference = directory / 'snakeoil'
    known = set()
    for key in KEY_TYPES:
        known.update(public_keys((reference / f'SECURE_BOOT_{key}_CRT').read_bytes()))
    candidates = [(name, value.encode()) for name, value in os.environ.items()
                  if name.startswith('SECURE_BOOT_') and name.endswith('_CRT')]
    # Include bundles (e.g. modules/linux-module-cert.crt) and extra-db/extra-kek.
    candidates += [(str(path), path.read_bytes()) for path in directory.rglob('*.crt')
                   if reference not in path.parents]
    for name, data in candidates:
        if known.intersection(public_keys(data)):
            raise ValueError(f'{name}: public snakeoil signing identity; development only')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', action='store_true',
                        help='check inputs for any published image/ISO (including nightly)')
    parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parent)
    args = parser.parse_args()
    try:
        check(args.directory, args.release or os.environ.get('RELEASE_BUILD') == '1',
              os.environ.get('IMPORT_MODE', ''))
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        # Never log certificate/key contents, including openssl stderr.
        detail = str(error) if isinstance(error, ValueError) else 'cannot read or parse signing certificates'
        print(f'Secure Boot key guard: {detail}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
