# Release process

The process of building a new release and publishing to Maven Central is currently a partly manual process.

Each project has a `Release` GitHub workflow that will push a release tag to the repo.
The pushing of the release tag will trigger a build, which will build and upload artifacts and create a GitHub release.

What is not currently automated is the updating of Creek's internal dependencies, e.g. once `creek-base` is released,
updating other projects that depend on it to the new release version. This needs to be done manually.
PRs to switch to release dependencies prior to release, and to the new snapshot after release,
should be tagged with the `chore` label, so that they do not show up in the release notes.

## Release steps

1. Run Dependabot on all repos to check for updates to dependencies.
   This helps ensures all components use a consistent set of 3rd-party libraries.
2. Ensure all Dependabot related PRs are building successfully and then merge.
   Dependabot PRs will be tagged with the `dependencies` label.
3. Ensure each repo's current version is on the correct snapshot build
   ```shell
   mkdir tmp
   
   # Check out a fresh copy of each repo to a temp location
   creek_gh_clone ./tmp ".github aggregate-template example-kafka-streams-aggregate multi-module-template simple-kafka-streams-tutorial single-module-template creek-script creek-release-test creek-service.github.io"
   
   # Display each repos version:  
   CREEK_BASE_DIR="./tmp" creek_gradle_each ./gradlew cV -quiet
   
   rm -rf ./tmp
   ```
5. For each Creek repo, in the following order:
    1. `creek-test`
    2. `creek-base`
    3. `creek-observability` & `creek-platform`
    4. `creek-json-schema` & `creek-service`
    5. `creek-json-schema-gradle-plugin` & `creek-system-test`
    6. `creek-system-test-gradle-plugin`
    7. all extension repos, e.g. `creek-kafka`
6. ...follow these steps to release:
    1. Run GitHub dependency bot, e.g. the [creek-base dependency bot](https://github.com/creek-service/creek-base/network/updates)
       <br>This will generate a PR to update the version of other Creek components the repo depends on to the release build.
        1. Ignore any other non-Creek dependency update PRs for now.
           Merging them could result in inconsistent 3rd party library versions across the components.
        2. label the Creek dependency PR with `chore` so that it is excluded from the release notes.
        3. Ensure the PR builds and then merge.
        4. Wait for the triggered `Build` on the `main` branch to complete.
    2. Run the `Release` workflow on GitHub e.g. [Creek test Release](https://github.com/creek-service/creek-test/actions/workflows/release.yml).
    3. Ensure the `Release` workflow, and the triggered `Build` workflow on the release tag, complete successfully.
    4. Ensure artefacts are correctly published to the [OSSHR Nexus](https://s01.oss.sonatype.org/), and later available on Maven Central.
    5. Ensure Gradle plugins are published to the Gradle Plugin Portal, e.g. [org.creekservice.schema.json](https://plugins.gradle.org/plugin/org.creekservice.schema.json)

## Post release steps

Once all components are released, follow these post release steps:

1. Update `aggregate-template` to the new release version
   by running [GitHub Dependabot](https://github.com/creek-service/aggregate-template/network/updates).
   Merging all dependency PRs.
2. Do the same steps as above for all tutorials. [Need a way to automate this!](https://github.com/dependabot/dependabot-core/issues/6098)
3. For `creek-test`, commit a small change, e.g. a newline in a doc.
   This will trigger a new snapshot build to be created.
   Once build...
4. For each Creek repo, in the following order:
    1. `creek-base`
    2. `creek-observability` & `creek-platform` & `single-module-template` & `double-module-template`
    3. `creek-json-schema` & `creek-service`
    4. `creek-json-schema-gradle-plugin` & `creek-system-test`
    5. `creek-system-test-gradle-plugin`
    6. all extension repos, e.g. `creek-kafka`
5. ...follow these steps to update to the next snapshot:
    1. Run the e.g. the [creek-base dependency bot](https://github.com/creek-service/creek-base/network/updates)
       This will pick up the new snapshot build and create an appropriate PR.
    2. Merge this PR once its green.
6. Update  to the new release version:
   by running [GitHub Dependabot](https://github.com/creek-service/aggregate-template/network/updates).
   Merging all dependency PRs.

## Notes on release process

The Creek organisation in GitHub has secrets containing:
- The GPG key and passphrase used for signing release artifacts.
  See https://central.sonatype.org/publish/requirements/gpg/ for more info.
- A Nexus API key used for uploading artifacts to Maven Central / OSSHR.
  See https://blog.solidsoft.pl/2015/09/08/deploy-to-maven-central-using-api-key-aka-auth-token/#nexus-api-key-generation for more info.

## Developer setup

Nothing is required on a local developers machine.

However, creating a GPG key and [adding it to ~/.gradle/gradle.properties](https://central.sonatype.org/publish/publish-gradle/#credentials)
will mean locally created artifacts are signed before publishing, e.g. to `mavenLocal()`.
This can be usual for testing the build scripts.
