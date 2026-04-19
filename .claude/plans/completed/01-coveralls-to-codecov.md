# Plan: Migrate All Creek Repos from Coveralls to Codecov

## Problem

The `coveralls-gradle-plugin` v2.12.2 has not been maintained since 2021 and uses
`getDependencyProject()`, an API removed in Gradle 9. This is the **#1 blocker** across
the Creek org — the vast majority of failing PRs are failing for this reason.

## Reference Implementation

`creek-kafka` PR [#857](https://github.com/creek-service/creek-kafka/pull/857) **merged ✅** is
the canonical example. Use its diff as the template for all other repos.

## Changes Per Repo

### 1. `buildSrc/build.gradle.kts`
Remove the coveralls plugin dependency and its `xerces` exclusion workaround:
```kotlin
// REMOVE:
implementation("gradle.plugin.org.kt3k.gradle.plugin:coveralls-gradle-plugin:2.12.2")

// REMOVE the entire configurations.all block that excludes xerces:
configurations.all {
    configurations.all {
        exclude(group = "xerces", module = "xercesImpl")
    }
}
```

### 2. `buildSrc/src/main/kotlin/creek-coverage-convention.gradle.kts`
Replace multi-module Jacoco aggregation + Coveralls upload with simple per-module XML generation:
```kotlin
// REMOVE: id("com.github.kt3k.coveralls") plugin
// REMOVE: entire `coverage` JacocoReport task registration
// REMOVE: entire `coveralls { ... }` block
// REMOVE: entire `tasks.coveralls { ... }` block

// ADD: xml.required.set(true) inside existing tasks.withType<JacocoReport> block:
tasks.withType<JacocoReport>().configureEach {
    dependsOn(tasks.test)
    reports {
        xml.required.set(true)
    }
}
```

### 3. `.github/workflows/build.yml`
Replace `./gradlew build coveralls` with `./gradlew build jacocoTestReport` and add the
Codecov upload action. Remove all Coveralls environment variables:
```yaml
# REMOVE env vars: COVERALLS_REPO_TOKEN, CI_NAME, CI_JOB_ID, CI_PULL_REQUEST
# CHANGE build step run command:
run: ./gradlew build jacocoTestReport

# ADD after the build step:
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@57e3a136b779b570ffcdbf80b3bdc90e7fab3de2 # v6.0.0
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: '**/build/reports/jacoco/test/jacocoTestReport.xml'
    fail_ci_if_error: true
```

### 4. `README.md`
Replace the Coveralls badge with a Codecov badge:
```markdown
# REMOVE:
[![Coverage Status](https://coveralls.io/repos/github/creek-service/REPO/badge.svg?branch=main)](...)

# ADD:
[![codecov](https://codecov.io/gh/creek-service/REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/creek-service/REPO)
```

## Notes

- The org-wide `CODECOV_TOKEN` secret is already configured in the creek-service GitHub org.
- The Codecov app is already installed on the org.
- Codecov natively merges multiple XML reports from sub-modules — no aggregation task needed.
- For single-module repos the task is `jacocoTestReport`; for multi-module it stays the same
  (each submodule generates its own report and Codecov merges them).

## Repos Needing This Change

Any repo that still has `coveralls-gradle-plugin` in `buildSrc/build.gradle.kts`. At minimum
the repos with open "fix: replace coveralls plugin" PRs that are failing:

- `creek-platform` — open PR #401 has a syntax error; close it and raise a correct Codecov PR
- `multi-module-template` — open PR #396 ✅ already passing; merge it
- `single-module-template` — open PR, already passing; merge it
- `aggregate-template` — open PR, already passing; merge it
- All remaining repos with dependabot bumps that are failing due to the coveralls issue

## Execution Order

1. Merge already-passing "fix coveralls" PRs first (`multi-module-template`, `single-module-template`, `aggregate-template`).
2. Fix `creek-platform` (close broken PR #401, raise a correct Codecov PR) — this unblocks all repos that inherit from it.
3. Apply the change to every remaining affected repo.
