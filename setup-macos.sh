#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# dsh-settings -> macOS bootstrap
#
# Restores this DSH (DeepSeek Harness) configuration onto a Mac, rewiring the
# Windows paths that were baked into the profile package.json files.
#
# Usage:
#   cd <this repo>
#   ./setup-macos.sh              # install into ~/.dsh
#   DSH_HOME_DIR=/some/path ./setup-macos.sh
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DSH_HOME_DIR="${DSH_HOME_DIR:-$HOME/.dsh}"
PROFILE="${DSH_PROFILE:-desktop}"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

say "Repo:      $REPO_DIR"
say "DSH home:  $DSH_HOME_DIR"
say "Profile:   $PROFILE"

# --- 1. sanity -------------------------------------------------------------
[[ "$(uname -s)" == "Darwin" ]] || warn "This script targets macOS; continuing anyway."
command -v node >/dev/null 2>&1 || warn "node not found on PATH. Install Node.js before running DSH."
command -v pnpm >/dev/null 2>&1 || warn "pnpm not found on PATH. Run 'corepack enable pnpm' or 'npm i -g pnpm'."

# --- 2. back up any existing install --------------------------------------
if [[ -d "$DSH_HOME_DIR" ]]; then
  BACKUP="$DSH_HOME_DIR.pre-restore.$(date +%Y%m%d-%H%M%S)"
  say "Existing $DSH_HOME_DIR found - moving it to $BACKUP"
  mv "$DSH_HOME_DIR" "$BACKUP"
fi
mkdir -p "$DSH_HOME_DIR"

# --- 3. dsh-home: session history, storages, runtime state ----------------
if [[ -d "$REPO_DIR/dsh-home" ]]; then
  say "Restoring session history, storages, and runtime state"
  # -a keeps timestamps; trailing /. copies directory contents.
  cp -a "$REPO_DIR/dsh-home/." "$DSH_HOME_DIR/"
fi

# --- 4. skills -------------------------------------------------------------
if [[ -d "$REPO_DIR/skills" ]]; then
  say "Restoring skills"
  mkdir -p "$DSH_HOME_DIR/skills"
  cp -a "$REPO_DIR/skills/." "$DSH_HOME_DIR/skills/"
fi

# --- 5. profiles: config only, paths rewired ------------------------------
say "Restoring profiles with macOS paths"
for src in "$REPO_DIR"/profiles/*/; do
  name="$(basename "$src")"
  dest="$DSH_HOME_DIR/profiles/$name"
  mkdir -p "$dest"
  # The desktop profile's package.json holds Windows absolute link: paths.
  # When a template exists it is the source of truth, so skip both the baked
  # package.json and the reference copy, then render the template below.
  for f in "$src"*; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    case "$base" in
      package.template.json|package.windows-original.json.txt) continue ;;
      package.json) [[ -f "$src/package.template.json" ]] && continue ;;
    esac
    cp -a "$f" "$dest/"
  done
  if [[ -f "$src/package.template.json" ]]; then
    say "  rewiring $name/package.json -> $REPO_DIR/plugins/..."
    sed "s|__DSH_BACKUP_DIR__|$REPO_DIR|g" "$src/package.template.json" > "$dest/package.json"
  fi
done

# --- 6. local plugins -----------------------------------------------------
if [[ -d "$REPO_DIR/plugins" ]]; then
  say "Local plugins are linked in place from $REPO_DIR/plugins (not copied)."
fi

# --- 7. secrets -----------------------------------------------------------
say "Setting up secret files"
if [[ -f "$REPO_DIR/secrets-examples/.env.example" ]]; then
  cp -n "$REPO_DIR/secrets-examples/.env.example" "$DSH_HOME_DIR/.env"
  warn "Fill in $DSH_HOME_DIR/.env (ANZU_MCP_TOKEN) before using the Anzu_PC tools."
fi
if [[ -d "$REPO_DIR/secrets-examples" ]]; then
  for f in "$REPO_DIR"/secrets-examples/*.example; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f" .example)"
    [[ "$base" == ".env" ]] && continue
    if [[ ! -f "$DSH_HOME_DIR/$base" ]]; then
      cp "$f" "$DSH_HOME_DIR/$base"
      warn "Created placeholder $DSH_HOME_DIR/$base - replace the PASTE_* values."
    fi
  done
fi

# --- 8. dependencies ------------------------------------------------------
say "Next: install profile dependencies"
cat <<EOF

  cd "$DSH_HOME_DIR/profiles/$PROFILE"
  pnpm install          # pulls dsh-whale-widget from GitHub, links local plugins

Then start DSH and confirm:
  dsh --version
  dsh web

EOF

say "Done. Profile config restored to $DSH_HOME_DIR/profiles/$PROFILE"
