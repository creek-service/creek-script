# creek-script
Scripts and docs for working with Creek Service repositories

## Installation

To install the scripts, run `. .\install.sh`

## Z-shall Functions

### Git

#### creek-git-diff

Show a diff of all local Creek git repos. All parameters are passed to `git diff`.

For example:

```shell
> creek-git-diff --name-only
----- creek-json-schema -------------------
?? diff.txt
----- creek-json-schema-gradle-plugin -------------------

.github/workflows/codeql.yml
----- creek-kafka -------------------

.github/workflows/codeql.yml
.gitignore
```

The `?? diff.txt` shows an untracked file in the `creek-json-schema` repo.
Two other repos have differences.