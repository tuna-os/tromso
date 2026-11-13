"""Exercise the release guard with real certificates and make's cached targets."""

import os
from pathlib import Path
import shutil
import subprocess

import pytest

REPO = Path(__file__).resolve().parents[2]
SOURCE = REPO / 'files/boot-keys'
SCRIPT = SOURCE / 'check-release-keys.py'


@pytest.fixture
def keydir(tmp_path):
    shutil.copytree(SOURCE, tmp_path / 'keys')
    return tmp_path / 'keys'


def run_guard(keydir, *, release=True, **variables):
    env = {k: v for k, v in os.environ.items()
           if not k.startswith('SECURE_BOOT_') and k not in ('IMPORT_MODE', 'RELEASE_BUILD')}
    env.update(variables)
    command = ['python3', str(SCRIPT), '--directory', str(keydir)]
    if release:
        command.append('--release')
    return subprocess.run(command, env=env, capture_output=True, text=True)


@pytest.mark.parametrize('mode', ['snakeoil', 'local'])
def test_public_modes_are_development_only(keydir, mode):
    assert run_guard(keydir, IMPORT_MODE=mode).returncode == 1
    assert run_guard(keydir, release=False, IMPORT_MODE=mode).returncode == 0


def test_unsigned_build_needs_no_keys(keydir):
    assert run_guard(keydir).returncode == 0


@pytest.mark.parametrize('key', ['PK', 'PK_MIC', 'KEK', 'KEK_MIC', 'DB', 'VENDOR', 'MODULES', 'SYSEXT'])
def test_every_public_identity_is_rejected_when_renamed(keydir, key):
    cert = (keydir / 'snakeoil' / f'SECURE_BOOT_{key}_CRT').read_bytes()
    (keydir / 'renamed.crt').write_bytes(cert)
    assert run_guard(keydir).returncode == 1


def test_environment_certificate_cannot_bypass_mode(keydir):
    cert = (keydir / 'snakeoil/SECURE_BOOT_VENDOR_CRT').read_text()
    result = run_guard(keydir, SECURE_BOOT_OTHER_CRT=cert)
    assert result.returncode == 1
    assert cert not in result.stderr


def test_bundle_with_public_identity_is_rejected(keydir):
    certs = [p.read_bytes() for p in (keydir / 'snakeoil').glob('*_CRT')]
    (keydir / 'modules/linux-module-cert.crt').write_bytes(b'\n'.join(certs))
    assert run_guard(keydir).returncode == 1


def test_fresh_certificate_is_allowed_but_reissued_snakeoil_is_not(keydir):
    cert = keydir / 'VENDOR.crt'
    subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
                    '-subj', '/CN=release-test/', '-keyout', str(keydir / 'test.key'),
                    '-out', str(cert), '-days', '1'], check=True, capture_output=True)
    assert run_guard(keydir).returncode == 0
    subprocess.run(['openssl', 'req', '-x509', '-new', '-key',
                    str(keydir / 'snakeoil/SECURE_BOOT_VENDOR_KEY'),
                    '-subj', '/CN=different-name/', '-out', str(cert), '-days', '1'],
                   check=True, capture_output=True)
    assert run_guard(keydir).returncode == 1


def test_invalid_certificate_fails_closed(keydir):
    (keydir / 'VENDOR.crt').write_text('')
    assert run_guard(keydir).returncode == 1


def test_missing_reference_fails_closed(keydir):
    (keydir / 'snakeoil/SECURE_BOOT_DB_CRT').unlink()
    assert run_guard(keydir).returncode == 1


def test_import_is_complete_before_any_recipe_runs(keydir):
    result = subprocess.run(['make', '-j4', 'IMPORT_MODE=import', 'generate-keys'],
                            cwd=keydir, env={'PATH': os.environ['PATH']},
                            capture_output=True, text=True)
    assert result.returncode != 0
    assert 'missing import variables' in result.stderr
    assert not (keydir / 'PK.key').exists()
    assert not (keydir / 'private-key').exists()


def test_cached_target_is_checked(keydir):
    shutil.copyfile(keydir / 'snakeoil/SECURE_BOOT_DB_CRT', keydir / 'DB.crt')
    result = subprocess.run(['make', 'RELEASE_BUILD=1', 'DB.crt'], cwd=keydir,
                            env={'PATH': os.environ['PATH']}, capture_output=True, text=True)
    assert result.returncode != 0
    assert 'public snakeoil' in result.stderr


def test_complete_import_works_for_development_but_not_release(keydir):
    variables = {p.name: p.read_text() for p in (keydir / 'snakeoil').iterdir()}
    assert run_guard(keydir, release=False, IMPORT_MODE='import', **variables).returncode == 0
    assert run_guard(keydir, IMPORT_MODE='import', **variables).returncode == 1
    env = {'PATH': os.environ['PATH'], **variables}
    result = subprocess.run(['make', 'IMPORT_MODE=import', 'VENDOR.crt'], cwd=keydir,
                            env=env, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert (keydir / 'VENDOR.crt').read_text().strip() == variables['SECURE_BOOT_VENDOR_CRT'].strip()
