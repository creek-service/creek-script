# Release process

The process of building a new release and publishing to Maven Central is currently a partly manual process.

Each project has a `Release` GitHub workflow that will push a release tag to the repo.
The pushing of the release tag will trigger a build, which will build and upload artifacts and create a GitHub release.

What is not currently automated is the updating of Creek's internal dependencies, e.g., once `creek-base` is released,
updating other projects that depend on it to the new release version. This needs to be done manually.
PRs to switch to release dependencies prior to release, and to the new snapshot after release,
should be tagged with the `chore` label, so that they do not show up in the release notes.

## Release steps

1. Check [SonaType Lift](https://lift.sonatype.com/results/github.com/creek-service) and review:
   1. issues: resolving / suppressing as required.
   2. Dependency security vulnerabilities: Update transient dependencies where fixes exist.
      Clear out older transient dependency bumps where no longer needed.
2. Check [Maven Deps](https://deps.dev/search?q=org.creekservice&system=maven&kind=PACKAGE) for similar to above.
3. Run Dependabot on all repos to check for updates to dependencies.
   This helps ensure all components use a consistent set of third-party libraries.
4. Ensure all Dependabot related PRs are building successfully and then merge.
   Dependabot PRs will be tagged with the `dependencies` label.
5. For non-patch releases, set the next release version on all repos to be released, using the `Set Next Version`
   workflow on GitHub.
6. For each Creek repo, in the following order:
    ```
                               creek-test
                                   |
                               creek-base
                                   |
                        ---------------------------------
                        |                               |
                creek-observability              creek-json-schema
                        |                                |
                  creek-platform            creek-json-schema-gradle-plugin
                        |                   
                   creek-service           
                        |
                creek-system-test
                        |
                        --------------------------------------
                        |                                    |
            creek-kafka & all extensions      creek-system-test-gradle-plugin
    ```
7. ...follow these steps to release:
    1. Run the `Release` workflow on GitHub e.g. [Creek test Release](https://github.com/creek-service/creek-test/actions/workflows/release.yml).
    2. Ensure the `Release` workflow, and the triggered `Build` workflow on the release tag, complete successfully.
    3. Ensure artifacts are correctly published to the [Sona Type Nexus](https://central.sonatype.com/search?q=org.creekservice)
    4. Ensure artifacts are later available on Maven Central.
    5. Ensure Gradle plugins are published to the Gradle Plugin Portal, e.g. [org.creekservice.schema.json](https://plugins.gradle.org/plugin/org.creekservice.schema.json)

## Post-release steps

Once all components are released, follow these post-release steps:

1. For each Creek repo, in the same order as above, namely
   ```
                               creek-test
                                   |
                               creek-base
                                   |
                        ---------------------------------
                        |                               |
                creek-observability              creek-json-schema
                        |                                |
                  creek-platform            creek-json-schema-gradle-plugin
                        |                   
                   creek-service           
                        |
                creek-system-test
                        |
                        --------------------------------------
                        |                                    |
            creek-kafka & all extensions      creek-system-test-gradle-plugin
                        |                                    |
                        --------------------------------------
                                           |
                               multi & single-module-template     
    ```
2. follow these steps the next snapshot build to be built
    1. Create a PR with a small change, a newline in a doc.
    2. Label the PR with `chore` so that it is excluded from the release notes.
    3. Merge this PR once it's green.
3. Announce on main doc site https://github.com/creek-service/creek-service.github.io
   e.g. https://github.com/creek-service/creek-service.github.io/pull/11
   1. Create a post announcing the new release.
   2. Update `_pages/home.md` to reference new release version and announcement post.

## Notes on the release process

The Creek organisation in GitHub has the following release-related secrets:
- `TRIGGER_GITHUB_TOKEN`: A token with permissions to allow the `release` workflow to trigger the main `build` workflow when it pushes a new release tag
  A fine-grained token _for the creek org_ with the following rights on all repos:
  - content: read / write: so it can push tags
  - actions: read / write: sp it can trigger the main build.
- `ORG_GRADLE_PROJECT_SIGNINGKEY`/`ORG_GRADLE_PROJECT_SIGNINGPASSWORD`: The GPG key and passphrase used for signing release artifacts.
  See https://central.sonatype.org/publish/requirements/gpg/ for more info.
- `SONA_USERNAME`/`SONA_PASSWORD`: Secrets for publishing to the [Maven Central Portal](https://central.sonatype.org/pages/ossrh-eol/) used for uploading artifacts to Maven Central.
  See https://blog.solidsoft.pl/2015/09/08/deploy-to-maven-central-using-api-key-aka-auth-token/#nexus-api-key-generation for more info.
- `GRADLE_PUBLISH_KEY`/`GRADLE_PUBLISH_SECRET`: Secrets for publishing Gradle plugins to the plugin portal.

## Developer setup

Nothing is required on a local developers machine.

However, creating a GPG key and [adding it to ~/.gradle/gradle.properties](https://central.sonatype.org/publish/publish-gradle/#credentials)
will mean locally created artifacts are signed before publishing, e.g., to `mavenLocal()`.
This can be usual for testing the build scripts.
