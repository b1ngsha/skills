#!/usr/bin/env bash
# Install skills from this repo into every detected agent's skills directory.
# Uses symlinks so updates in this repo propagate to all agents instantly.
#
# Usage:
#   ./install.sh                  # install (idempotent)
#   ./install.sh uninstall        # remove only the symlinks this repo created
#   ./install.sh dry-run          # preview changes
#
# Remote one-liner (after pushing to GitHub):
#   curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/master/install.sh | bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-install}"

# Agent skill directories. Add new ones here as agents adopt the SKILL.md convention.
TARGETS=(
  "$HOME/.cursor/skills"
  "$HOME/.codex/skills"
  "$HOME/.claude/skills"
  "$HOME/.agents/skills"
)

# Discover skills: any top-level directory containing SKILL.md.
SKILLS=()
while IFS= read -r dir; do
  SKILLS+=("$dir")
done < <(find "$REPO_DIR" -maxdepth 2 -name SKILL.md -not -path "*/.git/*" -exec dirname {} \;)

[ ${#SKILLS[@]} -gt 0 ] || { echo "No SKILL.md found under $REPO_DIR" >&2; exit 1; }

printf "repo:   %s\nmode:   %s\nskills: %d\n\n" "$REPO_DIR" "$MODE" "${#SKILLS[@]}"

installed_any=0
for target in "${TARGETS[@]}"; do
  parent="$(dirname "$target")"
  if [ ! -d "$parent" ]; then
    printf "[skip] %s (agent not installed)\n" "$target"
    continue
  fi
  agent="$(basename "$parent")"
  printf "[%s] %s\n" "$agent" "$target"
  [ "$MODE" = "install" ] && mkdir -p "$target"

  for skill in "${SKILLS[@]}"; do
    name="$(basename "$skill")"
    link="$target/$name"

    case "$MODE" in
      install)
        if [ -L "$link" ]; then
          if [ "$(readlink "$link")" = "$skill" ]; then
            printf "  ok       %s\n" "$name"
          else
            rm "$link"
            ln -s "$skill" "$link"
            printf "  relinked %s\n" "$name"
          fi
        elif [ -e "$link" ]; then
          printf "  SKIP     %s  (exists and is not a symlink)\n" "$name" >&2
          continue
        else
          ln -s "$skill" "$link"
          printf "  linked   %s\n" "$name"
        fi
        installed_any=1
        ;;
      uninstall)
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$skill" ]; then
          rm "$link"
          printf "  removed  %s\n" "$name"
        fi
        ;;
      dry-run)
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$skill" ]; then
          printf "  ok       %s\n" "$name"
        else
          printf "  would link %s -> %s\n" "$name" "$skill"
        fi
        ;;
      *)
        echo "unknown mode: $MODE (use install|uninstall|dry-run)" >&2
        exit 1
        ;;
    esac
  done
  echo
done

if [ "$MODE" = "install" ] && [ "$installed_any" = "0" ]; then
  echo "No supported agent directories detected. Install Cursor / Codex / Claude Code first." >&2
  exit 1
fi
