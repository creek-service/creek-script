# Gradle 9 — Category 5: Kotlin Daemon OOM in CodeQL `analyze` ✅ COMPLETED

**Completed:** 2026-04-19 — Fix applied to all 4 PR branches.

**Fix applied:** Added `kotlin.daemon.jvmargs=-Xmx2g` to `gradle.properties` on the
`dependabot/gradle/gradle-wrapper-9.4.1` branch of each affected repo.

---

## Affected PRs (4 repos)

| Repo | PR |
|------|----|
| `creek-observability` | #444 |
| `creek-json-schema` | #566 |
| `creek-release-test` | #407 |
| `single-module-template` | #375 |

## Error

```
Execution failed for task ':buildSrc:compileKotlin'.
> A failure occurred while executing ...GradleKotlinCompilerWorkAction
   > Not enough memory to run compilation. Try to increase it via 'gradle.properties':
       kotlin.daemon.jvmargs=-Xmx<size>

Caused by: java.lang.OutOfMemoryError: GC overhead limit exceeded
    at org.jetbrains.kotlin.codegen.signature.JvmSignatureWriter.makeJvmMethodSignature(...)
```

Failing job: `analyze (java)` (CodeQL) only.
`build_linux` and `build_windows` pass on all affected repos.

## Root Cause

Gradle 9.4.1 generates significantly more Kotlin DSL accessor classes during `buildSrc`
configuration than Gradle 8.x. The Kotlin compiler daemon exhausts its default JVM heap
(`GC overhead limit exceeded`) while compiling the generated accessors in
`:buildSrc:compileKotlin` under the CodeQL runner environment.

The failure is specific to CodeQL because:
- CodeQL wraps the build with its own analysis tracing, increasing memory pressure
- Regular CI runners (`build_linux`) have more available memory or different JVM defaults

## Fix

**Important:** `buildSrc` is a separate isolated Gradle build — it does **not** inherit
the root project's `gradle.properties`. The setting must go in `buildSrc/gradle.properties`.

Created `buildSrc/gradle.properties` in each affected repo with:

```properties
# Increase Kotlin daemon heap to avoid OOM during buildSrc compilation with Gradle 9
kotlin.daemon.jvmargs=-Xmx2g
```

Also removed the incorrect `kotlin.daemon.jvmargs` that was mistakenly added to the root
`gradle.properties` in the first fix attempt.

This should also be applied to `main` branches across all Creek repos as a proactive
measure, since any repo upgrading to Gradle 9 in future will hit the same issue.
