# CLAUDE.md — Multi-Repo Workspace Guideline

This folder organizes independent sibling git repositories (`malex-tech`, `malex-dashboard`, `muuvies`) side by side. Each child repository has its own remote, `CLAUDE.md` / `README.md`, dependencies, and CI pipeline. This root repository tracks only workspace-level glue and `.gitignore`s every sibling project, so committing here never touches the child repos.

Read this file first to see which repository a task belongs in, check `CLAUDE.local.md` (if present) for host-specific overrides, and read the target project's own `CLAUDE.md` / `README.md`. Where rules overlap, **the child repository's own file wins**.

## Sibling Repositories

| Repo | What it is | Stack | Deploys how | Verify with |
|---|---|---|---|---|
| **malex-tech** | Static developer portfolio & technical notes | Astro 6, Tailwind v4, Cloudflare Workers Static Assets | Static asset upload / Workers Builds | `pnpm check && pnpm build`; Playwright desktop dark/light + mobile `390x844` |
| **malex-dashboard** | Edge ops dashboard for workers, probes, and node heartbeats | Cloudflare Worker + D1 + Cron Triggers, Cloudflare Access, optional Azure probe | Wrangler (`wrangler.example.jsonc` template) | `pnpm typecheck && pnpm test` |
| **muuvies** | Self-hosted media search, AI release assistant & seedbox control plane | Python 3.13, FastAPI, SQLite (`aiosqlite` + FTS5), React 19 + TypeScript + Vite, Docker Compose | Container build + health-checked rollout (`scripts/deploy.sh`) | `(cd frontend && pnpm typecheck && pnpm build) && .venv/bin/pytest -q && docker compose config --quiet` |

## Agent Skills Layout

Skills live under `.agents/skills/` (and `.claude/skills/`) across the workspace:
- Root orchestrator: `.agents/skills/malex-orchestrator/` (and `.agents/skills.json` registers sibling skills for tool discovery)
- `malex-tech/.agents/skills/`: `malex-frontend`, `malex-content`, `malex-deploy-ops`
- `malex-dashboard/.agents/skills/`: `dashboard-worker`, `dashboard-ui-ops`
- `muuvies/.agents/skills/`: `muuvies-backend`, `muuvies-frontend`, `muuvies-deploy-ops`, `muuvies-testing`, `seedbox-ops`

## Cross-Project Guardrails

- **Verify before pushing `main`:** Run the target repository's checks and get explicit user approval before committing or pushing in any repository (including this root workspace).
- **Isolate dev from prod Docker stacks:** Never run `docker compose up` in a dev checkout that shares a Compose project name with a live deployment on the same host; preview backend changes with `uvicorn` on an alternate port and a temporary `DATA_DIR` / `DATABASE_URL`.
- **Secrets never get committed or echoed:** Never commit or print `.env` files, `wrangler.jsonc`, SQLite databases, `.fernet_key`, SSH/WireGuard keys, `local.settings.json`, or API tokens.
- **Public repos stay sanitized:** Never place personal domains, private IPs, seedbox credentials/ports, internal host paths, or private service configurations in public repositories.
- **Host overrides belong in gitignored local files:** Keep machine-specific endpoints, paths, and prod deployment notes in `CLAUDE.local.md` and `Makefile.local`.

## Workspace Files

| Path | What it is |
|---|---|
| `Makefile` | Cross-project tasks: `status`, `fetch`, `pull`, `clone`, `check`, `vps`, `health`, `deploys` (`make help` lists all targets). Supports optional `Makefile.local` overrides. |
| `README.md` | Human-facing overview of the workspace layout and commands. |
| `CLAUDE.local.md` | Optional, gitignored host-specific operational rules and endpoints. |
| `notes/` | Gitignored scratch directory for plans and investigation notes. |
