# Release process

Each project has a `Release` GitHub workflow that will push a release tag to the repo.
The pushing of the release tag will trigger a build, which will build and upload artifacts and create a GitHub release.

## Versioning
 
### Core repos

Core repos get their Creek version from Git tags via the `pl.allegro.tech.build.axion-release` plugin.

Run the following to determine the current version, run the following command on a local, up-to-date, copy of the repo, with no local changes, from the `main` branch:

```shell
./gradlew -q cV
```

### Demo repos

Demo repos get their Creek version from the `creekVersion` property, defined in either the root Gradle build file or Gradle properties file.

Demo repos can also make use of Creek plugins, which may be versioned explicitly. These should be kept inline with the `creekVersion` property.

## Pre-Release steps

### Preparing core repos

1. Run Dependabot checks across all core repos and ensure all Dependabot PRs are merged and the main branch build has passed.
2. Check all core repos for open security vulnerabilities, e.g. under https://github.com/creek-service/creek-system-test-gradle-plugin/security/dependabot and abort the release if any are found.
3. Verify the main build of all core repos are building successfully on Github
4. For non-patch releases, run the 'Set Next Version' workflow on all core repos in parallel, setting the part to either `minor` or `major`, as requested by the user. Wait for the workflows to complete and verify success.
5. Verify all core repos now have the correct version set in their root Gradle build file.

### Verifying demos work

For each demo repo:

1. Look for an existing, or create a WIP PR that updates the version of creek, including creek plugin versions, to the current snapshot version.
2. Verify the PR builds successfully on GitHub. If not, inform the user and await instructions.

## Release Execution Phase

Follow the strict dependency order:

```
                           creek-test
                               |
                           creek-base
                               |
                    ---------------------------------
                    |                               |
            creek-observability              creek-json-schema
                    |                               |
              creek-platform            creek-json-schema-gradle-plugin
                    |                                |
               creek-service                         |
                    |                                |
            creek-system-test                        |
                    |                                |
                    -------------------------------  |
                    |                             |  |
     creek-system-test-gradle-plugin        creek-kafka & all extensions
```

For each repo in order:
1. Verify the latest release for the repo is as expected, i.e. NOT the release currently being worked on.
2. Trigger the 'Release' workflow on GitHub using `gh workflow run`
3. Monitor workflow completion and verify success
4. The 'Release' workflow will push a tag, causing a new 'Build' to be triggered on the `main` branch: monitor the main build workflow and verify success.
5. Verify the new version is published to Sonatype Nexus (https://central.sonatype.com/search?q=org.creekservice) (can take several minutes after Nexus publication)
6. For Gradle plugins, verify the new version is published to Gradle Plugin Portal (https://plugins.gradle.org/search?term=org.creekservice) (can take several minutes after Nexus publication)
7. Do NOT proceed to the next repo until the current repo is fully verified

### Parallelization Opportunities

- creek-observability and creek-json-schema can be released in parallel
  - once creek-observability is done, creek-platform can be started, etc.
  - once creek-json-schema is done, creek-json-schema-gradle-plugin can be started
- creek-kafka requires both creek-system-test and creek-json-schema-gradle-plugin
- creek-kafka and extensions can be released in parallel
- Wait for parent repos before releasing dependents

## Post-Release Phase

### Bump Creek version in demo repos to new release

For each demo repo:
1. Find the WIP PR that bumps the creek version to the snapshot version
2. Update the PR, including title and description, to bump the version to the newly released version of creek, including plugins.
3. Verify the demo repo builds successfully on GitHub. If not, inform the user and await instructions.
4. Mark the PR as ready for review.
5. Merge the PR.

### Bump Creek version in core repos docs site to new release

Some core repos have docs sites that use worked examples. These are stored under a `docs-examples` directory in the root of the repo.

For each core repo:
1. Update the `docs-examples` directory to use the new version of creek, including plugins.
2. Verify the docs site builds successfully on GitHub. If not, inform the user and await instructions.
3. Merge the PR.

### Publish next snapshot versions of core repos:

Follow the same project dependency order as release, for each core repo:
1. Push a change the READ.md in the repos root to trigger a new build. The change should either add a new line to the end of the file, or remove the existing blank line.
2. Verify the triggered `Build` workflow on the `main` branch succeeds and repot to the user if it does not.
3. Include post-release repos (multi-module-template, single-module-template)

###  Announce release

Update documentation site (https://github.com/creek-service/creek-service.github.io):
1. Create an announcement post
2. Update _pages/home.md with the new release version and announcement link

## Notes on the release process

The Creek organisation in GitHub has the following release-related secrets:
- `TRIGGER_GITHUB_TOKEN`: A token with permissions to allow the `release` workflow to trigger the main `build` workflow when it pushes a new release tag
  A fine-grained token _for the creek org_ with the following rights on all repos:
  - content: read / write: so it can push tags
  - actions: read / write: sp it can trigger the main build.
- `ORG_GRADLE_PROJECT_SIGNINGKEY`/`ORG_GRADLE_PROJECT_SIGNINGPASSWORD`: The GPG key and passphrase used for signing release artifacts.
  See https://central.sonatype.org/publish/requirements/gpg/ for more info.
- `SONA_USERNAME`/`SONA_PASSWORD`: Secrets for publishing to the [Maven Central Portal](https://central.sonatype.org/pages/ossrh-eol/).
  See https://blog.solidsoft.pl/2015/09/08/deploy-to-maven-central-using-api-key-aka-auth-token/#nexus-api-key-generation for more info.
- `GRADLE_PUBLISH_KEY`/`GRADLE_PUBLISH_SECRET`: Secrets for publishing Gradle plugins to the plugin portal.

## Developer setup

Nothing is required on a local developers machine.

However, creating a GPG key and [adding it to ~/.gradle/gradle.properties](https://central.sonatype.org/publish/publish-gradle/#credentials)
will mean locally created artifacts are signed before publishing, e.g., to `mavenLocal()`.
This can be usual for testing the build scripts.
