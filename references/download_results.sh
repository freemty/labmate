#!/bin/bash
# Download experiment results from remote GPU server
# Usage: download_results.sh --server <host> --exp <exp_id>
#
# Configure for your remote GPU setup. This is a skeleton —
# customize the remote paths for your environment.

set -euo pipefail

SERVER=""
EXP_ID=""
REMOTE_BASE="~/experiments"

while [[ $# -gt 0 ]]; do
  case $1 in
    --server) SERVER="$2"; shift 2 ;;
    --exp) EXP_ID="$2"; shift 2 ;;
    --remote-base) REMOTE_BASE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$SERVER" ] || [ -z "$EXP_ID" ]; then
  echo "Usage: download_results.sh --server <host> --exp <exp_id>"
  echo ""
  echo "Options:"
  echo "  --server       Remote server hostname or user@host"
  echo "  --exp          Experiment ID (e.g., exp01a)"
  echo "  --remote-base  Remote experiment base directory (default: ~/experiments)"
  exit 1
fi

LOCAL_DIR="exp/${EXP_ID}/results/"
REMOTE_DIR="${REMOTE_BASE}/${EXP_ID}/results/"

echo "Downloading results from ${SERVER}:${REMOTE_DIR}"
echo "  → ${LOCAL_DIR}"

mkdir -p "$LOCAL_DIR"

rsync -avz --progress \
  "${SERVER}:${REMOTE_DIR}" \
  "${LOCAL_DIR}"

echo "Download complete. Results in ${LOCAL_DIR}"
