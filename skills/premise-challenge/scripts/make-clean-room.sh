#!/bin/sh
# Make a copy of a git repo with agent instructions, docs and decision records
# removed, so a cold-start agent cannot read them even by accident.
# Usage: make-clean-room.sh <repo> <out-dir> [ref] [extra-path-to-remove ...]
#
# Extra paths are relative to the repository root. Every symbolic link left in
# the copy must resolve to an existing path inside the copy; otherwise the
# script fails. On any failure after the output directory is created, the
# script removes that directory, so a partial copy is never left for use.
set -eu

[ $# -ge 2 ] || { echo "usage: $0 <repo> <out-dir> [ref] [extra-path ...]" >&2; exit 2; }
repo="$1"; out="$2"; ref="${3:-HEAD}"
[ $# -ge 3 ] && shift 3 || shift $#

top=$(cd "$repo" && git rev-parse --show-toplevel) || { echo "refuse: $repo is not a git repository" >&2; exit 1; }
repo=$(cd "$top" && pwd -P)
base=$(git -C "$repo" rev-parse --verify "$ref^{commit}") || { echo "refuse: unknown ref $ref" >&2; exit 1; }

[ -e "$out" ] || [ -L "$out" ] && { echo "refuse: $out exists" >&2; exit 1; }
for p in "$@"; do
  case "$p" in
    ""|/*|*/|*//*) echo "refuse: extra path must be a relative path without empty parts or a trailing '/': '$p'" >&2; exit 1 ;;
  esac
  rest="$p"
  while :; do
    case "$rest" in */*) part="${rest%%/*}"; rest="${rest#*/}" ;; *) part="$rest"; rest="" ;; esac
    case "$part" in .|..) echo "refuse: extra path must not contain '.' or '..' parts: $p" >&2; exit 1 ;; esac
    [ -n "$rest" ] || break
  done
done
parent=$(dirname "$out")
[ -d "$parent" ] || { echo "refuse: parent directory $parent does not exist" >&2; exit 1; }
case "$(cd "$parent" && pwd -P)/" in
  "$repo"/*) echo "refuse: out-dir must be outside the repository" >&2; exit 1 ;;
esac

created=""; tmp=""
cleanup() {
  status=$?
  [ -n "$tmp" ] && rm -f "$tmp"
  if [ "$status" -ne 0 ] && [ -n "$created" ]; then
    cd /
    rm -rf "$created"
    echo "removed the incomplete clean room $created; do not use it" >&2
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

mkdir "$out"
out=$(cd "$out" && pwd -P)
created="$out"

# Write the archive to a file first, so a failing git archive cannot hide
# behind a successful tar.
tmp=$(mktemp "${TMPDIR:-/tmp}/clean-room.XXXXXX")
git -C "$repo" archive --format=tar -o "$tmp" "$base" || { echo "failed: git archive exited with an error" >&2; exit 1; }
tar -x -f "$tmp" -C "$out" || { echo "failed: tar could not extract the archive" >&2; exit 1; }
rm -f "$tmp"; tmp=""
cd "$out"

# Check every extra path before deleting anything: each part before the last
# must be a real directory, not a symbolic link, so a deletion cannot leave
# the clean room. A symbolic link as the last part is removed as a link.
for p in "$@"; do
  cur="."; rest="$p"
  while :; do
    case "$rest" in */*) part="${rest%%/*}"; rest="${rest#*/}" ;; *) part="$rest"; rest="" ;; esac
    cur="$cur/$part"
    [ -n "$rest" ] || break
    if [ -L "$cur" ]; then
      echo "refuse: extra path $p goes through the symbolic link ${cur#./}" >&2; exit 1
    fi
    [ -d "$cur" ] || break
  done
done

# Agent instruction files at any depth (files or symlinks), case-insensitive.
find . \( -iname CLAUDE.md -o -iname CLAUDE.local.md -o -iname AGENTS.md -o -iname GEMINI.md \
  -o -iname .cursorrules -o -iname .windsurfrules -o -iname .clinerules \
  -o -ipath '*/.github/copilot-instructions.md' -o -ipath '*/.github/instructions/*.instructions.md' \) ! -type d -exec rm -f {} +
find . \( -type d -o -type l \) \( -iname .claude -o -iname .codex -o -iname .cursor -o -iname .windsurf -o -iname .clinerules \) -prune -exec rm -rf {} +
# Documentation, RFCs, ADRs and decision records at any depth; doc/ and design/
# only at the root, since nested ones are often source code. A symbolic link
# with one of these names is removed as a link.
find . \( -type d -o -type l \) \( -iname docs -o -iname adr -o -iname adrs -o -iname decisions -o -iname rfcs \) -prune -exec rm -rf {} +
find . -mindepth 1 -maxdepth 1 \( -type d -o -type l \) \( -iname doc -o -iname design \) -exec rm -rf {} +
for p in "$@"; do rm -rf "./$p"; done

# Every symbolic link left must resolve, through any chain of links, to an
# existing path inside the clean room. External, dangling and looping links
# fail the run.
bad=$(find . -type l -exec sh -c '
  root=$1; shift
  for l do
    p=$l; n=0; ok=1
    while [ -L "$p" ]; do
      n=$((n + 1))
      if [ "$n" -gt 40 ]; then ok=0; break; fi
      t=$(readlink "$p") || { ok=0; break; }
      case $t in /*) p=$t ;; *) p=$(dirname "$p")/$t ;; esac
    done
    if [ "$ok" = 1 ] && [ -e "$p" ]; then
      if [ -d "$p" ]; then
        r=$(cd "$p" 2>/dev/null && pwd -P) || r=""
      else
        r=$(cd "$(dirname "$p")" 2>/dev/null && pwd -P) && r=$r/$(basename "$p") || r=""
      fi
      case "$r/" in "$root"/*) continue ;; esac
    fi
    printf "%s\n" "$l"
  done' sh "$out" {} +)
if [ -n "$bad" ]; then
  echo "check FAILED: these symbolic links point outside the clean room, to nothing, or into a loop:" >&2
  printf '%s\n' "$bad" | head -20 >&2
  echo "pass them as extra paths to remove them, then run again" >&2
  exit 1
fi

left=$( {
  find . \( -iname CLAUDE.md -o -iname CLAUDE.local.md -o -iname AGENTS.md -o -iname GEMINI.md \
    -o -iname .cursorrules -o -iname .windsurfrules -o -iname .clinerules \
    -o -ipath '*/.github/copilot-instructions.md' -o -ipath '*/.github/instructions/*.instructions.md' \
    -o -iname .claude -o -iname .codex -o -iname .cursor -o -iname .windsurf \
    -o -iname docs -o -iname adr -o -iname adrs -o -iname decisions -o -iname rfcs \)
  find . -mindepth 1 -maxdepth 1 \( -iname doc -o -iname design \)
} | head -5)
if [ -n "$left" ]; then
  echo "check FAILED: these listed names are still present:" >&2; echo "$left" >&2; exit 1
fi

echo "clean room: $out"
echo "base: $base"
echo "files left: $(find . -type f | wc -l | tr -d ' ')"
echo "symbolic links left: $(find . -type l | wc -l | tr -d ' '), all inside the clean room"
echo "check: none of the listed names are left; review the tree yourself for other decision context"
