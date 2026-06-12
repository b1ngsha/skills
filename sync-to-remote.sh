#!/usr/bin/env bash
# Sync local skills to a remote machine.
#
# Usage:
#   ./sync-to-remote.sh                          # use REMOTE env or sync-remote.conf
#   ./sync-to-remote.sh user@192.168.101.71       # explicit host
#   ./sync-to-remote.sh 192.168.101.71           # host only (uses SSH_USER or $USER)
#   ./sync-to-remote.sh lab                        # named profile from sync-remote.conf
#   REMOTE=user@host ./sync-to-remote.sh         # env var
#   SSH_PASSWORD='xxx' ./sync-to-remote.sh host  # non-interactive password
#   SSH_KEY=~/.ssh/id_ed25519 ./sync-to-remote.sh host
#
# Config (first found wins for defaults):
#   ./sync-remote.conf
#   ~/.config/skills-sync/sync-remote.conf
#
# Config format:
#   REMOTE=user@192.168.101.71    # default target
#   SSH_USER=user                 # used when host has no user@
#   [lab]                         # named profile
#   host=user@192.168.101.71
#
# Syncs:
#   1. This skills repo          -> ~/Documents/code/skills
#   2. ~/.cursor/skills-cursor   -> ~/.cursor/skills-cursor
#   3. Extra agent skills        -> ~/.agents/skills/
#   4. Extra codex skills        -> ~/.codex/skills/
#   5. Runs install.sh on remote to create symlinks

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RSYNC_OPTS=(-avz --delete --exclude '.git/' --exclude '.DS_Store')
CONFIG_DEFAULT_USER="${SSH_USER:-${USER:-}}"
CONFIG_REMOTE=""
declare -A PROFILES=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TARGET]

Sync local skills to a remote machine via rsync + install.sh.

TARGET (first match wins):
  user@host          SSH destination
  host               host only; user from SSH_USER, \$USER, or config
  profile-name       named profile from sync-remote.conf

Options:
  -c, --config PATH  Config file (default: ./sync-remote.conf or ~/.config/skills-sync/sync-remote.conf)
  -l, --list         List configured profiles and exit
  -h, --help         Show this help

Environment:
  REMOTE             Default SSH target (user@host)
  SSH_USER           Default SSH user when TARGET has no user@
  SSH_PASSWORD       Non-interactive password auth
  SSH_KEY            SSH private key path

Examples:
  $(basename "$0") lab
  $(basename "$0") user@192.168.101.230
  REMOTE=user@192.168.101.71 $(basename "$0")
EOF
}

load_config() {
  local file="$1"
  [ -f "$file" ] || return 0

  local section=""
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue

    if [[ "$line" =~ ^\[(.+)\]$ ]]; then
      section="${BASH_REMATCH[1]}"
      continue
    fi

    if [ -z "$section" ]; then
      case "$line" in
        REMOTE=*) CONFIG_REMOTE="${line#REMOTE=}" ;;
        SSH_USER=*) CONFIG_DEFAULT_USER="${line#SSH_USER=}" ;;
      esac
    else
      case "$line" in
        host=*) PROFILES["$section"]="${line#host=}" ;;
      esac
    fi
  done < "$file"
}

resolve_config_files() {
  CONFIG_FILES=()
  if [ -n "${SYNC_CONFIG:-}" ]; then
    CONFIG_FILES+=("$SYNC_CONFIG")
  elif [ -f "$REPO_DIR/sync-remote.conf" ]; then
    CONFIG_FILES+=("$REPO_DIR/sync-remote.conf")
  elif [ -f "$HOME/.config/skills-sync/sync-remote.conf" ]; then
    CONFIG_FILES+=("$HOME/.config/skills-sync/sync-remote.conf")
  fi
}

normalize_target() {
  local target="$1"
  if [[ "$target" == *@* ]]; then
    printf '%s' "$target"
  else
    local ssh_user="${CONFIG_DEFAULT_USER:-$USER}"
    [ -n "$ssh_user" ] || { echo "Cannot resolve SSH user for host: $target" >&2; exit 1; }
    printf '%s@%s' "$ssh_user" "$target"
  fi
}

resolve_remote() {
  local arg="${1:-}"

  if [ -n "$arg" ]; then
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      -l|--list)
        LIST_ONLY=1
        return 0
        ;;
      -c|--config)
        echo "Option --config requires a path argument." >&2
        exit 1
        ;;
    esac

    if [ -n "${PROFILES[$arg]+x}" ]; then
      REMOTE="${PROFILES[$arg]}"
      return 0
    fi

    REMOTE="$(normalize_target "$arg")"
    return 0
  fi

  if [ -n "${REMOTE:-}" ]; then
    REMOTE="$(normalize_target "$REMOTE")"
    return 0
  fi

  if [ -n "$CONFIG_REMOTE" ]; then
    REMOTE="$(normalize_target "$CONFIG_REMOTE")"
    return 0
  fi

  echo "No remote target configured." >&2
  echo "Set REMOTE, create sync-remote.conf, or pass user@host as an argument." >&2
  echo "Run '$(basename "$0") --help' for usage." >&2
  exit 1
}

parse_args() {
  local positional=()
  LIST_ONLY=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -l|--list)
        LIST_ONLY=1
        shift
        ;;
      -c|--config)
        [ $# -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
        SYNC_CONFIG="$2"
        shift 2
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  resolve_config_files
  for cfg in "${CONFIG_FILES[@]:-}"; do
    load_config "$cfg"
  done

  if [ "$LIST_ONLY" = "1" ]; then
    echo "Config files:"
    if [ ${#CONFIG_FILES[@]:-0} -eq 0 ]; then
      echo "  (none)"
    else
      printf '  %s\n' "${CONFIG_FILES[@]}"
    fi
    echo
    echo "Default REMOTE: ${CONFIG_REMOTE:-<unset>}"
    echo "SSH_USER: ${CONFIG_DEFAULT_USER:-<unset>}"
    echo
    echo "Profiles:"
    if [ ${#PROFILES[@]} -eq 0 ]; then
      echo "  (none)"
    else
      for name in "${!PROFILES[@]}"; do
        printf '  %-12s %s\n' "$name" "${PROFILES[$name]}"
      done | sort
    fi
    exit 0
  fi

  if [ ${#positional[@]} -gt 1 ]; then
    echo "Too many arguments: ${positional[*]}" >&2
    usage >&2
    exit 1
  fi

  resolve_remote "${positional[0]:-}"
}

ssh_cmd() {
  local remote_cmd="$1"
  if [ -n "${SSH_KEY:-}" ]; then
    ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new \
      "$REMOTE" "$remote_cmd"
  else
    expect <<EOF
set timeout 120
log_user 1
spawn ssh -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new $REMOTE $remote_cmd
expect {
  -re "(?i)password:" {
    send "$SSH_PASSWORD\r"
    exp_continue
  }
  eof
}
catch wait result
exit [lindex \$result 3]
EOF
  fi
}

rsync_to() {
  local src="$1" dst="$2"
  if [ -n "${SSH_KEY:-}" ]; then
    rsync "${RSYNC_OPTS[@]}" \
      -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new" \
      "$src" "$REMOTE:$dst"
  else
    expect <<EOF
set timeout 600
log_user 1
spawn rsync ${RSYNC_OPTS[*]} -e "ssh -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new" $src $REMOTE:$dst
expect {
  -re "(?i)password:" {
    send "$SSH_PASSWORD\r"
    exp_continue
  }
  eof
}
catch wait result
exit [lindex \$result 3]
EOF
  fi
}

parse_args "$@"

if [ -z "${SSH_PASSWORD:-}" ] && [ -z "${SSH_KEY:-}" ]; then
  printf "SSH password for %s: " "$REMOTE"
  read -rs SSH_PASSWORD
  echo
  [ -n "$SSH_PASSWORD" ] || { echo "Password required." >&2; exit 1; }
fi

echo "==> Remote: $REMOTE"
echo "==> Local repo: $REPO_DIR"
echo

echo "==> Testing SSH connection..."
ssh_cmd "echo connected && whoami && hostname"
echo

echo "==> [1/5] Ensuring remote directories..."
ssh_cmd "mkdir -p ~/Documents/code ~/.cursor ~/.agents/skills ~/.codex/skills"

echo "==> [2/5] Syncing skills repo..."
rsync_to "$REPO_DIR/" "~/Documents/code/skills/"

echo "==> [3/5] Syncing ~/.cursor/skills-cursor..."
if [ -d "$HOME/.cursor/skills-cursor" ]; then
  rsync_to "$HOME/.cursor/skills-cursor/" "~/.cursor/skills-cursor/"
else
  echo "    (skipped)"
fi

echo "==> [4/5] Syncing extra agent/codex skills..."
for skill in find-skills frontend-design simplify; do
  src="$HOME/.agents/skills/$skill"
  if [ -d "$src" ] && [ ! -L "$src" ]; then
    rsync_to "$src/" "~/.agents/skills/$skill/"
    echo "    synced agents/$skill"
  fi
done
for skill in xsparkai-design-system-review; do
  src="$HOME/.codex/skills/$skill"
  if [ -d "$src" ] && [ ! -L "$src" ]; then
    rsync_to "$src/" "~/.codex/skills/$skill/"
    echo "    synced codex/$skill"
  fi
done

echo "==> [5/5] Running install.sh on remote..."
ssh_cmd "cd ~/Documents/code/skills && chmod +x install.sh && ./install.sh && echo && echo 'cursor/skills:' && ls -1 ~/.cursor/skills/ && echo && echo 'skills-cursor:' && ls -1 ~/.cursor/skills-cursor/"

echo
echo "==> Done! Skills synced to $REMOTE"
