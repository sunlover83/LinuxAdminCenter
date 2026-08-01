# Linux Admin Center (LAC)

> **Powerful administration. Simple operation.**

Linux Admin Center is a modular Bash application for common Linux desktop administration tasks. It provides an interactive terminal interface as well as command-line options while keeping all system actions transparent.

## Current features

- Interactive main menu
- Update checks and update installation
- Support for APT, DNF, Pacman and Zypper
- System and hardware information
- Network information
- Restart-requirement detection
- System-wide and user-specific configuration
- Debug logging
- Automated shell tests

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

## Configuration

LAC reads configuration from these locations in order:

1. `/etc/lac/lac.conf`
2. `${XDG_CONFIG_HOME:-$HOME/.config}/lac/lac.conf`

User settings override system settings. Currently supported:

```ini
DEBUG=false
```

## Development

Run all tests:

```bash
bash tests/run_tests.sh
```

Run ShellCheck:

```bash
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

## Project structure

```text
src/lac.sh                  Application entry point
src/core/                   Shared CLI, configuration, metrics and UI code
src/modules/update/         Update management
src/modules/system_info/    System information view
src/modules/network_info/   Network information view
tests/                      Automated shell tests
docs/                       Project documentation
```

## Roadmap

The project is currently in the `0.1.0-alpha` development phase. Features are implemented incrementally and the version will be raised once the current foundation is consolidated.

Planned areas include:

- System cleanup tools
- Hardware diagnostics
- Extended network diagnostics
- Gaming-related system tools
- Installation and packaging workflow

## License

This project is licensed under the MIT License.
