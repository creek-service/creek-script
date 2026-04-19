# Gradle 9 — Category 4: `ProjectDependency.getPath()` removed

## Affected PRs (1 repo)
| Repo | PR |
|------|----|
| `creek-kafka` (docs) | #836 |

## Error
```
A problem occurred configuring project ':client-extension'.
> Failed to notify project evaluation listener.
   > 'java.lang.String org.gradle.api.artifacts.ProjectDependency.getPath()'
```

Fails across all matrix build jobs (all Kafka versions, Linux and Windows).
Also causes `submit-dependencies` to fail.

## Problem Statement
Gradle 9 removed `ProjectDependency.getPath()` (deprecated since Gradle 8.x).
A project evaluation listener attached to `:client-extension` calls this method
during the configuration phase. Because this is a configuration-phase failure,
the project cannot even configure — all tasks fail before running.

Note: This is on the `docs-examples/gradle-wrapper-9.4.1` branch of `creek-kafka`,
a separate directory (`docs-examples/`) with its own `buildSrc` and build files,
distinct from PR #850 (main project).

Note: The earlier `getDependencyProject()` error (Category 0, now fixed by
upgrading `moduleplugin` to 2.0.0) is different — `getPath()` is a separate
removed method on `ProjectDependency`.

## Investigation Steps

1. **Find the source of the `getPath()` call** in `creek-kafka/docs-examples`:
   ```
   gh search code --repo creek-service/creek-kafka "getPath\|\.path" \
     -- path:docs-examples
   ```
   Focus on:
   - `buildSrc/src/main/kotlin/` convention plugins
   - `build.gradle.kts` files in `docs-examples/`
   - Any plugin that registers a project evaluation listener

2. **Understand the context**
   - Which plugin/listener is attached to `:client-extension`?
   - Is `getPath()` called on a `ProjectDependency` to get the project path string
     (e.g. `:some:subproject`)?

3. **Identify the correct replacement**
   Gradle 9 migration: `ProjectDependency.getPath()` → use one of:
   - `dependency.dependencyProject.path` (if project reference is safe at
     configuration time and the `getDependencyProject()` method is available —
     check Gradle 9 API docs, this method exists in 9.x)
   - `(dependency as ProjectDependency).dependencyProject.path`
   - Access the `ProjectDependency`'s `path` property via the `ProjectDependency`
     interface rather than the removed convenience method.

4. **Check whether `getDependencyProject()` was also removed in Gradle 9**
   - The earlier error (Category 0, creek-base) was `getDependencyProject()` being
     called by `moduleplugin 1.8.15` (fixed by upgrading to 2.0.0).
   - Confirm whether `getDependencyProject()` still exists in Gradle 9 API or if
     only `getPath()` was removed.
   - If `getDependencyProject()` is available, use `dependency.dependencyProject.path`.

5. **Check for any other removed API calls** in `docs-examples/` beyond `getPath()`:
   ```
   # Common Gradle 9 removals to check for:
   # - Project.exec() / Project.javaexec()
   # - ProjectDependency.getDependencyProject()
   # - Convention mapping APIs
   gh search code --repo creek-service/creek-kafka \
     "getDependencyProject\|\.exec\b\|\.javaexec\b\|getConventionMapping" \
     -- path:docs-examples
   ```

## Fix
- Replace `dependency.getPath()` (or `dependency.path`) with
  `dependency.dependencyProject.path` (or equivalent safe accessor).
- The fix is in the project evaluation listener that processes `:client-extension`
  configuration — likely in a convention plugin or `build.gradle.kts` in
  `docs-examples/`.
- Push the fix commit to the `dependabot/gradle/docs-examples/gradle-wrapper-9.4.1`
  branch of `creek-kafka`.

## Rollout
Single repo only (`creek-kafka` PR #836 docs branch). Apply and push directly
to the PR branch.
