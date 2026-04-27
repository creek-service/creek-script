# Creek Build Inspector Memory

## Dependabot Workflow Patterns

Two classes of repos:

**"Dependabot Updates" orchestrator workflow** (runs on main branch, event=dynamic):
- aggregate-template, creek-base, creek-jekyll-theme, creek-json-schema-gradle-plugin,
  creek-observability, creek-platform, creek-release-test, creek-service,
  creek-service.github.io, creek-system-test, creek-system-test-gradle-plugin,
  multi-module-template, single-module-template, basic-kafka-streams-demo,
  creek-system-test, wip-state-stores-demo

**PR-based flow only** (no "Dependabot Updates" orchestrator; CI runs directly on dependabot/* branches):
- creek-json-schema, creek-kafka, creek-test, json-schema-validation-comparison,
  ks-aggregate-api-demo, ks-connected-services-demo

## Notes

- Java builds (gradle) take ~5-30 minutes, so CI queues after a dependabot bump are large and long
- The `/repos/{org}/{repo}/dependabot/updates` API returns 404 - not a supported endpoint
- Use `gh run list --limit 30 --json ...` to get enough runs per repo (large orgs have many PRs)
- `declare -A` (associative arrays) not supported in the shell environment - use python3 for complex data
- `creek-service.github.io` has a dot in the name; avoid using it in bash arithmetic contexts
