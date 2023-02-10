# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

#
asdf plugin test kubecolor https://github.com/bartoszmajsak/asdf-kubecolor.git "kubecolor --kubecolor-version"
```

Tests are automatically run in GitHub Actions on push and PR.
