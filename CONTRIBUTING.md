# Contributing to Linux Admin Center

Thank you for helping improve Linux Admin Center. Contributions may include bug
reports, feature proposals, documentation improvements, tests, and code changes.

## Before you start

- Search existing issues and pull requests before opening a new one.
- Use the provided issue forms for bug reports and feature requests.
- Discuss substantial behavioral or architectural changes in an issue first.
- Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

The detailed developer and architecture documentation is currently maintained
in German:

- [Developer guide](docs/Entwicklerhandbuch.md)
- [Architecture](docs/Architektur.md)

## Development setup

The runtime requires Bash 4.3 or newer. The complete quality checks additionally
use ShellCheck and Debian packaging tools. Docker is required only for the local
cross-distribution portability workflow.

Clone the repository and create a focused branch from the current `main` branch:

```bash
git clone https://github.com/sunlover83/LinuxAdminCenter.git
cd LinuxAdminCenter
git switch main
git pull --ff-only
git switch -c feature/short-description
```

Use a descriptive prefix such as `feature/`, `fix/`, `docs/`, `test/`, or
`chore/`.

## Coding guidelines

- Keep changes focused and avoid unrelated refactoring.
- Preserve the existing modular Bash structure.
- Quote shell expansions unless intentional word splitting is required.
- Keep user-visible output clear and actionable.
- Treat privileged operations, filesystem changes, and package-manager actions
  as security-sensitive.
- Add or update tests for behavioral changes.
- Update documentation and `CHANGELOG.md` when a user-visible change requires it.
- Do not include credentials, personal paths, hostnames, hardware fingerprints,
  or other sensitive data in code, fixtures, logs, or screenshots.

## Validation

Run the regression suite:

```bash
bash tests/run_tests.sh
```

Run the portability subset:

```bash
bash tests/portability_test.sh
```

Run ShellCheck:

```bash
shellcheck install.sh uninstall.sh debian/preinst scripts/*.sh \
    src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

For Debian package changes, also run:

```bash
bash tests/debian_package_build.sh
bash tests/debian_package_lifecycle.sh
bash tests/debian_package_lint.sh
```

GitHub Actions repeats the complete quality and portability matrix for every
pull request.

## Pull requests

- Target `main` from a focused branch.
- Complete the pull request template.
- Link related issues with `Closes #<issue-number>` when appropriate.
- Describe safety-relevant behavior and the validation performed.
- Keep the branch up to date when requested.
- Resolve review findings without hiding unrelated changes in the same commit.

Pull requests are merged only after the required checks have completed
successfully.

## License

By contributing, you agree that your contribution is licensed under the
repository's [MIT License](LICENSE).
