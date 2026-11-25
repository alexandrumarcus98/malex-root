# malex-root — cross-project tasks. `make help` lists them.
# workspace-root — cross-project tasks. `make help` lists them.
SHELL := /bin/bash
.DEFAULT_GOAL := help

-include Makefile.local

REPOS          := malex-dashboard malex-tech muuvies
GITHUB_USER    ?= your-github-username
APP_PROD_DIR   ?=
WATCHDOG       ?=
SITE_URL       ?=
APP_HEALTH_URL ?=

.PHONY: help status fetch pull clone check check-site check-dashboard test-muuvies vps health deploys

help: ## Show this list of commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

status: ## Branch and uncommitted changes for malex-root and every sibling project
	@for r in . $(REPOS); do \
		name=$$r; [ "$$r" = . ] && name=malex-root; \
		name=$$r; [ "$$r" = . ] && name=workspace-root; \
		if [ -d "$$r/.git" ]; then printf '\n== %s\n' "$$name"; git -C "$$r" status -sb; \
		else printf '\n== %s (not cloned, run make clone GITHUB_USER=...)\n' "$$name"; fi; \
	done

fetch: ## git fetch every project (no merges)
	@for r in $(REPOS); do [ -d "$$r/.git" ] && { echo "== $$r"; git -C "$$r" fetch --prune; }; done; true

pull: ## Fast-forward every clean project; skips ones with uncommitted changes
	@for r in $(REPOS); do \
		[ -d "$$r/.git" ] || continue; \
		if [ -n "$$(git -C "$$r" status --porcelain)" ]; then echo "== $$r: skipped (uncommitted changes)"; \
		else echo "== $$r"; git -C "$$r" pull --ff-only; fi; \
	done

clone: ## Clone missing sibling projects (uses github.com/$(GITHUB_USER)/<repo>)
	@for r in $(REPOS); do [ -d "$$r" ] || git clone "git@github.com:$(GITHUB_USER)/$$r.git" "$$r"; done

check-site: ## Typecheck and build malex-tech
	cd malex-tech && pnpm check && pnpm build

check-dashboard: ## Typecheck and test malex-dashboard
	cd malex-dashboard && pnpm typecheck && pnpm test

test-muuvies: ## Typecheck/build frontend, run pytest, and validate Compose for muuvies
	cd muuvies && (cd frontend && pnpm typecheck && pnpm build) && .venv/bin/pytest -q && docker compose config --quiet

check: check-site check-dashboard test-muuvies ## Run every project's checks

vps: ## Local container status (plus optional WATCHDOG script from Makefile.local)
	@docker ps --format '{{.Names}}\t{{.Status}}'
	@if [ -n "$(WATCHDOG)" ] && [ -x "$(WATCHDOG)" ]; then echo; "$(WATCHDOG)" --status; fi

health: ## Check optional SITE_URL and APP_HEALTH_URL configured in Makefile.local
	@if [ -z "$(SITE_URL)" ] && [ -z "$(APP_HEALTH_URL)" ]; then \
		echo "Set SITE_URL and/or APP_HEALTH_URL in Makefile.local to run health checks."; \
	else \
		if [ -n "$(SITE_URL)" ]; then curl -fsS -o /dev/null -w 'site   %{http_code}\n' "$(SITE_URL)"; fi; \
		if [ -n "$(APP_HEALTH_URL)" ]; then curl -fsS -w '\n' "$(APP_HEALTH_URL)" | sed 's/^/app    /'; fi; \
	fi

deploys: ## Show app deploy history when APP_PROD_DIR is set in Makefile.local
	@if [ -n "$(APP_PROD_DIR)" ] && [ -x "$(APP_PROD_DIR)/scripts/deploy.sh" ]; then \
		"$(APP_PROD_DIR)/scripts/deploy.sh" --status; \
	else \
		echo "Set APP_PROD_DIR in Makefile.local to view production deploy history."; \
	fi
