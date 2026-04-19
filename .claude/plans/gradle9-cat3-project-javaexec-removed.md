# Gradle 9 — Category 3: `Project.javaexec()` removed

## Affected PRs (1 repo)
| Repo | PR |
|------|----|
| `creek-kafka` | #850 |

## Error
```
Execution failed for task ':test-service-json:generateJsonSchema'.
> 'org.gradle.process.ExecResult org.gradle.api.Project.javaexec(org.gradle.Action)'
```

Fails across all 10 build matrix entries (Kafka versions 2.8.2 through 3.7.0,
both Linux and Windows).

## Problem Statement
Gradle 9 removed `Project.javaexec()` (and `Project.exec()`), which were
deprecated in Gradle 7.6. Code that calls `project.javaexec { ... }` directly
in a task action or configuration block now throws a `groovy.lang.MissingMethodException`
/ `NoSuchMethodError` at runtime.

The `generateJsonSchema` task in the `:test-service-json` subproject calls
`project.javaexec { ... }` directly.

## Investigation Steps

1. **Find the `generateJsonSchema` task definition** in `creek-kafka`:
   ```
   gh api repos/creek-service/creek-kafka/contents/test-service-json/build.gradle.kts \
     --jq '.content' | base64 -d
   ```
   Or search across the repo:
   ```
   gh search code --repo creek-service/creek-kafka "generateJsonSchema" 
   ```

2. **Understand how `javaexec` is used**
   - Is it called inside a `@TaskAction` method of a custom task class?
   - Is it called in a `doFirst`/`doLast` block?
   - What class/jar is being executed and what arguments does it take?

3. **Identify the correct replacement**
   Gradle 9 migration guide recommends two approaches:
   
   a. **Inject `ExecOperations`** (preferred for custom task classes):
      ```kotlin
      abstract class GenerateJsonSchema @Inject constructor(
          private val execOps: ExecOperations
      ) : DefaultTask() {
          @TaskAction
          fun generate() {
              execOps.javaexec {
                  mainClass.set("com.example.SchemaGenerator")
                  classpath(...)
              }
          }
      }
      ```
   
   b. **Use `providers.javaexec`** (for use in build scripts / lazy evaluation):
      ```kotlin
      providers.javaexec {
          mainClass.set("com.example.SchemaGenerator")
          classpath(...)
      }.result.get()
      ```

4. **Check whether this task is defined in `buildSrc`, a convention plugin, or
   inline in `build.gradle.kts`** — the fix location depends on where it lives.

5. **Check for any other uses of `project.exec()` or `project.javaexec()`** in
   the repo that may also need migrating:
   ```
   gh search code --repo creek-service/creek-kafka "project.javaexec\|project.exec"
   ```

## Fix
- Replace `project.javaexec { ... }` with `ExecOperations` injection in the
  custom task class, or `providers.javaexec { ... }` in build script context.
- Push the fix commit to the `dependabot/gradle/gradle-wrapper-9.4.1` branch
  of `creek-kafka`.

## Rollout
Single repo only (`creek-kafka` PR #850). Apply and push directly to the PR branch.
