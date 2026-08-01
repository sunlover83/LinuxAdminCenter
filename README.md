# Linux Admin Center (LAC)

> **Powerful administration. Simple operation.**

Linux Admin Center is a modular Bash application for common Linux desktop administration tasks. It provides an interactive terminal interface as well as command-line options while keeping all system actions transparent.

Current version: **0.2.0-alpha (Consolidation)**

## Current features

- Interactive main menu
- Update checks and update installation
- Support for APT, DNF, Pacman and Zypper
- System and hardware information
- Dedicated network information
- Restart-requirement detection
- System-wide and user-specific configuration
- Debug logging
- Automated shell tests
- Automated GitHub Actions quality checks

## Usage

Start the interactive interface:

```bash
./src/lac.sh
```

Available command-line options:

```text
-h, --help          Show help
-v, --version       Show version information
-i, --system-info   Show system information
-n, --network-info  Show network information
-u, --check-updates Check for available updates
```

The update check returns status `10` when updates are available. This allows scripts to distinguish available updates from execution errors.

## Configuration

LAC reads configuration from these locations in order:

1. `/etc/lac/lac.conf`
2. `${XDG_CONFIG_HOME:-$HOME/.config}/lac/lac.conf`

User settings override system settings. Currently supported:

```ini
DEBUG=false
```

## Documentation

- [Installation](docs/Installation.md)
- [User manual](docs/Benutzerhandbuch.md)
- [Architecture](docs/Architektur.md)
- [Developer guide](docs/Entwicklerhandbuch.md)
- [Changelog](CHANGELOG.md)

The detailed project documentation is currently maintained in German.

## Development

Run all tests:

```bash
bash tests/run_tests.sh
```

Run ShellCheck:

```bash
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

GitHub Actions runs both checks automatically for pull requests and pushes to `main`.

## Project structure

```text
.github/workflows/         Automated quality checks
src/lac.sh                 Application entry point
src/core/                  Shared CLI, configuration, metrics and UI code
src/modules/update/        Update management
src/modules/system_info/   System information view
src/modules/network_info/  Network information view
tests/                     Automated shell tests
docs/                      Project documentation
```

## Roadmap

Version `0.2.0-alpha` consolidates the existing foundation with complete project documentation, separated system and network views, and automated quality checks.

Planned areas for later development include:

- System cleanup tools
- Hardware diagnostics
- Extended network diagnostics
- Gaming-related system tools
- Installation and packaging workflow

The next functional module will be planned separately after the consolidation phase.

## License

This project is licensed under the MIT License.
