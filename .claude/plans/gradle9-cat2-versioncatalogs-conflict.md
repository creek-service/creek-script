# Gradle 9 — Category 2: `Cannot add extension 'versionCatalogs'`

## Affected PRs (5 repos)
| Repo | PR |
|------|----|
| `basic-kafka-streams-demo` | #678 |
| `aggregate-template` | #827 |
| `ks-aggregate-api-demo` | #565 |
| `ks-connected-services-demo` | #606 |
| `wip-state-stores-demo` | #117 |

## Error
```
An exception occurred applying plugin request [id: 'org.creekservice.system.test']
> Failed to apply plugin 'org.creekservice.system.test'.
   > Could not create task of type 'SystemTest'.
      > A problem occurred configuring project
          ':buildSrc:generatePrecompiledScriptPluginAccessors:accessors…'.
         > Cannot add extension with name 'versionCatalogs',
           as there is an extension already registered with that name.
```

## Problem Statement
In Gradle 9, when `buildSrc` generates accessors for precompiled script plugins,
the `versionCatalogs` extension is already registered on the synthetic accessor
project by the Gradle infrastructure. The `org.creekservice.system.test` plugin
(applied inside a convention plugin in these repos, likely a coverage or test
convention) then tries to register its own `versionCatalogs` extension, causing
a conflict crash at configuration time — before any source is compiled.

Note: this also fails on `wip-state-stores-demo` which uses Gradle 9.3.1, so the
issue is not specific to 9.4.1.

## Investigation Steps

1. **Locate the `org.creekservice.system.test` plugin source**
   - This plugin lives in the `creek-system-test` repo.
   - Find where it registers the `versionCatalogs` extension:
     `gh api repos/creek-service/creek-system-test/git/trees/main?recursive=1 | jq '.tree[].path' | grep -i catalog`
   - Read the plugin source to understand why/when it registers the extension.

2. **Understand the Gradle 9 change**
   - In Gradle 9, `VersionCatalogsExtension` (`versionCatalogs`) is auto-applied
     to _all_ projects including synthetic accessor projects in `buildSrc`.
   - The plugin must be registering it unconditionally.

3. **Identify the fix location**
   - The fix belongs in `creek-system-test` repo (the plugin source), not in the
     affected demo/template repos — fixing the plugin fixes all consumers.
   - Find the plugin class that calls `project.extensions.create("versionCatalogs", ...)`
     or similar.

4. **Apply the fix**
   - Guard the extension registration:
     ```kotlin
     if (project.extensions.findByName("versionCatalogs") == null) {
         project.extensions.create("versionCatalogs", ...)
     }
     ```
   - Or check whether the plugin should skip registration entirely on synthetic
     accessor projects (they have a special project path like `:buildSrc:...accessors...`).

5. **Check if `creek-system-test` itself has a Gradle 9 PR open**
   - If it does (PR #675), the fix should be pushed to that branch.
   - Then the 5 affected demo/template repos need to consume the updated version
     of the plugin once it is published, OR the fix is applied to their local
     buildSrc convention files if the registration happens there instead.

6. **Verify the fix** by running `./gradlew tasks` on one of the affected repos
   locally (or triggering CI) to confirm `buildSrc` generates accessors cleanly.

## Rollout
- If the fix is in the `creek-system-test` plugin: publish a new snapshot/release
  and update version references in the 5 affected repos' `build.gradle.kts`.
- If the fix is in convention files within each affected repo's `buildSrc`: push
  the change to each of the 5 PR branches.
