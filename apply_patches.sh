#!/bin/bash
# apply_patches.sh — apply the noblelte patch bundle onto a freshly synced tree.
# Usage (from the bundle dir):  ./apply_patches.sh ~/los22
# Idempotent: already-applied patches are detected and skipped. Stops at the first real failure.
set -u
TOP=${1:-~/los22}
B=$(cd "$(dirname "$0")" && pwd)
export GIT_COMMITTER_NAME=${GIT_COMMITTER_NAME:-noblelte-port} GIT_COMMITTER_EMAIL=${GIT_COMMITTER_EMAIL:-port@localhost}
fail(){ echo "FAILED: $*"; echo "Fix the conflict in that project, then re-run (applied ones are skipped)."; exit 1; }
cd "$TOP" || exit 1
for d in "$B"/patches/*/; do
  path=$(cat "$d/PATH"); base=$(cat "$d/BASE")
  [ -d "$path" ] || fail "$path missing (repo sync with manifests/ first)"
  echo "== $path"
  # 1) commits (format-patch series)
  for p in "$d"/0*.patch; do
    [ -e "$p" ] || continue
    [ "$(basename "$p")" = 9999-noblelte-worktree.patch ] && continue
    subj=$(sed -n 's/^Subject: \(\[PATCH[^]]*\] \)\?//p' "$p" | head -1)
    if git -C "$path" log --format=%s "$base..HEAD" 2>/dev/null | grep -qxF "$subj"; then echo "   skip (applied) $(basename "$p")"; continue; fi
    git -C "$path" am -q --3way "$p" || { git -C "$path" am --abort; fail "$path: $(basename "$p")"; }
    echo "   am   $(basename "$p")"
  done
  # 2) working-tree changes (edits, deletions, symlinks, modes, new files, binary blobs)
  w="$d/9999-noblelte-worktree.patch"
  if [ -s "$w" ]; then
    if git -C "$path" apply --binary -R --check "$w" 2>/dev/null; then echo "   skip (applied) worktree"
    else git -C "$path" apply --binary --whitespace=nowarn "$w" || fail "$path: worktree patch"; echo "   apply worktree"; fi
  fi
done
echo "== all patches applied. Next: bash tools/audit_src.sh && bash tools/nuke_fix.sh check  (see BUILD.md)"
