# Security Policy

## Supported versions

Security fixes are provided for the latest stable Linux Admin Center release.

| Version | Supported |
| --- | --- |
| 1.2.x | Yes |
| Earlier versions | No |
| Pre-release versions | Best effort |

## Reporting a vulnerability

Do not report security vulnerabilities through a public GitHub issue, discussion,
or pull request.

Use GitHub's private vulnerability reporting feature from the repository's
**Security** tab. Include the following information when possible:

- the affected Linux Admin Center version and installation method;
- the affected distribution and version;
- a clear description of the vulnerability and its potential impact;
- minimal reproduction steps or a proof of concept;
- any suggested mitigation or fix;
- whether the vulnerability has already been disclosed elsewhere.

If private vulnerability reporting is temporarily unavailable, open a public
issue titled `Security contact request` without technical details, logs, or
proof-of-concept material. A private communication channel will then be arranged.

This is a volunteer-maintained project and cannot guarantee a fixed response
time. Reports will be acknowledged and assessed as soon as reasonably possible.

## Security-sensitive areas

Reports are especially valuable when they concern:

- privilege escalation or unsafe privileged command execution;
- command, argument, environment, or path injection;
- unsafe cleanup, installation, upgrade, or removal behavior;
- package or release artifact integrity;
- unintended disclosure of local system or user information;
- GitHub Actions or release workflow permissions.

## Responsible testing and disclosure

Test only on systems and data you own or are explicitly authorized to use.
Avoid destructive testing against third-party systems and do not access,
modify, or retain other people's data.

Please allow reasonable time for investigation and remediation before public
disclosure. Confirmed vulnerabilities will be documented with appropriate
credit unless the reporter requests anonymity.
