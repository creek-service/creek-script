# Plan: Java 11 → Java 17 Migration

## Problem

Several repos have PR branches still targeting Java 11, but SNAPSHOT dependencies
in the Creek org now require JVM 17+. This causes compile/runtime failures on those PRs.

Affected repos identified from the rebuild run:
- `creek-json-schema-gradle-plugin`
- `creek-release-test`
- Potentially others with very stale branches

## Diagnosis Per Repo

Before migrating, check what Java version each affected repo's `build.yml` currently targets:
```bash
# In each repo:
grep -n "java-version" .github/workflows/build.yml
grep -n "sourceCompatibility\|targetCompatibility\|jvmTarget\|release" buildSrc/src/main/kotlin/*.gradle.kts
```

## Changes Required

### 1. `.github/workflows/build.yml`
```yaml
# CHANGE:
java-version: '11'
# TO:
java-version: '17'
```

### 2. `buildSrc/src/main/kotlin/creek-java-convention.gradle.kts` (or equivalent)
```kotlin
// CHANGE:
java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}
// TO:
java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
```

Or if using the `--release` flag:
```kotlin
// CHANGE:
options.release.set(11)
// TO:
options.release.set(17)
```

### 3. Module-info files (if present)
Check `module-info.java` files — Java 17 is backward compatible so these rarely need changes.

### 4. `README.md`
Update any Java version badges or prerequisites.

## Notes

- Java 17 is an LTS release — a safe target.
- The wider Creek org appears to have already moved to Java 17+; these are just lagging branches.
- Stale dependabot branches may also need rebasing onto main after main is updated.
- If a repo uses `creek-coverage-convention.gradle.kts` from `creek-platform`, fix
  `creek-platform` first (plan 02) before rebasing these branches.

## Execution Order

1. Confirm the main branch of each affected repo already targets Java 17 (if main was
   already migrated, the PR branches just need rebasing).
2. If main also targets Java 11, update main first via a dedicated PR, then rebase
   dependabot/feature branches.
3. Close and re-open stale dependabot PRs after rebasing, or use
   `@dependabot rebase` comment to trigger an automated rebase.
