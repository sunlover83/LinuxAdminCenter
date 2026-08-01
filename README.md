# Linux Admin Center (LAC)

> **Powerful administration. Simple operation.**

Linux Admin Center is a modular Bash application for common Linux desktop administration tasks. It provides an interactive terminal interface as well as command-line options while keeping all system actions transparent.

Current version: **0.4.0-alpha (Diagnostics)**

## Current features

- Interactive main menu
- Update checks and update installation
- Support for APT, DNF, Pacman and Zypper
- System and hardware information
- Dedicated network information
- Read-only hardware diagnostics
- CPU temperature reporting through `sensors`
- NVIDIA GPU temperature, utilization and memory reporting
- SMART and NVMe drive-health checks
- Read-only cleanup report
- Confirmed package-cache cleanup
- Confirmed removal of packages classified as no longer required
- System journal disk-usage reporting
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
-h, --help                  Show help
-v, --version               Show version information
-i, --system-info           Show system information
-n, --network-info          Show network information
-d, --hardware-diagnostics Show hardware diagnostics
-u, --check-updates         Check for available updates
-c, --cleanup-report        Show a read-only cleanup report
```

The update check returns status `10` when updates are available. This allows scripts to distinguish available updates from execution errors.

The cleanup report never changes the system. Destructive cleanup actions are available only in the interactive menu and require explicit confirmation.

Hardware diagnostics are read-only. CPU, GPU and storage information is displayed only when the required tools are available. Drive-health checks may require root privileges; LAC does not request those privileges automatically.

## System cleanup safety

The current cleanup module is intentionally limited:

- package caches can be cleaned
- automatically installed packages that the package manager classifies as no longer required can be reviewed and removed
- journal disk usage is displayed, but journal files are not deleted
- repository metadata is not removed
- Pacman cache cleanup keeps the two newest cached versions

Users should review every proposed package removal before entering the required `REMOVE` confirmation.

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
.github/workflows/                  Automated quality checks
src/lac.sh                          Application entry point
src/core/                           Shared CLI, configuration and metrics code
src/modules/update/                 Update management
src/modules/cleanup/                Safe system cleanup workflow
src/modules/system_info/            System information view
src/modules/network_info/           Network information view
src/modules/hardware_diagnostics/   Hardware diagnostics view
tests/                              Automated shell tests
docs/                               Project documentation
```

## Roadmap

Version `0.4.0-alpha` introduces read-only hardware diagnostics for temperatures, NVIDIA GPUs and storage-device health.

Planned areas for later development include:

- Extended network diagnostics
- Gaming-related system tools
- Installation and packaging workflow
- Additional cleanup categories after separate safety reviews

## License

This project is licensed under the MIT License.
