"""Invariants for the generated BuildStream CI config (tuna-os/tromso#311).

`.github/actions/generate-bst-ci-config` writes the config that build_final
feeds to `bst --config`. The load-bearing claim is that **without CASD
credentials it reproduces the committed buildstream-ci.conf byte for byte** —
that is what makes adopting remote execution a no-op until someone obtains a
client certificate, and it is why the committed file can stay where
tuna-os/bst-ci's chunk jobs still read it.

The script runs here directly, so these are real executions rather than
assertions about text. Stdlib only: the CI pytest job installs nothing but
pytest.
"""

import os
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GENERATE = REPO / ".github" / "actions" / "generate-bst-ci-config" / "generate.sh"
COMMITTED = REPO / "buildstream-ci.conf"

CACHE_ENDPOINT = "https://cache.projectbluefin.io:11002"
ANON_ENDPOINT = "https://cache.freedesktop-sdk.io:11001"

CERT = "-----BEGIN CERTIFICATE-----\nnot-a-real-cert\n-----END CERTIFICATE-----"
KEY = "-----BEGIN PRIVATE KEY-----\nnot-a-real-key\n-----END PRIVATE KEY-----"


def run_generator(*, remote_execution="false", push="true", cert="", key=""):
    """Run generate.sh into a scratch workspace; return (returncode, config)."""
    with tempfile.TemporaryDirectory() as workspace:
        env = {
            **os.environ,
            "GITHUB_WORKSPACE": workspace,
            "ENABLE_REMOTE_EXECUTION": remote_execution,
            "ENABLE_PUSH": push,
            "CASD_CLIENT_CERT": cert,
            "CASD_CLIENT_KEY": key,
        }
        proc = subprocess.run(
            ["bash", str(GENERATE)], env=env, capture_output=True, text=True
        )
        conf = Path(workspace) / "buildstream-ci.conf"
        written = conf.read_text() if conf.exists() else None
        creds = {
            name: (Path(workspace) / name).exists()
            for name in ("client.crt", "client.key")
        }
        modes = {
            name: oct(os.stat(Path(workspace) / name).st_mode & 0o777)
            for name in creds
            if creds[name]
        }
    return proc, written, creds, modes


def test_generator_exists_and_is_executable_bash():
    assert GENERATE.is_file(), GENERATE
    assert GENERATE.read_text().startswith("#!/usr/bin/env bash")


def test_local_only_config_matches_the_committed_file_exactly():
    """The whole safety argument for this change. Any drift here means the
    nightly build stops behaving the way it does today."""
    proc, written, _, _ = run_generator()
    assert proc.returncode == 0, proc.stderr
    assert written == COMMITTED.read_text(), (
        "generated local-only config differs from the committed "
        "buildstream-ci.conf; update whichever is wrong, they must agree"
    )


def test_local_only_config_writes_no_credentials():
    _, _, creds, _ = run_generator()
    assert creds == {"client.crt": False, "client.key": False}


def test_local_only_config_names_no_remote_endpoint():
    """Belt and braces on the byte comparison: no mTLS endpoint, no executor,
    however the committed file may be edited later."""
    _, written, _, _ = run_generator()
    assert CACHE_ENDPOINT not in written
    assert "remote-execution:" not in written


def test_remote_execution_without_credentials_fails_closed():
    """A run that asked for the executor and silently got a local-only config
    would look like a slow success — the exact failure mode #311 describes."""
    proc, _, _, _ = run_generator(remote_execution="true")
    assert proc.returncode != 0
    assert "credentials are missing" in proc.stdout + proc.stderr


def test_credentials_alone_add_the_cache_but_not_the_executor():
    """Push to the mTLS cache is useful on its own, and is what the aarch64
    job asks for. It must not drag the executor in with it."""
    proc, written, creds, modes = run_generator(cert=CERT, key=KEY)
    assert proc.returncode == 0, proc.stderr
    assert creds == {"client.crt": True, "client.key": True}
    assert set(modes.values()) == {"0o600"}, modes
    for section in ("artifacts:", "source-caches:"):
        assert section in written
    assert written.count(CACHE_ENDPOINT) == 2
    assert written.count(ANON_ENDPOINT) == 2
    assert "remote-execution:" not in written


def test_remote_execution_config_has_all_three_services():
    """BuildStream needs execution, storage and action-cache; two out of three
    gives a config that loads and then builds locally anyway."""
    proc, written, _, _ = run_generator(remote_execution="true", cert=CERT, key=KEY)
    assert proc.returncode == 0, proc.stderr
    assert "remote-execution:" in written
    for service in ("execution-service:", "storage-service:", "action-cache-service:"):
        assert service in written, service
    # cache.storage-service as well as the one under remote-execution, so the
    # runner's casd is remote-backed and payloads stay off its ~100 GB disk.
    assert written.count("storage-service:") == 2
    # Container-side paths: the Justfile mounts the workspace at /src.
    assert "client-key: /src/client.key" in written
    assert "client-cert: /src/client.crt" in written


def test_remote_execution_raises_the_scheduler_counts():
    """Under remote execution the runner stops compiling, so leaving builders
    at 1 would serialise the whole graph and waste the executor."""
    _, local, _, _ = run_generator()
    _, remote, _, _ = run_generator(remote_execution="true", cert=CERT, key=KEY)
    assert "  builders: 1" in local and "  max-jobs: 0" in local
    assert "  builders: 2" in remote and "  max-jobs: 8" in remote


def test_push_can_be_disabled_without_losing_reads():
    proc, written, _, _ = run_generator(cert=CERT, key=KEY, push="false")
    assert proc.returncode == 0, proc.stderr
    assert "push: true" not in written
    assert CACHE_ENDPOINT in written


def test_workflow_wires_the_action_and_removes_the_key():
    """A leftover client.key on a runner is a credential leak; the cleanup
    step has to be unconditional."""
    workflow = (
        REPO / ".github" / "workflows" / "build-tromso-multirunner.yml"
    ).read_text()
    assert workflow.count("uses: ./.github/actions/generate-bst-ci-config") == 2
    assert workflow.count("rm -f client.key client.crt") == 2
    assert workflow.count("if: always()") >= 2


def test_workflow_fails_closed_on_a_silent_local_fallback():
    """#311: a green cache hit is not proof the executor loaded."""
    workflow = (
        REPO / ".github" / "workflows" / "build-tromso-multirunner.yml"
    ).read_text()
    assert 'grep -q "Remote Execution Configuration"' in workflow
    assert "remote execution requested but not engaged" in workflow
    # Without pipefail the grep would run on a tee'd log from a failed build
    # and the step would still report the build's exit status as 0.
    assert "set -o pipefail" in workflow
