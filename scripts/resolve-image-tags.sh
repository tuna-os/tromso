#!/usr/bin/env bash
# Print the image tags one final build publishes, space-separated.
#
# Enforces the channel contract (tuna-os/tromso#314): only the channel owner
# (x86_64) publishes the bare :latest, :nightly and :stable tags. Every other
# architecture must pass a single hyphen-prefixed suffix, and gets only
# suffixed tags. Called by .github/workflows/build-final.yml.

set -euo pipefail

usage() {
  echo "Usage: $0 --ref <git-ref> --sha <git-sha> --channel-owner <true|false> [--tag-suffix <suffix>] [--date <YYYYMMDD>]" >&2
  exit 1
}

REF=""
SHA=""
CHANNEL_OWNER=""
TAG_SUFFIX=""
DATE_TAG=""

while [[ $# -gt 0 ]]; do
  [[ $# -ge 2 ]] || usage
  case "$1" in
    --ref) REF="$2" ;;
    --sha) SHA="$2" ;;
    --channel-owner) CHANNEL_OWNER="$2" ;;
    --tag-suffix) TAG_SUFFIX="$2" ;;
    --date) DATE_TAG="$2" ;;
    *) usage ;;
  esac
  shift 2
done

if [[ -z "$REF" || -z "$SHA" || -z "$CHANNEL_OWNER" ]]; then
  usage
fi

if [[ -z "$DATE_TAG" ]]; then
  DATE_TAG=$(date -u +%Y%m%d)
fi

case "$CHANNEL_OWNER" in
  true)
    if [[ -n "$TAG_SUFFIX" ]]; then
      echo "Error: channel owner must not specify tag suffix ('$TAG_SUFFIX')" >&2
      exit 1
    fi
    ;;
  false)
    if [[ -z "$TAG_SUFFIX" ]]; then
      echo "Error: non-channel-owner must specify non-empty tag suffix (unsuffixed channel tags are exclusive to x86_64)" >&2
      exit 1
    fi
    if [[ ! "$TAG_SUFFIX" =~ ^-[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
      echo "Error: tag suffix must be one hyphen-prefixed OCI tag component" >&2
      exit 1
    fi
    ;;
  *)
    echo "Error: --channel-owner must be 'true' or 'false', got '$CHANNEL_OWNER'" >&2
    exit 1
    ;;
esac

# main = nightly trunk (also owns latest); stable = release bookmark.
if [[ "$REF" == "refs/heads/stable" ]]; then
  echo "stable${TAG_SUFFIX} stable-${DATE_TAG}${TAG_SUFFIX} ${SHA}${TAG_SUFFIX}"
else
  echo "latest${TAG_SUFFIX} nightly${TAG_SUFFIX} nightly-${DATE_TAG}${TAG_SUFFIX} ${SHA}${TAG_SUFFIX}"
fi
