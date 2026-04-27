# Copilot Instructions

## Startup

At the start of each session, read the following files for additional context before responding:

- `~/.claude/CLAUDE.md` — system-wide context (if it exists)
- `.claude/CLAUDE.md` — project-specific context

## Repository purpose

This repo contains zsh shell functions and demo project templates for managing the [Creek Service](https://github.com/creek-service) GitHub organisation.

It is not a compiled project — there are no build, test, or lint commands.

## Architecture

### zsh-functions

Shell functions installed into `~/.zshrc` via `install.sh`. Organised into three categories:

- `zsh-functions/git/` — functions that operate on local Creek repo clones (e.g. `creek_git_each`, `creek_gradle_each`, `creek_released_each`, `creek_git_diff`)
- `zsh-functions/github/` — functions that interact with GitHub via the `gh` CLI (e.g. `creek_gh_clone`, `creek_gh_clean_notifications`, `creek_gh_rebuild_prs`)
- `zsh-functions/release/` — functions for Creek release management (e.g. `creek-set-next-version`)

Each function is its own file; `install.sh` adds all of them to `fpath` and autoloads them.

### Demo projects

Three completed demo repos and a `work/` directory of in-progress demos. These are Creek Service tutorial repositories (Kafka Streams demos), not scripts.

### Claude agent configuration

- `.claude/CLAUDE.md` — persistent memory and context for Claude AI sessions
- `.claude/agents/` — custom Claude sub-agent definitions (`creek-build-inspector`, `creek-pr-manager`)
- `.claude/agent-memory/` — persistent cross-session memory for those agents

## Key conventions

### CREEK_BASE_DIR

Most `git/` functions require the `CREEK_BASE_DIR` environment variable pointing to the directory containing all local Creek repo clones (e.g. `~/dev/github.com/creek-service`). It is set in `~/.zshrc` by `install.sh`. Functions call `creek_base_dir` (a helper in `zsh-functions/git/creek_base_dir`) to resolve it and fail fast if unset.

### CREEK_EACH_EXCLUDE

Pass a space-separated list of repo names in `CREEK_EACH_EXCLUDE` to skip them when using `creek_git_each` or any function that wraps it:

```shell
CREEK_EACH_EXCLUDE="creek-script creek-service.github.io" creek_git_each git status
```

### Bulk operations against GitHub

**Always fetch the fresh repo list from GitHub** — never rely on local clones to enumerate repos:

```shell
gh repo list creek-service --limit 2000 --no-archived --json nameWithOwner --jq '.[].nameWithOwner'
```

### Repo categories

| Category | Identifying characteristic | Notes |
|---|---|---|
| Core | Does not end in `-demo` and is not a template | Uses snapshot builds; consistent `buildSrc` + workflow set |
| Demo | Name ends in `-demo`, or is `aggregate-template` | Consumes released Creek libs; different `buildSrc`/workflow set |
| Special | See list below | Exclude from bulk operations |

**Special repos** (exclude from all-repo operations): `creek-script`, `creek-service.github.io`, `creek-jekyll-theme`, `.github`, `json-schema-validation-comparison`, `demo-repository`, `single-module-template`, `multi-module-template`.

### Released repos

A repo is releasable if it has `.github/release.yml` (the release-drafter config). `creek_released_each` already handles this filter locally. `creek-set-next-version` cross-checks via GitHub by looking for `.github/workflows/release.yml`. The release dependency order (creek-test → creek-base → creek-observability / creek-json-schema → … → creek-kafka) is documented in `release/README.md` and `.claude/CLAUDE.md`.

### Scripting style

- All scripts are **zsh** (`#!/bin/zsh`), not bash.
- New functions follow the same Apache 2.0 licence header pattern as existing files.
- Each function is a single file in the appropriate `zsh-functions/<category>/` subdirectory; the filename is the function name.
- Helper functions (not intended to be called directly) are prefixed with `_creek_`.

### gh CLI

The `gh` CLI is a hard dependency. Scripts authenticate with the user's existing `gh` session and interact with the `creek-service` GitHub org.
