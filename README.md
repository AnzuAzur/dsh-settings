# DSH settings backup (Windows -> macOS)

A snapshot of my DeepSeek Harness configuration from
`C:\Users\hoang\.dsh`, captured **2026-10-09** and rewired so it restores onto a
Mac. Secrets are **not** in this repo — only `.example` templates.

> Setting this up on a Mac? Jump to [Restoring on macOS](#restoring-on-macos).

---

## What's in here

| Path | Restores to | What it is |
|---|---|---|
| [`dsh-home/`](dsh-home) | `~/.dsh/` | Session history, attachments, storages, and the `dshw-*` widget state files |
| [`profiles/desktop/`](profiles/desktop) | `~/.dsh/profiles/desktop/` | **The main event** — the desktop profile: local plugins registered, model + reasoning settings, the custom `compact-90` preset, tool toggles |
| [`profiles/web/`](profiles/web) | `~/.dsh/profiles/web/` | Web profile patch |
| [`profiles/headless/`](profiles/headless) | `~/.dsh/profiles/headless/` | Headless profile patch (shipped defaults) |
| [`skills/`](skills) | `~/.dsh/skills/` | The `anzu-open-app` skill |
| [`plugins/dsh-mcp-anzu-pc/`](plugins/dsh-mcp-anzu-pc) | linked from the clone | Hand-written MCP bridge bundle for the Anzu_PC DevSpace server |
| [`plugins/dsh-wallpaper-engine/`](plugins/dsh-wallpaper-engine) | linked from the clone | Wallpaper Engine plugin source (node_modules stripped) |
| [`secrets-examples/`](secrets-examples) | `~/.dsh/` | Placeholder versions of the three secret files |
| [`setup-macos.sh`](setup-macos.sh) | — | One-shot restore script that rewires the Windows paths |

`dsh-home/.dshw-*.json` are the whale-widget's persisted state (bubble text,
size, turn counter, usage history). They are cosmetic but included so the widget
comes back looking the same.

---

## The customizations worth knowing about

These live in [`profiles/desktop/cordis.patch.yml`](profiles/desktop/cordis.patch.yml)
and are the reason a plain DSH install won't feel like this one:

- **Model routing** — `deepseek-official` / `deepseek-flash` at `reasoningEffort: max`.
- **`compact-90` preset** — compaction waits until **85% of the 1M context window**
  (850,000 tokens) instead of the shipped 67.8%. The trigger is reachable because
  `llm-deepseek` caps per-request output at 100,000 tokens, freeing window for history:
  budget 900,000 → trigger 850,000 → 90,000 kept verbatim.
- **Tool-result pruner** tuned to `thresholdChars: 8192`, `headChars: 4096`, `tailChars: 1024`.
- **Subagent settings** — `spawn` and `fork` providers, both `continuable` background
  mode; the `codex`, `claude-code`, and `ralph` providers are disabled.
- **UI** — standard transcript view, detailed performance/usage readouts,
  `developerTools: true`, `allowParallelInProgress: true`.
- **Platform-aware shell** — `tool-pwsh` is disabled off Windows and `tool-bash`
  is disabled on Windows, via `!!js process.platform` expressions. Both work correctly
  on a Mac with no edits.

---

## Secrets are templated, not included

Three files in `~/.dsh` hold live credentials and are **excluded** by
[`.gitignore`](.gitignore). Placeholder copies live in `secrets-examples/`:

| Real file | Template | What it holds |
|---|---|---|
| `~/.dsh/.credentials.yaml` | `.credentials.yaml.example` | DSH browser-session secret |
| `~/.dsh/.env` | `.env.example` | `ANZU_MCP_TOKEN` for the Anzu_PC connector |
| `~/.dsh/anzu-mcp-token.json` | `anzu-mcp-token.json.example` | Rotating OAuth access/refresh token |

If a real secret ever lands in a commit, rotate it — git history keeps it forever.

---

## Restoring on macOS

### 1. Prerequisites

```bash
# Homebrew, if you don't have it: https://brew.sh
brew install node
corepack enable pnpm      # or: npm install -g pnpm

# Then install DeepSeek Harness for macOS from the official releases page.
```

`node`, `pnpm`, and the `dsh` binary itself are **not** in this repo — only my
configuration is. Install the app first.

### 2. Clone and run the restore script

```bash
git clone <this-repo> ~/dsh-settings
cd ~/dsh-settings
chmod +x setup-macos.sh
./setup-macos.sh
```

The script:

1. Moves any existing `~/.dsh` aside to `~/.dsh.pre-restore.<timestamp>`.
2. Copies `dsh-home/` contents into `~/.dsh/`.
3. Copies `profiles/*` into `~/.dsh/profiles/*`.
4. **Rewrites `package.json`** — the Windows build used absolute `link:` paths
   (`C:/Users/hoang/dsh-mcp-anzu-pc`, `D:/dsh-wallpaper-engine`). The script
   substitutes `__DSH_BACKUP_DIR__` with the real clone path so the local plugins
   resolve on macOS. The untouched originals are kept as
   `package.windows-original.json` for reference.
5. Copies the skills across.
6. Seeds the three secret files from `secrets-examples/` if absent.
7. Prints the `pnpm install` command for the next step.

### 3. Install profile dependencies

```bash
cd ~/.dsh/profiles/desktop
pnpm install
```

This links the two local plugins from the clone and pulls
`dsh-whale-widget` from `github:MeteorNOX/DeepSeek-Balance-Whale-Widget`.

### 4. Fill in the secrets

```bash
$EDITOR ~/.dsh/.env                    # paste the real ANZU_MCP_TOKEN
$EDITOR ~/.dsh/anzu-mcp-token.json     # paste the real tokens, or let the connector re-issue them
```

Better: just sign in through the app and let DSH write `~/.dsh/.credentials.yaml`
itself rather than hand-editing the placeholder.

### 5. Verify

```bash
dsh --version
dsh web
```

Then confirm the `compact-90` preset appears in the model picker and that
`~/.dsh/skills/anzu-open-app` is picked up.

---

## What won't work on macOS

Both local plugins are backed by **Windows-only** services. Committing them is
harmless — they just won't do anything useful — but you may want to drop them
from the `dsh.profile.bundles` list in
`~/.dsh/profiles/desktop/package.json` to keep startup clean.

- **`dsh-mcp-anzu-pc`** bridges to the Anzu_PC / DevSpace desktop connector at
  `http://127.0.0.1:7676/mcp`. That server controls a **Windows** PC. Without it
  running, the `mcp__anzu__*` tools simply won't appear.
- **`dsh-plugin-wallpaper-engine`** discovers Wallpaper Engine via **Steam app
  431960** on Windows. There is no macOS equivalent, so the plugin finds nothing.
- **`anzu-open-app` skill** launches `chrome.exe`, `spotify.exe`, `hoyoPlay.exe`,
  `genshinimpact.exe`, and friends. It is Windows-specific by design — the skill
  itself warns against substituting Mac apps for the Windows ones it targets.

If you want a Mac-native equivalent, the seam to reuse is the bundle pattern:
a `package.json` with a `dsh.bundle.patch` entry plus a `cordis.patch.yml` that
`insert`s rows. Copy the shape from `plugins/dsh-mcp-anzu-pc/` — it is only two
small files.

---

## Session history

`dsh-home/sessions/` holds 13 past sessions (24 MB, zstd-compressed JSONL),
keyed by the Windows working directories they ran in. They will restore and are
readable, but the paths inside them reference Windows locations, so resuming an
old session on macOS will point at directories that don't exist. Delete
`dsh-home/sessions/` before running the script if you would rather start clean.

---

## Repo hygiene notes

- No `node_modules` is committed; `pnpm install` rebuilds it.
- The desktop profile's `pnpm-lock.yaml` **is** committed, so dependency
  resolution should match the Windows install.
- `profiles/*/.plugin-manager/logs/` is ignored — those are install-time logs.
