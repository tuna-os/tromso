#!/usr/bin/env python3
"""Record actual image identity and check existing GitHub qualification artifacts."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

REPO = "tuna-os/tromso"
IMAGE_REF = re.compile(r"ghcr\.io/tuna-os/tromso@sha256:[0-9a-f]{64}")
COMMIT = re.compile(r"[0-9a-f]{40}")
WORKFLOWS = {
    "iso": "build-iso.yml",
    "plain": "test-plain-install.yml",
    "luks": "test-luks-install.yml",
}


def gh(*args):
    return subprocess.check_output(["gh", *args, "--repo", REPO], text=True)


def latest_completed(runs):
    for run in runs:
        if run["status"] == "completed":
            return run
    raise ValueError("No completed run exists")


def latest(workflow):
    return latest_completed(json.loads(gh(
        "run", "list", "--workflow", workflow, "--branch", "main", "--limit", "20",
        "--json", "databaseId,conclusion,status,headSha",
    )))


def require_success(run, force):
    if run["conclusion"] != "success" and not force:
        raise ValueError(f"Run {run['databaseId']} did not succeed")


def qualification(kind, reference, workflow_sha, run_id):
    if not IMAGE_REF.fullmatch(reference):
        raise ValueError("Qualification needs a canonical immutable image reference")
    if not COMMIT.fullmatch(workflow_sha) or not run_id.isdecimal():
        raise ValueError("Qualification needs the workflow SHA and run ID")
    return {
        "schemaVersion": 1, "kind": kind, "sourceRef": reference,
        "workflowSha": workflow_sha, "runId": run_id, "success": True,
    }


def verify_qualification(document, kind, reference, run):
    expected = qualification(kind, reference, run["headSha"], str(run["databaseId"]))
    for field, value in expected.items():
        if type(document.get(field)) is not type(value) or document[field] != value:
            raise ValueError(f"{kind} qualification has an incorrect {field}")


def check(reference, force):
    for kind, workflow in WORKFLOWS.items():
        run = latest(workflow)
        require_success(run, force)
        with tempfile.TemporaryDirectory(prefix=f"tromso-{kind}-qualification-") as directory:
            gh("run", "download", str(run["databaseId"]), "--name",
               f"qualification-{kind}", "--dir", directory)
            document = json.loads((Path(directory) / "qualification.json").read_text())
        verify_qualification(document, kind, reference, run)
        print(f"{kind}: {reference} qualified by run {run['databaseId']}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    candidate = commands.add_parser("candidate")
    candidate.add_argument("--force", action="store_true")
    verify = commands.add_parser("check")
    verify.add_argument("reference")
    verify.add_argument("--force", action="store_true")
    record = commands.add_parser("record")
    record.add_argument("kind", choices=WORKFLOWS)
    record.add_argument("reference_file", type=Path)
    args = parser.parse_args()
    if args.command == "candidate":
        run = latest("build-tromso-multirunner.yml")
        require_success(run, args.force)
        if not COMMIT.fullmatch(run["headSha"]):
            raise ValueError("Build run has an invalid source SHA")
        print(run["headSha"])
    elif args.command == "check":
        check(args.reference, args.force)
    else:
        print(json.dumps(qualification(
            args.kind, args.reference_file.read_text().strip(),
            os.environ["GITHUB_SHA"], os.environ["GITHUB_RUN_ID"],
        )))


if __name__ == "__main__":
    main()
