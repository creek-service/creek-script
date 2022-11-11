# creek-script

Scripts and docs for working with Creek Service repositories. 
Oh, and document the [Creek release process](ReleaseProcess.md).

## Installation

To install the scripts, run 

```shell
. ./install.sh 
brew install gh
```

## Z-shall Functions

### Git Repositories

Functions for working with Creek Git repos

Many of the functions make use of a `CREEK_BASE_DIR` environment var to determine the directory under which all
Creek repositories are checked out, and iterate over ALL repos in this directory, i.e. the functions expect
all Creek repositories to be in their own subdirectory, e.g. `~/dev/github.com/creek`.

`CREEK_BASE_DIR` is set in `.zshrc` by the `install.sh` script. It can be overridden before calling these functions.

#### creek_git_each

Runs the supplied commands against each Creek Git repo in turn. For example:

```shell
creek_git_each git status
```

...runs `git status` on each repo.

The `CREEK_EACH_EXCLUDE` variable can be used to exclude repos. For example:

```shell
CREEK_EACH_EXCLUDE="creek-script creek-service.github.io" creek_git_each git diff --name-only
```

...will output any changed file names, but not in the `creek-script` or `creek-service.github.io` repos. 

#### creek_gradle_each

Runs the supplied commands against each Creek repo in turn. For example:

```shell
creek_git_each git status
```

...runs `git status` on each repo.

#### creek_git_diff

Show a diff of all local Creek git repos. All parameters are passed on to `git diff`.

For example, the following lists only the name of changed and untracked files:

```shell
> creek_git_diff --name-only
----- creek-json-schema -------------------
?? diff.txt
----- creek-json-schema-gradle-plugin -------------------

.github/workflows/codeql.yml
----- creek-kafka -------------------

/src/java/org/creekservice/something
```

The `?? diff.txt` shows an untracked file in the `creek-json-schema` repo.
Two other repos have differences.
