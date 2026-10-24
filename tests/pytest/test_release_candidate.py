"""Exercise the actual candidate-selection shell with a fake GitHub API."""

import json
import os
import subprocess
from pathlib import Path

import pytest
import yaml

REPO = Path(__file__).resolve().parents[2]
SHA = 'a' * 40
DIGEST = 'sha256:' + 'b' * 64


@pytest.mark.parametrize('candidate,expected', [
    ({'sha': SHA, 'digest': DIGEST}, True),
    ({'sha': 'c' * 40, 'digest': DIGEST}, False),
    ({'sha': SHA, 'digest': 'latest'}, False),
    ({'sha': SHA}, False),
    (None, False),
])
def test_candidate_selection_rejects_invalid_evidence(tmp_path, candidate, expected):
    workflow = yaml.safe_load(
        (REPO / '.github/workflows/promote-stable.yml').read_text()
    )
    script = workflow['jobs']['candidate']['steps'][-1]['run']
    gh = tmp_path / 'gh'
    gh.write_text('''#!/bin/bash
set -eu
if [ "$2" = list ]; then
    echo "$FAKE_RUN"
else
    mkdir -p candidate
    if [ "$FAKE_CANDIDATE" = null ]; then exit 1; fi
    echo "$FAKE_CANDIDATE" > candidate/release-candidate.json
fi
''')
    gh.chmod(0o755)
    output = tmp_path / 'output'
    result = subprocess.run(
        ['bash', '-c', script], cwd=tmp_path, capture_output=True, text=True,
        env={**os.environ, 'PATH': f'{tmp_path}:{os.environ["PATH"]}',
             'FAKE_RUN': json.dumps({'databaseId': 123, 'headSha': SHA}),
             'FAKE_CANDIDATE': json.dumps(candidate),
             'GITHUB_REPOSITORY': 'tuna-os/tromso',
             'GITHUB_OUTPUT': str(output),
             'GITHUB_STEP_SUMMARY': str(tmp_path / 'summary')},
    )
    assert (result.returncode == 0) == expected, result.stderr
    if expected:
        assert output.read_text() == f'sha={SHA}\ndigest={DIGEST}\n'
    else:
        assert not output.exists()
