#!/usr/bin/env bash
# Create a project from a stack overlay.
#
#   ./new.sh gin <dir>
#   ./new.sh react <dir>
#
# Official tooling creates the project. This script then copies the stack's
# coding standard and the small set of files that standard assumes.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "usage: ./new.sh gin <dir> | ./new.sh react <dir>" >&2
  exit 2
}

[ $# -eq 2 ] || usage
stack="$1"
raw_dest="$2"

case "$stack" in
  gin|react) ;;
  *) usage ;;
esac

if [ -e "$raw_dest" ]; then
  echo "destination exists: $raw_dest" >&2
  exit 1
fi

parent="$(dirname "$raw_dest")"
name="$(basename "$raw_dest")"
if [ ! -d "$parent" ]; then
  echo "parent directory does not exist: $parent" >&2
  exit 1
fi
if [[ ! "$name" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
  echo "directory name must match [A-Za-z][A-Za-z0-9_-]*: $name" >&2
  exit 1
fi

dest="$(cd "$parent" && pwd)/$name"

copy_gin_overlay() {
  mkdir -p "$dest"
  tar -C "$ROOT/stacks/gin" --exclude cmd -cf - . | tar -C "$dest" -xf -
  mkdir -p "$dest/cmd/$name"
  cp "$ROOT/stacks/gin/cmd/service/main.go" "$ROOT/stacks/gin/cmd/service/main_test.go" "$dest/cmd/$name/"
}

copy_react_overlay() {
  cp "$ROOT/stacks/react/AGENTS.md" "$ROOT/stacks/react/CODING_STANDARDS.md" "$dest/"
  mkdir -p "$dest/docs/standards" "$dest/src/routes" "$dest/src/test"
  cp "$ROOT/stacks/react/docs/standards/web-testing.md" "$dest/docs/standards/"
  cp "$ROOT/stacks/react/.oxlintrc.json" "$ROOT/stacks/react/.oxfmtrc.json" "$ROOT/stacks/react/vite.config.ts" "$dest/"
  cp "$ROOT/stacks/react/src/main.tsx" "$dest/src/main.tsx"
  cp "$ROOT/stacks/react/src/routes/__root.tsx" "$ROOT/stacks/react/src/routes/index.tsx" "$dest/src/routes/"
  cp "$ROOT/stacks/react/src/test/setup.ts" "$dest/src/test/"
  python3 - "$dest/package.json" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    pkg = json.load(f)
scripts = pkg.setdefault("scripts", {})
scripts["test"] = "vitest run"
scripts["lint"] = "oxlint --type-aware ."
scripts["format"] = "oxfmt --write ."
scripts["format:check"] = "oxfmt --check ."
with open(path, "w") as f:
    json.dump(pkg, f, indent=2)
    f.write("\n")
PY
}

if [ "$stack" = "gin" ]; then
  command -v go >/dev/null 2>&1 || { echo "go is required" >&2; exit 1; }
  mkdir -p "$dest"
  (
    cd "$dest"
    go mod init "$name"
    go get github.com/gin-gonic/gin
  )
  copy_gin_overlay
  (
    cd "$dest"
    gofmt -w .
    go test ./...
  )
  echo "created $dest"
  exit 0
fi

command -v pnpm >/dev/null 2>&1 || { echo "pnpm is required" >&2; exit 1; }
# create-vite treats an absolute path as a relative project name.
(
  cd "$(dirname "$dest")"
  pnpm create vite "$name" --template react-ts
)
(
  cd "$dest"
  pnpm add @tanstack/react-router @tanstack/react-query
  pnpm add -D @tanstack/router-plugin @tanstack/router-cli vitest jsdom \
    @testing-library/react @testing-library/jest-dom @testing-library/user-event \
    oxlint oxfmt
)
copy_react_overlay
(
  cd "$dest"
  pnpm exec tsr generate
  pnpm test
)
echo "created $dest"
