# malex-root
# workspace-root

Multi-repository workspace template holding independent sibling projects side by side. This root repo tracks only the shared workspace glue around them and `.gitignore`s each project directory.

| Project | Role |
|---|---|
| `malex-tech` | Developer site (Astro 6, Tailwind v4, Cloudflare Workers Static Assets) |
| `malex-dashboard` | Edge ops dashboard (Cloudflare Worker + D1 + Cron + optional Azure probe) |
| `muuvies` | Self-hosted media search, AI curator & seedbox control plane (FastAPI + React 19 + Docker Compose) |

See [CLAUDE.md](CLAUDE.md) for cross-project conventions, skill paths, and guardrails. Host-specific details belong in gitignored `CLAUDE.local.md` and `Makefile.local`.

## Commands

```bash
make help       # list all cross-repo targets
make status     # git status of workspace root and every sibling repo
make fetch      # git fetch --prune across sibling repos
make pull       # fast-forward clean sibling repos (skips dirty trees)
make check      # run build/typecheck/test checks across all repos
```

On a fresh machine, configure `GITHUB_USER` (e.g. in `Makefile.local`) and run `make clone` to check out any missing sibling repository. Optional host checks (`make vps`, `make health`, `make deploys`) read optional variables (`SITE_URL`, `APP_HEALTH_URL`, `WATCHDOG`, `APP_PROD_DIR`) from `Makefile.local`.

## Layout

```text
malex-root/          ← workspace glue (CLAUDE.md, README.md, Makefile, .gitignore, LICENSE)
workspace-root/      ← workspace glue (CLAUDE.md, README.md, Makefile, .gitignore, LICENSE)
├── malex-dashboard/ ← own repo, gitignored here
├── malex-tech/      ← own repo, gitignored here
├── muuvies/         ← own repo, gitignored here
├── CLAUDE.local.md  ← optional host overrides, gitignored
├── Makefile.local   ← optional Make variable overrides, gitignored
└── notes/           ← scratch notes, gitignored
```

## License

Workspace glue files in this repository are licensed under the [MIT License](LICENSE).
