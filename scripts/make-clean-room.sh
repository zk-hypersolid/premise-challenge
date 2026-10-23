#!/bin/sh
# Make a copy of a git repo with agent instructions, docs and decision records
# removed, so a cold-start agent cannot read them even by accident.
# Usage: make-clean-room.sh <repo> <out-dir> [ref] [extra-path-to-remove ...]
set -eu

[ $# -ge 2 ] || { echo "usage: $0 <repo> <out-dir> [ref] [extra-path ...]" >&2; exit 2; }
repo="$1"; out="$2"; ref="${3:-HEAD}"
[ $# -ge 3 ] && shift 3 || shift $#

top=$(cd "$repo" && git rev-parse --show-toplevel) || { echo "refuse: $repo is not a git repository" >&2; exit 1; }
repo=$(cd "$top" && pwd -P)
base=$(git -C "$repo" rev-parse --verify "$ref^{commit}") || { echo "refuse: unknown ref $ref" >&2; exit 1; }

[ -e "$out" ] && { echo "refuse: $out exists" >&2; exit 1; }
for p in "$@"; do
  case "$p" in
    /*|*..*) echo "refuse: extra path must be relative and must not contain '..': $p" >&2; exit 1 ;;
  esac
done
parent=$(dirname "$out")
[ -d "$parent" ] || { echo "refuse: parent directory $parent does not exist" >&2; exit 1; }
case "$(cd "$parent" && pwd -P)/" in
  "$repo"/*) echo "refuse: out-dir must be outside the repository" >&2; exit 1 ;;
esac
mkdir "$out"
out=$(cd "$out" && pwd -P)

git -C "$repo" archive --format=tar "$base" | tar -x -C "$out"
cd "$out"

# Agent instruction files at any depth (files or symlinks), case-insensitive.
find . \( -iname CLAUDE.md -o -iname CLAUDE.local.md -o -iname AGENTS.md -o -iname GEMINI.md \
  -o -iname .cursorrules -o -iname .windsurfrules -o -iname .clinerules \
  -o -ipath '*/.github/copilot-instructions.md' -o -ipath '*/.github/instructions/*.instructions.md' \) ! -type d -exec rm -f {} +
find . -type d \( -iname .claude -o -iname .codex -o -iname .cursor -o -iname .windsurf -o -iname .clinerules \) -prune -exec rm -rf {} +
# Documentation, RFCs, ADRs and decision records at any depth; doc/ and design/
# only at the root, since nested ones are often source code.
find . -type d \( -iname docs -o -iname adr -o -iname adrs -o -iname decisions -o -iname rfcs \) -prune -exec rm -rf {} +
find . -mindepth 1 -maxdepth 1 -type d \( -iname doc -o -iname design \) -exec rm -rf {} +
for p in "$@"; do rm -rf "./$p"; done

echo "clean room: $out"
echo "base: $base"
echo "files left: $(find . -type f | wc -l | tr -d ' ')"
left=$( {
  find . \( -iname CLAUDE.md -o -iname CLAUDE.local.md -o -iname AGENTS.md -o -iname GEMINI.md \
    -o -iname .cursorrules -o -iname .windsurfrules -o -iname .clinerules \
    -o -ipath '*/.github/copilot-instructions.md' -o -ipath '*/.github/instructions/*.instructions.md' \
    -o -iname .claude -o -iname .codex -o -iname .cursor -o -iname .windsurf \
    -o -iname docs -o -iname adr -o -iname adrs -o -iname decisions -o -iname rfcs \)
  find . -mindepth 1 -maxdepth 1 \( -iname doc -o -iname design \)
} | head -5)
if [ -z "$left" ]; then
  echo "check: none of the listed names are left; review the tree yourself for other decision context"
else
  echo "check FAILED:"; echo "$left"; exit 1
fi
