#!/usr/bin/env bash
# Renew the long-lived Claude OAuth token used by headless cron (see WORKER.md step 2).
# Usage: ./worker-token.sh [name]   (no name → oauth-token, name → oauth-token.<name>)
# bash only; Windows: follow WORKER.md by hand
set -euo pipefail

name="${1:-}"
if [ -n "$name" ] && ! [[ "$name" =~ ^[a-z0-9-]+$ ]]; then
  echo "name must match [a-z0-9-]+, got: $name" >&2; exit 1
fi

dir="$HOME/.claude-worker"
file="$dir/oauth-token${name:+.$name}"
[ -d "$dir" ] || { echo "no $dir — set up the worker folder first (WORKER.md)" >&2; exit 1; }

if [ -e "$file" ]; then
  read -rp "$file exists. Overwrite? [y/N] " ans
  [ "$ans" = y ] || [ "$ans" = Y ] || { echo "kept existing token" >&2; exit 1; }
fi
echo "target: $file (log in with the matching account in the browser)"
CLAUDE_CONFIG_DIR="$dir" claude setup-token

echo
read -rsp "Paste the token printed above (input hidden): " token
echo
[ -n "$token" ] || { echo "empty token, nothing written" >&2; exit 1; }

# Verify before replacing so a bad paste never clobbers a working token.
if ! CLAUDE_CONFIG_DIR="$dir" CLAUDE_CODE_OAUTH_TOKEN="$token" \
    claude -p --model claude-haiku-5-5 "Reply OK" >/dev/null; then
  echo "check call failed; $file left unchanged" >&2
  exit 1
fi

(umask 077; printf '%s\n' "$token" > "$file.new")
mv "$file.new" "$file"
chmod 600 "$file"
echo "token OK, saved to $file"

echo
echo "local.md 에 업데이트해주세요: Claude 워커 cron 토큰 ($(basename "$file")) $(date +%F) 발급, 약 1년 유효"
