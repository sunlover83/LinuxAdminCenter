# Linux Admin Center (LAC)

> **Powerful administration. Simple operation.**

Linux Admin Center is a modular Bash application for common Linux desktop administration tasks. It provides an interactive terminal interface as well as command-line options while keeping all system actions transparent.

Current version: **0.8.0-alpha (Compatibility)**

## Current features

- Interactive main menu
- Update checks and update installation
- Support for APT, DNF, Pacman and Zypper
- System and hardware information
- Dedicated network information
- Read-only network diagnostics
- Gateway, DNS and external connectivity checks
- Packet-loss and average-latency reporting
- Overall network assessment using `healthy`, `warning` and `failed`
- Read-only hardware diagnostics
- CPU temperature reporting through `sensors`
- NVIDIA GPU temperature, utilization and memory reporting
- SMART and NVMe drive-health checks
- Read-only Gaming Readiness report
- Display-server and desktop-environment detection
- Active graphics-driver and NVIDIA driver-version reporting
- Vulkan verification through `vulkaninfo`
- Native and Flatpak Steam detection
- Custom Proton compatibility-tool discovery
- Availability reporting for GameMode, MangoHud and Gamescope
- Overall gaming-readiness assessment using `ready`, `limited` and `incomplete`
- Read-only Gaming Diagnostics report
- Vulkan instance-version, device, driver and API-version reporting
- Conservative 32-bit Vulkan support verification with Flatpak-aware handling
- Steam launch-target and Steam-library discovery
- Bundled and custom Proton-runtime discovery
- Steam compatibility-prefix counting across libraries
- GameMode, MangoHud, MangoApp and Gamescope integration reporting
- Gamescope version reporting
- Overall gaming-diagnostics assessment using `healthy`, `warning` and `incomplete`
- Read-only service health report for systemd systems
- Init-system and systemd-state detection
- Active, inactive and failed service counts
- Failed-service details through `systemctl show`
- Total boot-time and slowest-service reporting through `systemd-analyze`
- Overall service assessment using `healthy`, `warning` and `failed`
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
-h, --help                   Show help
-v, --version                Show version information
-i, --system-info            Show system information
-n, --network-info           Show network information
-r, --network-diagnostics    Show network diagnostics
-d, --hardware-diagnostics   Show hardware diagnostics
-g, --gaming-readiness       Show gaming readiness
-G, --gaming-diagnostics     Show detailed gaming diagnostics
-e, --service-health         Show service health
-u, --check-updates          Check for available updates
-c, --cleanup-report         Show a read-only cleanup report
```

The update check returns status `10` when updates are available. This allows scripts to distinguish available updates from execution errors.

The cleanup report never changes the system. Destructive cleanup actions are available only in the interactive menu and require explicit confirmation.

Hardware diagnostics are read-only. CPU, GPU and storage information is displayed only when the required tools are available. Drive-health checks may require root privileges; LAC does not request those privileges automatically.

Network diagnostics are also read-only. LAC checks the IPv4 default gateway, DNS resolution and external IP reachability without modifying network interfaces, routes or DNS settings. Non-responsive ICMP targets are reported carefully because ping traffic may be blocked even when other network functions work.

The default diagnostic targets can be overridden temporarily:

```bash
LAC_DNS_TEST_HOST=example.org \
LAC_INTERNET_TEST_TARGET=9.9.9.9 \
./src/lac.sh --network-diagnostics
```

Gaming Readiness is the fast compatibility overview. It reports the graphical session, active graphics drivers, Vulkan verification, Steam availability, custom Proton tools and optional gaming utilities. Missing `vulkaninfo` is reported as `not verified`; it is not treated as proof that the Vulkan runtime itself is absent.

Gaming Diagnostics provides a deeper, still read-only compatibility analysis. It reports Vulkan runtime details, detected Vulkan devices and drivers, 32-bit Vulkan support, Steam library roots, installed Proton runtimes, compatibility-prefix counts and gaming integration tools. Native Steam uses conservative host-library checks for 32-bit Vulkan; Flatpak Steam reports this support as managed by Flatpak instead of evaluating host i386 library paths.

Service Health is read-only and currently targets systemd systems. It reports the system state, service counts, failed-service details, total boot time and the slowest services. LAC does not start, stop, enable, disable or restart services and does not request elevated privileges for these checks.

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
src/modules/network_diagnostics/    Network diagnostics view
src/modules/hardware_diagnostics/   Hardware diagnostics view
src/modules/gaming_readiness/       Gaming readiness view
src/modules/gaming_diagnostics/     Detailed gaming compatibility diagnostics
src/modules/service_health/         Service health view
tests/                              Automated shell tests
docs/                               Project documentation
```

## Roadmap

Version `0.8.0-alpha` introduces deeper read-only gaming compatibility diagnostics for Vulkan, Steam libraries, Proton runtimes and related gaming integrations while keeping the existing Gaming Readiness quick check separate.

Planned areas for later development include:

- Installation and packaging workflow
- Additional cleanup categories after separate safety reviews
- Further diagnostic modules where they provide clear administrative value

## License

This project is licensed under the MIT License.
