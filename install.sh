#!/usr/bin/env bash
# Link this repo's own skills, and point every agent at the npx skills tree.
#
# Upstream skills are owned by `npx skills` (`~/.agents/skills` and
# `~/.agents/.skill-lock.json`). This script must not replace those copies
# with a checkout under vendor/. Agent directories get a symlink to
# `~/.agents/skills/<name>`, so Cursor and Codex read the same tree Claude
# reads. Skills in this repo that npx does not own are still symlinked into
# `~/.agents/skills` from here.
#
#   ./install.sh             # (default) git pull + vendor submodules, then (re)link
#   ./install.sh update      # same as above (explicit alias)
#   ./install.sh link        # only (re)link symlinks — no network access
#   ./install.sh dry-run     # preview what would be linked (no network, no writes)
#   ./install.sh uninstall   # remove only the symlinks this repo created
#
# The git pull / submodule step only runs when this script lives in a real git
# checkout (a local clone). It is skipped automatically for remote one-liners
# and for rsync'd copies pushed by sync-to-remote.sh (they contain no .git).
# Set SKIP_UPDATE=1 to skip the network step even inside a clone.
#
# Remote one-liner (after pushing to GitHub):
#   curl -fsSL https://raw.githubusercontent.com/b1ngsha/skills/master/install.sh | bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-install}"
SKIP_UPDATE="${SKIP_UPDATE:-0}"

case "$MODE" in
  install|update|link|dry-run|uninstall) ;;
  *)
    echo "unknown mode: $MODE (use install|update|link|uninstall|dry-run)" >&2
    exit 1
    ;;
esac

# Canonical tree first. ~/.claude/skills is a symlink to it, so that pass is
# the same directory. Other agents are linked only after it exists.
CANON="$HOME/.agents/skills"
LOCK="$HOME/.agents/.skill-lock.json"
TARGETS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.cursor/skills"
  "$HOME/.codex/skills"
)

skill_in_lock() {
  local name="$1"
  [ -f "$LOCK" ] || return 1
  python3 -c 'import json,sys; sys.exit(0 if sys.argv[1] in json.load(open(sys.argv[2])).get("skills", {}) else 1)' "$name" "$LOCK"
}

is_canon_target() {
  local target="$1" canon_real target_real
  [ -d "$target" ] && [ -d "$CANON" ] || return 1
  canon_real="$(cd "$CANON" && pwd -P)"
  target_real="$(cd "$target" && pwd -P)"
  [ "$target_real" = "$canon_real" ]
}

# ---------------------------------------------------------------------------
# update_repo: bring this checkout up to date (git pull + vendor submodules).
# Linking continues even if the update fails so the current (possibly stale)
# content stays installed; UPDATE_FAILED makes the script exit non-zero at the
# end so the problem is not silently ignored.
# ---------------------------------------------------------------------------
UPDATE_FAILED=0
update_repo() {
  if [ "$SKIP_UPDATE" = "1" ]; then
    printf "[update] skipped (SKIP_UPDATE=1)\n"
    return 0
  fi

  local git_root
  if ! git_root="$(git -C "$REPO_DIR" rev-parse --show-toplevel 2>/dev/null)" || [ -z "$git_root" ]; then
    printf "[update] skipped: %s is not a git checkout (remote one-liner / synced copy?)\n" "$REPO_DIR"
    return 0
  fi

  printf "[update] repo: %s\n" "$git_root"

  # 1. Pull latest commits. --ff-only: never fabricate a merge, fail loudly instead.
  if ! git -C "$git_root" pull --ff-only 2>&1 | sed 's/^/    /'; then
    printf "WARN: git pull --ff-only failed (offline / uncommitted changes / unpushed local commits / diverged).\n" >&2
    printf "      Fix: push local commits, or run 'git pull --rebase', or commit/stash uncommitted changes.\n" >&2
    printf "      Then rerun. Use SKIP_UPDATE=1 to only relink without touching git.\n" >&2
    UPDATE_FAILED=1
  fi

  # 2. Refresh vendor submodules (Waza, kami, native-feel-skill, …)
  #    to their upstream tips. This stages the new gitlink pointers in the
  #    superproject but does not commit them.
  if ! git -C "$git_root" submodule update --recursive --remote 2>&1 | sed 's/^/    /'; then
    printf "WARN: 'git submodule update --recursive --remote' failed.\n" >&2
    printf "      Check network access to the submodule remotes and local submodule state.\n" >&2
    UPDATE_FAILED=1
  elif [ -n "$(git -C "$git_root" status --porcelain -- vendor 2>/dev/null)" ]; then
    printf "[update] vendor pointers moved. To keep the bump, commit them:\n"
    printf "        git -C %q add vendor\n" "$git_root"
    printf "        git -C %q commit -m 'chore: bump vendor skills'\n" "$git_root"
  fi

  return 0
}

if [ "$MODE" = "install" ] || [ "$MODE" = "update" ]; then
  update_repo
fi

# ---------------------------------------------------------------------------
# Discover skills:
#   1. authored:  <repo>/<skill>/SKILL.md
#   2. vendored:  any SKILL.md under <repo>/vendor/<sub>/... (submodules).
#      A per-vendor allowlist file <repo>/vendor/.allowlists/<sub> may restrict
#      which skill names get linked (one per line; lines of the form
#      "repo-dir-name=link-name" rename the link, e.g. yetone's content dir is
#      literally `skill`). Vendors without an allowlist publish every skill
#      they contain. Allowlists live outside the submodules so `git submodule
#      update` cannot clobber them.
#   Authored skills win on name collisions with vendored ones.
# ---------------------------------------------------------------------------
SKILL_DIRS=()
SKILL_NAMES=()
add_skill() {  # $1 = dir containing SKILL.md, $2 = link name
  local dir="$1" name="$2" i
  for i in "${!SKILL_NAMES[@]}"; do
    if [ "${SKILL_NAMES[$i]}" = "$name" ]; then
      printf "WARN: duplicate skill name '%s' (%s vs %s); keeping the first\n" "$name" "${SKILL_DIRS[$i]}" "$dir" >&2
      return
    fi
  done
  SKILL_DIRS+=("$dir")
  SKILL_NAMES+=("$name")
}
while IFS= read -r file; do
  dir="$(dirname "$file")"
  add_skill "$dir" "$(basename "$dir")"
done < <(find "$REPO_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)

for sub in "$REPO_DIR"/vendor/*/; do
  [ -d "$sub" ] || continue
  ALLOW=()
  allowfile="$REPO_DIR/vendor/.allowlists/$(basename "$sub")"
  if [ -f "$allowfile" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"
      [ -n "$line" ] || continue
      ALLOW+=("$line")
    done < "$allowfile"
    allowlisted=1
  else
    allowlisted=0
  fi
  while IFS= read -r file; do
    dir="$(dirname "$file")"
    name="$(basename "$dir")"
    if [ "$allowlisted" = "1" ]; then
      hit=""
      for entry in "${ALLOW[@]}"; do
        case "$entry" in
          "$name"=*) hit="${entry#*=}" ;;
          "$name")   hit="$name" ;;
        esac
      done
      [ -n "$hit" ] || continue
      name="$hit"
    fi
    add_skill "$dir" "$name"
  done < <(find "$sub" -name SKILL.md -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)
done

[ ${#SKILL_DIRS[@]} -gt 0 ] || { echo "No SKILL.md found under $REPO_DIR" >&2; exit 1; }

printf "repo:   %s\nmode:   %s\nskills: %d\n\n" "$REPO_DIR" "$MODE" "${#SKILL_DIRS[@]}"

installed_any=0
for target in "${TARGETS[@]}"; do
  parent="$(dirname "$target")"
  if [ ! -d "$parent" ]; then
    printf "[skip] %s (agent not installed)\n" "$target"
    continue
  fi
  agent="$(basename "$parent")"
  printf "[%s] %s\n" "$agent" "$target"
  if [ "$MODE" = "install" ] || [ "$MODE" = "update" ] || [ "$MODE" = "link" ]; then
    mkdir -p "$target"
  fi

  for i in "${!SKILL_DIRS[@]}"; do
    skill="${SKILL_DIRS[$i]}"
    name="${SKILL_NAMES[$i]}"
    link="$target/$name"
    # npx skills owns the bytes of a locked skill. Other agents only point at
    # that copy. This repo still symlinks skills npx does not know about.
    if is_canon_target "$target"; then
      if skill_in_lock "$name"; then
        printf "  npx      %s\n" "$name"
        continue
      fi
      dest="$skill"
    elif [ -e "$CANON/$name" ]; then
      dest="$CANON/$name"
    elif skill_in_lock "$name"; then
      printf "  npx      %s (not in %s)\n" "$name" "$CANON"
      continue
    else
      dest="$skill"
    fi

    case "$MODE" in
      install|update|link)
        if [ -L "$link" ]; then
          if [ "$(readlink "$link")" = "$dest" ]; then
            printf "  ok       %s\n" "$name"
          else
            rm "$link"
            ln -s "$dest" "$link"
            printf "  relinked %s\n" "$name"
          fi
        elif [ -e "$link" ]; then
          printf "  SKIP     %s  (exists and is not a symlink)\n" "$name" >&2
          continue
        else
          ln -s "$dest" "$link"
          printf "  linked   %s\n" "$name"
        fi
        installed_any=1
        ;;
      uninstall)
        if [ -L "$link" ] && { [ "$(readlink "$link")" = "$skill" ] || [ "$(readlink "$link")" = "$CANON/$name" ]; }; then
          rm "$link"
          printf "  removed  %s\n" "$name"
        fi
        ;;
      dry-run)
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$dest" ]; then
          printf "  ok       %s\n" "$name"
        else
          printf "  would link %s -> %s\n" "$name" "$dest"
        fi
        ;;
    esac
  done

  # Skills npx installed that this repo does not vendor (pr, retro, lark, …)
  # still need an agent symlink. Never replace a real directory.
  if ! is_canon_target "$target" && { [ "$MODE" = "install" ] || [ "$MODE" = "update" ] || [ "$MODE" = "link" ]; }; then
    for dest in "$CANON"/*; do
      [ -e "$dest" ] || continue
      name="$(basename "$dest")"
      link="$target/$name"
      # Publish real skills. Also retarget a leftover symlink when the canon
      # entry exists but has no SKILL.md, so agent dirs never point at the repo.
      if [ ! -e "$dest/SKILL.md" ] && [ ! -L "$link" ]; then
        continue
      fi
      if [ -L "$link" ]; then
        if [ "$(readlink "$link")" = "$dest" ]; then
          continue
        fi
        rm "$link"
        ln -s "$dest" "$link"
        printf "  relinked %s -> npx\n" "$name"
      elif [ -e "$link" ]; then
        printf "  SKIP     %s  (exists and is not a symlink)\n" "$name" >&2
      else
        ln -s "$dest" "$link"
        printf "  linked   %s -> npx\n" "$name"
      fi
      installed_any=1
    done
  fi
  echo
done

if { [ "$MODE" = "install" ] || [ "$MODE" = "update" ] || [ "$MODE" = "link" ]; } && [ "$installed_any" = "0" ]; then
  echo "No supported agent directories detected. Install Cursor / Codex / Claude Code first." >&2
  exit 1
fi

if [ "$UPDATE_FAILED" = "1" ]; then
  echo "Update step failed — see the WARN messages above. Fix the problem and rerun," >&2
  echo "or use SKIP_UPDATE=1 to only relink the current content." >&2
  exit 1
fi
