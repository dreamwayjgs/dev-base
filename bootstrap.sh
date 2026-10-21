#!/usr/bin/env bash
# Clone missing child repos listed in repos.txt; existing ones are left untouched.
# Usage: ./bootstrap.sh [name...]   (no names = every repo in repos.txt)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
grep -v '^#' repos.txt | while read -r name origin upstream; do
  [ -n "$name" ] || continue
  if [ $# -gt 0 ] && [[ " $* " != *" $name "* ]]; then continue; fi
  if [ -d "$name/.git" ]; then echo "skip $name (exists)"; continue; fi
  git clone "$origin" "$name"
  [ -z "${upstream:-}" ] || git -C "$name" remote add upstream "$upstream"
done
