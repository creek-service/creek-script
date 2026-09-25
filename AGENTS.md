# Agent notes

## Repository shape

- This is a zsh utility/documentation repository, not a Creek library or Gradle project. There is no package manifest, lockfile, build, test, lint, typecheck, or codegen setup; Gradle commands in the docs apply to other Creek repositories.
- Runtime code is under `zsh-functions/`: `git/` operates on local clones, `github/` uses the `gh` CLI/API, and `release/` dispatches organization workflows.
- `install.sh` autoloads every file in those directories, so a public function's filename must exactly match its zsh function name. Private helpers such as `_creek_git_diff` use the `_creek_` prefix; retain the `#!/bin/zsh` shebang and Apache header in new scripts.
- `.claude/CLAUDE.md` has the organization/repository categorization. `.agent/` contains platform-neutral agent specifications shared by `.claude/agents/` and `.opencode/agents/`; the Claude-specific agent/memory files are not OpenCode configuration, and `release/README.md` is the release source of truth.
- The demo-project inventory in `.github/copilot-instructions.md` is historical; this checkout currently has no demo or `work/` directories.

## Local setup and verification

- Activate from the repository root with `. ./install.sh`; `./install.sh` cannot load functions into the current shell. Installation appends `CREEK_BASE_DIR`, `fpath`, and autoload statements to and then sources `~/.zshrc`; rerunning it is not idempotent and can overwrite an explicitly selected base directory.
- The installer derives `CREEK_BASE_DIR` from the parent of the current `$PWD`. It must contain local Creek clones as immediate child directories; set it explicitly when running from elsewhere. The local `git/` functions fail when it is unset.
- GitHub/release functions require an authenticated `gh` CLI; repository cloning additionally requires SSH access. The README's `gh` prerequisite is `brew install gh`.
- `CREEK_EACH_EXCLUDE` is a space-separated list of child directory names and only affects the local wrappers. `creek_released_each` assigns its fixed list globally, replacing and persisting the caller's value.
- `creek_gradle_each` selects only directories containing `gradlew`. `creek_released_each` selects only directories containing `.github/release.yml` and always excludes `creek-release-test`, `multi-module-template`, and `single-module-template`.
- `creek_git_each` iterates every immediate child without verifying that it is a Git repository, joins and `eval`s its arguments, and stops at the first command failure. Pass a compound command as one quoted argument.
- For shell changes, use `zsh -n <file>` for a focused check. To check every current shell source, run `for file in install.sh doit.sh zsh-functions/*/*; do zsh -n "$file" || break; done`.

## GitHub and release operations

- Never use `CREEK_BASE_DIR` as the inventory for an organization-wide change. Fetch the current non-archived repositories with `gh repo list creek-service --limit 2000 --no-archived --json nameWithOwner --jq '.[].nameWithOwner'`; use a fresh temporary clone and clean it up when local work is required.
- For core/demo-only work, apply the special-repository policy in `.claude/CLAUDE.md` (notably `creek-script`, `creek-service.github.io`, `creek-jekyll-theme`, `.github`, `json-schema-validation-comparison`, and `demo-repository`). The module templates are handled separately in `release/README.md` and are excluded by `creek_released_each`.
- `creek_gh_clone [<output-dir>] [<excluded-names>]` uses SSH and clones every repository returned by `gh`; output defaults to `.`, exclusions are a single space-separated second argument, and the function applies no core/demo filter.
- `creek_gh_clean_notifications` examines currently unread PR notifications for the authenticated GitHub account and deletes closed ones across organizations, not only `creek-service`.
- `creek_gh_rebuild_prs` is non-read-only: it enumerates all open PRs in all fetched repositories, including drafts and special repos; it can update branches, trigger/rerun builds, poll checks, and attempt `--squash --delete-branch` merges. An empty `gh pr checks` result is treated as no failures, so run it only for an explicitly requested bulk PR operation.
- `creek-set-next-version <value>` is a GitHub-side bulk dispatcher, not a local version command. It accepts exactly one unvalidated argument, skips templates and `creek-release-test`, selects public repos with `.github/workflows/release.yml`, then dispatches each repo's `version.yml` with `part=<value>` without waiting or verifying. Current target-repo workflows distinguish capital-case `Major`, `Minor`, and `Patch` from explicit versions such as `1.2.3`; verify the target workflow because the local script does not validate casing.
- Do not use the organization-level `.github/workflows/set-next-version.yml` as executable automation: it is an incomplete scaffold with a bare `-` step. The current Dependabot workflow's major-update guard also references nonexistent step id `dependabot-metadata` while the step is named `metadata`; do not rely on it to exempt major updates.
- For releases, follow `release/README.md` rather than improvising order. In particular, `creek-kafka` waits for both `creek-system-test` and `creek-json-schema-gradle-plugin`. Obtain a core repo's version with `./gradlew -q cV` only from a clean, current `main` checkout, and do not release a dependent until the parent's release workflow, main build, and artifact publication are verified. The post-release snapshot phase explicitly includes both module templates even though `creek_released_each` excludes them.
- `doit.sh` is a one-off bulk-copy helper, not a task runner or test command. It only acts when the target convention file exists and copies it from a hard-coded local `creek-kafka` path, so inspect/parameterize that path before reuse elsewhere.
