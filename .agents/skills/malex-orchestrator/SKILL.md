---
name: malex-orchestrator
description: Multi-repo orchestration playbook for workspace sibling repositories using plan-execute handoffs, run_workflow parallel fan-out, and swarm workers across malex-tech, malex-dashboard, and muuvies. Use whenever a task spans multiple repositories, delegates to parallel agents/verifiers, or coordinates cross-repo contracts.
---

# Multi-Repo Orchestrator Playbook

Use this playbook when coordinating cross-repository tasks from the workspace root. Read `CLAUDE.local.md` (if present) for host-specific overrides and endpoints before planning production changes.

## 1. Plan-Execute & Workspace Rules
- **Investigate read-only first, then execute:** In Planning Mode, inspect files and cross-repo contracts read-only, then exit planning with explicit file paths, verification commands, and a re-plan trigger list.
- **Sibling repos are independent git repositories (`.gitignore`d by the workspace root):**
  - Never launch a branched or shared worktree (`workspace:"branch"` / `workspace:"share"`) from the workspace root expecting sibling directories to be cloned (`malex-tech`, `malex-dashboard`, and `muuvies` are ignored by root git).
  - Use `workspace:"inherit"` with **disjoint per-repo/per-file ownership**, or set `Cwd` directly inside a single child repository when working there.
- **Guardrails:** Never push `main`, commit changes, or recreate production containers without running repository checks and getting explicit user confirmation. Never run `docker compose up` in a dev checkout sharing a project name with live prod; never print or commit secrets.

## 2. Cross-Repo Contracts (Check Before Changing)
- **Reverse Proxy & Headers:** Keep response headers, CSP rules, and `/static/*` caching behavior aligned between application builds and any external reverse-proxy config (e.g., Caddy). Recreate containers on single-file bind mounts when mounted configs change.
- **Runtime `.env` Parity:** When adding or renaming variables in `.env.example` or `wrangler.example.jsonc`, document safe defaults and align local runtime `.env` / `wrangler.jsonc` files separately.
- **Monitoring Producer / Ingest Schema:** Keep telemetry JSON snapshot keys, Cloudflare Access service-token audience settings (`CF_ACCESS_AUD` vs `CF_INGEST_ACCESS_AUD`), and ingest `Authorization: Bearer` tokens synchronized between external probes and `malex-dashboard/src/ingest.ts`.
- **Public-Repo Redaction:** Always verify public repositories (`gitleaks` + grep) before committing so no private domains, IPs, internal host paths, or credentials leak.

## 3. `run_workflow` & `swarm` Patterns
- **Parallel cross-repo audit or verify (`run_workflow`):**
  ```python
  phase("Cross-repo checks")
  repos = ["malex-tech", "malex-dashboard", "muuvies"]
  reports = await parallel(repos, lambda r: agent(
      f"Inspect {r} for <goal>. Do not edit files or print secrets. Return findings only.",
      schema={"type": "string"},
      role=f"Audit {r}",
      workspace="inherit",
  ))
  for r, out in zip(repos, reports):
      log(f"[{r}] {out}")
  ```
- **Author + Independent Verifier (`swarm`):**
  - Give each author disjoint file/repo ownership (`workspace:"inherit"`), leave `model` unset unless explicitly overridden, and pair changes with a read-only `verifier` worker that executes tests/builds and inspects diffs before reporting completion.

## 4. Verification Matrix
- **Workspace-wide:** `make check`
- **`malex-tech`:** `cd malex-tech && pnpm check && pnpm build` (plus Playwright desktop dark/light + mobile `390x844` verification for layout/CSS/theme changes)
- **`malex-dashboard`:** `cd malex-dashboard && pnpm typecheck && pnpm test`
- **`muuvies`:**
  ```bash
  cd muuvies
  (cd frontend && pnpm typecheck && pnpm build)
  .venv/bin/pytest -q
  docker compose config --quiet
  ```

## 5. Review Gate Before Push
- Independent review / verification reports zero high-severity findings.
- Relevant `make check` / repo checks pass after the final edit.
- Secret & privacy scan (`gitleaks` + targeted `grep`) passes cleanly.
- Explicit user confirmation received before committing or pushing `main`.
