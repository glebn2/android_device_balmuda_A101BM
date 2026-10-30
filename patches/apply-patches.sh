#!/bin/bash
# Apply the BALMUDA Phone patches to the LineageOS sources: <repository path>/NNNN-*.patch.
# Run from the source root:
#   device/balmuda/A101BM/patches/apply-patches.sh            apply (skips applied patches)
#   device/balmuda/A101BM/patches/apply-patches.sh --revert   revert (before repo sync)
set -e
MODE=apply
[ "$1" = "--revert" ] && { MODE=revert; shift; }
TOP=${1:-$PWD}
P=$(cd "$(dirname "$0")" && pwd)

list=$(cd "$P" && find . -name '*.patch' | sed 's|^\./||' | sort)
[ "$MODE" = revert ] && list=$(echo "$list" | sort -r)
for f in $list; do
  repo=$(dirname "$f")
  [ -d "$TOP/$repo" ] || { echo "missing $TOP/$repo, run from the source root"; exit 1; }
  if git -C "$TOP/$repo" apply --reverse --check "$P/$f" 2>/dev/null; then
    applied=1
  else
    applied=0
  fi
  if [ "$MODE" = apply ]; then
    if [ $applied = 1 ]; then echo "already applied: $f"; continue; fi
    git -C "$TOP/$repo" apply "$P/$f" || { echo "does not apply: $f"; exit 1; }
    echo "applied: $f"
  else
    if [ $applied = 0 ]; then echo "not applied: $f"; continue; fi
    git -C "$TOP/$repo" apply --reverse "$P/$f"
    echo "reverted: $f"
  fi
done
