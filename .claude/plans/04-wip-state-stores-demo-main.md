# Plan: Fix wip-state-stores-demo Broken Main Branch

## Problem

The `main` branch of
[`wip-state-stores-demo`](https://github.com/creek-service/wip-state-stores-demo)
is failing after the "Switch coverage reporting from Coveralls to Codecov" commit was
merged (#123). The `release` job fails immediately during Gradle initialisation:

```
* Where:
Initialization script '/home/runner/work/_temp/dummy-cleanup-project/init.gradle' line: 8

* What went wrong:
Cannot get the value of write-only property 'removeUnusedEntriesOlderThan' for object
of type org.gradle.api.internal.cache.DefaultCacheConfigurations$DefaultCacheResourceConfiguration.
```

## Root Cause

The init.gradle is injected by `gradle/actions/setup-gradle@v3.5.0` as part of its
cache-cleanup logic. It tries to **read** `removeUnusedEntriesOlderThan` — a property
that became **write-only** in Gradle ≥ 8.8.

`wip-state-stores-demo` main is still on **Gradle 8.4**. The PR branch used Gradle 9.4.1
(from its dependabot bump PR), which is why the PR passed but main is now failing.

There is already an open dependabot PR bumping the Gradle wrapper
(`dependabot/gradle/gradle-wrapper-9.3.1`).

## Fix Options

### Option A — Upgrade Gradle Wrapper to 9.x (Recommended)

Merge or recreate the dependabot PR that bumps the Gradle wrapper from 8.4 → 9.x.
This resolves the root cause and aligns main with the rest of the org.

Steps:
1. Check if `dependabot/gradle/gradle-wrapper-9.3.1` PR is still open and up to date.
2. If it is, rebase it and trigger a build.
3. If the build passes, merge it.
4. Alternatively, raise a manual PR: update `gradle/wrapper/gradle-wrapper.properties`
   to Gradle 9.4.1 (the version used elsewhere in the org).

### Option B — Pin gradle/actions/setup-gradle to an older version (Workaround)

```yaml
# In .github/workflows/build.yml, change:
uses: gradle/actions/setup-gradle@v3.5.0
# To an older version that doesn't inject the problematic init.gradle, e.g.:
uses: gradle/actions/setup-gradle@v3.1.0
```

This is a workaround, not a fix — Option A is preferred.

### Option C — Disable Gradle cache cleanup

```yaml
- uses: gradle/actions/setup-gradle@v3.5.0
  with:
    gradle-home-cache-cleanup: false   # already present — but the issue is in the
                                       # dummy-cleanup-project init, not the main cleanup
```

Unlikely to help since the error appears before this setting takes effect.

## Impact

Until main is fixed, **all 24 open PRs** in `wip-state-stores-demo` cannot be evaluated
or merged, as their CI also fails against the broken baseline.

## Execution Order

1. Fix main first (Option A — upgrade Gradle wrapper to 9.4.1).
2. Once main is green, rebase all open PRs and trigger rebuilds.
3. Address any remaining PR failures (likely also Coveralls-related — apply plan 01).
