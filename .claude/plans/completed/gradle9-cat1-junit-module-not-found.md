# Gradle 9 — Category 1: `module not found: org.junit.jupiter.engine` ✅ COMPLETED

**Completed:** 2026-04-19 — Fix applied to all 10 PR branches.

**Fix applied:** Changed `testRuntimeOnly` → `testImplementation` for `junit-jupiter-engine`
in `buildSrc/src/main/kotlin/creek-common-convention.gradle.kts` (or root `build.gradle.kts`
for single-project repos). This ensures the engine jar is on `testCompileClasspath` so
`moduleplugin 2.0.0`'s `--add-modules` directive can resolve it during `compileTestJava`.

---

## Affected PRs (10 repos)
| Repo | PR |
|------|----|
| `creek-base` | #487 |
| `creek-service` | #452 |
| `creek-platform` | #399 |
| `creek-system-test` | #675 |
| `creek-observability` | #444 |
| `creek-test` | #475 |
| `creek-json-schema` | #566 |
| `creek-release-test` | #407 |
| `multi-module-template` | #388 |
| `single-module-template` | #375 |

## Error
```
Execution failed for task ':XXX:compileTestJava'.
  error: module not found: org.junit.jupiter.engine
```

## Problem Statement
Gradle 9 changed how the JPMS module path is assembled for test compilation.
`org.junit.jupiter.engine` is declared `testRuntimeOnly` but `moduleplugin 2.0.0`
(under Gradle 9) is placing it on the module path during `compileTestJava`, where
it cannot be resolved (runtime-only deps are not available at compile time in the
module world).

Previously (Gradle 8 + moduleplugin 1.8.15) this worked because the module path
was assembled differently, or the engine jar was transitively reachable.

## Investigation Steps

1. **Reproduce locally** using `creek-base` PR #487 branch as the reference case.
   - Clone the branch and run `./gradlew :type:compileTestJava --info` to see the
     full module path Gradle 9 passes to `javac`.
   - Check whether `junit-jupiter-engine` is on the `--module-path` or `--class-path`.

2. **Check moduleplugin 2.0.0 changelog / issues**
   - Review https://github.com/java9-modularity/gradle-modules-plugin/releases/tag/2.0.0
   - Search issues for Gradle 9 + `testRuntimeOnly` + `module not found`.

3. **Check `module-info.java` in affected subprojects**
   - Do any test `module-info.java` files `requires org.junit.jupiter.engine`?
     (They shouldn't — engine is internal to JUnit, not part of the public API.)
   - If so, remove the `requires` for the engine module and only require
     `org.junit.jupiter.api`.

4. **Check `creek-module-convention.gradle.kts`**
   - Does it configure `moduleplugin` options that affect the test module path?
   - Is `java.modularity.inferModulePath` set? (currently `false`)

5. **Potential fixes to evaluate (in order of preference)**
   a. Remove `requires org.junit.jupiter.engine` from `module-info.java` test
      descriptors (if present) — engine is implementation detail.
   b. Move `junit-jupiter-engine` from `testRuntimeOnly` to `testImplementation`
      so it is available on the module path at compile time.
   c. Configure moduleplugin to exclude certain modules from the test module path,
      keeping them on the classpath instead.
   d. Add `--add-modules org.junit.jupiter.engine` to test compile args only if
      needed as a last resort.

6. **Verify fix compiles and tests pass** on the `creek-base` branch before
   rolling out to all 10 repos.

## Rollout
Once a fix is confirmed, apply to all 10 PR branches:
- The fix will likely be in `buildSrc/src/main/kotlin/creek-module-convention.gradle.kts`
  and/or individual `module-info.java` files.
- If it's a convention plugin change, push to all 10 PR branches.
- If it's per-module `module-info.java` changes, enumerate affected modules per repo.
