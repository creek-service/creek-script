# Creek Build Failure Patterns

## Notes
- creek-json-schema-gradle-plugin and creek-system-test-gradle-plugin are Gradle plugins; failures in
  creek-json-schema-gradle-plugin upstream may cascade into creek-system-test-gradle-plugin.
- creek-kafka matrix uses Kafka versions: 2.8.2, 3.0.2, 3.1.2, 3.2.3, 3.3.2, 3.4.1, 3.5.2, 3.6.2, 3.7.0
