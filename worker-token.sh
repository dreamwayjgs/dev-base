#!/usr/bin/env bash
# Renew the long-lived Claude OAuth token used by headless cron (see WORKER.md step 2).
# Usage: ./worker-token.sh   (bash only; Windows: follow WORKER.md by hand)
set -euo pipefail

dir="$HOME/.claude-worker"
file="$dir/oauth-token"
[ -d "$dir" ] || { echo "no $dir — set up the worker folder first (WORKER.md)" >&2; exit 1; }

CLAUDE_CONFIG_DIR="$dir" claude setup-token

echo
read -rsp "Paste the token printed above (input hidden): " token
echo
[ -n "$token" ] || { echo "empty token, nothing written" >&2; exit 1; }

(umask 077; printf '%s\n' "$token" > "$file.new")
mv "$file.new" "$file"
chmod 600 "$file"

if CLAUDE_CONFIG_DIR="$dir" CLAUDE_CODE_OAUTH_TOKEN="$token" \
    claude -p --model claude-haiku-5-5 "Reply OK" >/dev/null; then
  echo "token OK, saved to $file"
else
  echo "token saved to $file but the check call failed" >&2
  exit 1
fi

echo
echo "local.md 에 업데이트해주세요: Claude 워커 cron 토큰 $(date +%F) 발급, 약 1년 유효"
