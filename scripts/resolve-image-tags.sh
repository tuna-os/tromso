#!/usr/bin/env bash
# scripts/resolve-image-tags.sh: Compute and validate publication image tags
# based on git ref, commit SHA, architecture channel ownership, and tag suffix.
# Enforces the publication contract: unsuffixed channel tags (:latest, :nightly,
# :stable) remain exclusive to x86_64 (channel_ownership=true).

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
  case "$1" in
    --ref)
      REF="$2"
      shift 2
      ;;
    --sha)
      SHA="$2"
      shift 2
      ;;
    --channel-owner)
      CHANNEL_OWNER="$2"
      shift 2
      ;;
    --tag-suffix)
      TAG_SUFFIX="$2"
      shift 2
      ;;
    --date)
      DATE_TAG="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$REF" || -z "$SHA" || -z "$CHANNEL_OWNER" ]]; then
  usage
fi

if [[ -z "$DATE_TAG" ]]; then
  DATE_TAG=$(date -u +%Y%m%d)
fi

if [[ "$CHANNEL_OWNER" == "true" ]]; then
  if [[ -n "$TAG_SUFFIX" ]]; then
    echo "Error: channel owner must not specify tag suffix ('$TAG_SUFFIX')" >&2
    exit 1
  fi
  if [[ "$REF" == "refs/heads/stable" ]]; then
    echo "stable stable-${DATE_TAG} ${SHA}"
  else
    echo "latest nightly nightly-${DATE_TAG} ${SHA}"
  fi
elif [[ "$CHANNEL_OWNER" == "false" ]]; then
  if [[ -z "$TAG_SUFFIX" ]]; then
    echo "Error: non-channel-owner must specify non-empty tag suffix (unsuffixed channel tags are exclusive to x86_64)" >&2
    exit 1
  fi
  if [[ "$REF" == "refs/heads/stable" ]]; then
    echo "stable${TAG_SUFFIX} stable-${DATE_TAG}${TAG_SUFFIX} ${SHA}${TAG_SUFFIX}"
  else
    echo "latest${TAG_SUFFIX} nightly${TAG_SUFFIX} nightly-${DATE_TAG}${TAG_SUFFIX} ${SHA}${TAG_SUFFIX}"
  fi
else
  echo "Error: --channel-owner must be 'true' or 'false', got '$CHANNEL_OWNER'" >&2
  exit 1
fi
