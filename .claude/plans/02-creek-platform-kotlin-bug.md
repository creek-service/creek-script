# Plan: Fix creek-platform PR #401 Kotlin Syntax Error

## Problem

`creek-platform` PR [#401](https://github.com/creek-service/creek-platform/pull/401)
("fix: replace unmaintained coveralls Gradle plugin with coverallsapp/github-action")
has a syntax error introduced during editing of
`buildSrc/src/main/kotlin/creek-coverage-convention.gradle.kts`.

The coveralls block was only partially removed, leaving a dangling `.map{it.toString()}`
expression that causes a Kotlin compilation failure:

```kotlin
// Current broken state in PR #401:
coveralls {
    sourceDirs = allprojects.flatMap{it.sourceSets.main.get().allSource.srcDirs}
.map{it.toString()}          // ← dangling — not attached to anything
    jacocoReportPath = layout.buildDirectory.file("reports/jacoco/coverage/coverage.xml")
}
```

## Additional Problem

PR #401 is targeting **Coveralls** (`coverallsapp/github-action`) instead of **Codecov**
— the rest of the org is migrating to Codecov (see plan 01). This PR should be superseded.

## Recommended Fix

**Close PR #401** and raise a new PR that applies the correct Codecov migration
(per plan `01-coveralls-to-codecov.md`).

### New PR changes for `creek-platform`

`buildSrc/src/main/kotlin/creek-coverage-convention.gradle.kts` — the file is a
multi-module convention so the `coverage` aggregate task can be removed entirely:

```kotlin
// BEFORE (simplified):
plugins { java; jacoco; id("com.github.kt3k.coveralls") }

allprojects {
    tasks.withType<JacocoReport>().configureEach { dependsOn(tasks.test) }
}

val coverage = tasks.register<JacocoReport>("coverage") { /* aggregation */ }

coveralls { ... }
tasks.coveralls { ... }

// AFTER:
plugins { java; jacoco }

allprojects {
    tasks.withType<JacocoReport>().configureEach {
        dependsOn(tasks.test)
        reports {
            xml.required.set(true)
        }
    }
}
```

`buildSrc/build.gradle.kts`:
- Remove `coveralls-gradle-plugin` dependency line
- Remove the `configurations.all { exclude(group = "xerces") }` block

`.github/workflows/build.yml`:
- Remove Coveralls env vars from Build step
- Change `run: ./gradlew build coveralls` → `run: ./gradlew build jacocoTestReport`
- Add `codecov/codecov-action@v6.0.0` step (pinned SHA, using `CODECOV_TOKEN` secret)

`README.md`:
- Swap Coveralls badge for Codecov badge

## Why creek-platform Is High Priority

`creek-platform` is a foundational dependency consumed by most other Creek repos. Any
repo inheriting the `creek-coverage-convention.gradle.kts` plugin via platform will benefit
from this fix being applied at source, even if individual repos also need their own
`buildSrc` and workflow updates.
