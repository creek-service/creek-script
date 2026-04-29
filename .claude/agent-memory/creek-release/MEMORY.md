# Creek Release Agent Memory

## Critical: Always Track Progress

**ALWAYS** create and maintain a progress tracking file at `.claude/agent-memory/creek-release/<release-version-number>/progress.md` for every release.

Start tracking from the very beginning - including pre-release steps like:
- Dependabot checks
- Security vulnerability checks
- Demo repo verification
- Version verification

Update the progress file as each step completes, so work can be resumed if interrupted.

## Release Progress File Format

Structure the progress file to include:
- Pre-release checks status
- Core repos release status (in dependency order)
- Post-release steps status
- Timestamps for key milestones
- Any blockers or issues encountered

## "Set Next Version" Workflow - Critical Notes

### part field must be `Patch` (capital P)
The `part` field must be `Patch` (capital P), NOT `patch` (lowercase). Using lowercase will fail:
```
gh workflow run "Set next version" --repo creek-service/<REPO> --field part=Patch
```

### Expected 409 Build Failures After Release
When running "Set next version" AFTER a release (post-release snapshot bump):
- The workflow creates a `v0.4.5-alpha` tag on the same commit as `v0.4.4`
- This triggers a Build on the alpha tag
- axion-release computes version `0.4.4` at the alpha tag commit (alpha marks START of next cycle)
- The Build tries to republish `0.4.4` artifacts → HTTP 409 Conflict (already published)
- **This is EXPECTED behavior** — not a real failure
- The `v0.4.5-alpha` tag is correctly created; future commits will use `0.4.5-SNAPSHOT`
- Template repos (multi-module-template, single-module-template) don't publish to GitHub Packages so their Builds succeed cleanly

## Demo Repo Post-Release Update Pattern

### Existing PRs Approach
Before releasing, a WIP snapshot PR is created for each demo repo. After release, update that PR:

1. **Files to change in each demo repo PR branch:**
   - `build.gradle.kts`: `creekVersion = "X.Y.Z-SNAPSHOT"` → `"X.Y.Z"`
   - `buildSrc/build.gradle.kts`: `creek-system-test-gradle-plugin:X.Y.Z-SNAPSHOT` → `X.Y.Z`; remove `mavenLocal()` + snapshot maven repo
   - `buildSrc/src/main/kotlin/common-convention.gradle.kts`: remove `mavenLocal()` + TODO comment + snapshot maven repo block
   - `buildSrc/src/main/kotlin/coverage-convention.gradle.kts` (if modified in PR): same removals

2. **After pushing changes:**
   - Update PR title: remove "WIP: " prefix, change version to release
   - Update PR body to reflect the release
   - `gh pr ready <PR#> --repo creek-service/<repo>` to mark out of draft
   - Wait for builds to pass
   - `gh pr merge <PR#> --repo creek-service/<repo> --squash --admin` (repos use squash-only, no merge commits)

### Demo Repos (names ending -demo + aggregate-template)
- basic-kafka-streams-demo
- ks-aggregate-api-demo
- ks-connected-services-demo
- wip-state-stores-demo
- aggregate-template

### Template Repos (treated as core for "Set Next Version" but creekVersion updated separately)
- multi-module-template: uses `set("creekVersion", ...)` pattern
- single-module-template: uses `val creekVersion = ...` pattern
- Both use axion-release for their OWN versioning → run "Set next version" on them

### Merge Method
Repos use squash-only (no merge commits). Always use `--squash` flag:
```
gh pr merge <PR#> --repo creek-service/<repo> --squash --admin
```
Admin flag is needed to bypass approval requirements when builds are green.

## Docs Site (creek-service.github.io)

- Announcement posts go in `_posts/YYYY-MM-DD-vX.Y.Z-released.md`
- Homepage version reference is in `_pages/home.md` — update both the label text and the URL
- Most recent posts format follows Jekyll front matter with categories: releases
- The docs site commit directly to main (no PRs needed)

