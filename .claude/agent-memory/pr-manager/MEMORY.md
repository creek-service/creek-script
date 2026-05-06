# PR Manager Memory

## CI Infrastructure Issues
- `gradle/wrapper-validation-action` can intermittently fail with ETIMEDOUT on Cloudflare IPs (104.16.72.101, 104.16.73.101) — retry with a new push/empty commit usually resolves it
- `creek-json-schema-gradle-plugin` has a flaky test: `GenerateJsonSchemaTest` uses Gradle 8.14.4 which occasionally gets a 502/timeout from services.gradle.org — retry resolves it

## Key Repo Notes
- `creek-json-schema-gradle-plugin` build has both linux and windows jobs + functional tests (takes 20+ min)
