## Summary

Describe the purpose and user-visible result of this pull request.

## Related issues

Closes #

## Changes

<!-- List the main changes as bullet points. -->

## Safety and system impact

Describe any privileged commands, filesystem changes, package-manager actions,
service changes, network access, or cleanup behavior. Write `None` when the
change has no such impact.

## Validation

List the commands and environments used to validate the change.

```text
bash tests/run_tests.sh
```

## Checklist

- [ ] The change is focused and does not include unrelated modifications.
- [ ] Tests were added or updated where behavior changed.
- [ ] The regression suite and relevant focused tests pass.
- [ ] ShellCheck passes for changed shell files.
- [ ] Documentation and changelog entries were updated when required.
- [ ] No credentials, personal data, machine-specific paths, hostnames, or hardware fingerprints were added.
- [ ] Security-sensitive and privileged behavior is described above.
