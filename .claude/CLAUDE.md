# Claude memory

The Creek Service project is hosted on Github: https://github.com/creek-service

When asked to perform operations on all Creek repositories, do not rely on existing local git clones. 
Instead, get the list of repos from Github. When necessary, clone the repo under /tmp, create a PR branch if requested, perform the operation, push, commit, and then delete the clone. 
This ensures that you are always working with the latest list of repos, and that you have a clean working directory for each operation.

## Repos

There are two sets of repos

### Core repos

These implement the published libraries of Creek itself.

These are generally using snapshot builds, unless a release is in progress.
They use a mostly consistent set of `buildSrc` files and Github workflows.

The dependency flow of the core repos is as follows:

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

### Demo repos

These consume the published libraries and demonstrate how to use them.

The will generally not be using snapshot builds. They get updated to the latest released version.
They use a mostly consistent set of `buildSrc` files and Github workflows, which are different from the core repos.

Demo repos have a name ending in `-demo`. The `aggregate-template` is used to build demo repos, and should also be considered a demo repo.

### Special repos

Special repos should not be considered a core/demo repo for the purposes of any operations that need to be performed across all repos.

- `json-schema-validation-comparison` is used to build a website to compare JSON Schema validation libraries. 
- `creek-script` is used to store scripts that perform operations across all repos. 
- `creek-service.github.io` is builds the docs site for the project
- `creek-jekyll-theme` is a theme used to build the docs site
- `.github` stores org wide files.
- `demo-repository` is a Github provided demo repo.


