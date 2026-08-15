# Linux Admin Center (LAC)

> **Powerful administration. Simple operation.**

Linux Admin Center is a modular Bash application for common Linux desktop administration tasks. It provides an interactive terminal interface as well as command-line options while keeping all system actions transparent.

Current version: **1.0.0 (Stable)**

Version 1.0.0 is the first stable Linux Admin Center release. It promotes the validated 1.0.0-rc1 baseline without adding new features or changing functional runtime behavior.

## Current features

- System-wide installer and uninstaller
- Standard `/usr/local` installation layout
- Installed `lac` and `lac-uninstall` commands
- Configurable installation prefix and `DESTDIR` staging support
- Safe reinstall workflow that replaces stale runtime files
- Configuration preservation during uninstall
- Bash 4.3 minimum-version enforcement before the full runtime is loaded
- Distribution-family detection through `ID` and `ID_LIKE`
- Interactive main menu
- Read-only LAC Self Check
- Bash-version, installation-type, runtime-file and launcher verification
- Required core-tool and optional diagnostic-tool availability reporting
- Configuration and package-manager availability reporting
- Overall self-check assessment using `healthy`, `warning` and `failed`
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
- Cross-distribution portability checks for Debian stable, Fedora, Arch Linux and openSUSE Tumbleweed

## Requirements

LAC requires:

- Linux
- Bash 4.3 or newer
- common command-line tools such as `awk`, `sed`, `find`, `sort`, `tr`, `uname`, `df`, `du` and `hostname`
- one supported package-manager family: APT, DNF, Pacman or Zypper

Feature-specific tools are detected at runtime and are not installed automatically. For example, Arch-based update checks require `checkupdates`, while Pacman itself remains usable by other LAC functions without that helper. Pacman cache cleanup additionally uses `paccache`.

## Distribution detection

LAC reads `/etc/os-release`. Known base distributions are mapped directly, while derivatives can inherit support through `ID_LIKE`:

| Distribution family | Package manager |
|---|---|
| Debian / Ubuntu | APT |
| Fedora / RHEL / CentOS | DNF |
| Arch | Pacman |
| openSUSE / SLES / SUSE | Zypper |

The multi-distribution CI verifies this mapping on Debian stable, Fedora, Arch Linux and openSUSE Tumbleweed in addition to the full Ubuntu regression run.

## Installation

Clone the repository and install LAC system-wide:

```bash
git clone git@github.com:sunlover83/LinuxAdminCenter.git
cd LinuxAdminCenter
sudo ./install.sh
```

The default installation creates:

```text
/usr/local/bin/lac
/usr/local/bin/lac-uninstall
/usr/local/lib/linux-admin-center/
/usr/local/share/linux-admin-center/
/usr/local/share/doc/linux-admin-center/
```

After installation, LAC can be started from anywhere:

```bash
lac
lac --version
lac --self-check
```

Update an installed copy by updating the repository and running the installer again:

```bash
git switch main
git pull --ff-only
sudo ./install.sh
```

Remove the installed application with:

```bash
sudo lac-uninstall
```

The uninstaller deliberately preserves `/etc/lac` and user configuration under `$HOME/.config/lac`.

The installer supports a custom absolute prefix:

```bash
sudo ./install.sh --prefix /opt/lac
```

For packaging and staged installations, the conventional `DESTDIR` variable is supported:

```bash
DESTDIR=/tmp/lac-package-root ./install.sh --prefix /usr
```

Unsafe installation targets are rejected before file operations. Relative paths, filesystem-root targets and `.` / `..` path components are not accepted for the protected prefix/staging values.

Distribution-specific `.deb`, `.rpm` or similar package files are not yet provided in 1.0.0. The installation layout and `DESTDIR` support are intended as the foundation for those formats.

## Usage

Start an installed LAC:

```bash
lac
```

During development, LAC can still be started directly from the repository:

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
-S, --self-check             Check the LAC runtime and dependencies
-u, --check-updates          Check for available updates
-c, --cleanup-report         Show a read-only cleanup report
```

The LAC Self Check is completely read-only. It verifies the active Bash version, installation type, the complete runtime tree, installed launchers, configuration readability, required core commands, optional diagnostic tools and the detected package manager. Missing optional diagnostic tools are reported but do not reduce the overall status. Missing runtime files, unsupported Bash versions or incomplete system-wide launchers produce `failed`; missing core tools, unreadable configuration or an unavailable package manager produce `warning`.

The update check returns status `10` when updates are available. This allows scripts to distinguish available updates from execution errors.

The cleanup report never changes the system. Destructive cleanup actions are available only in the interactive menu and require explicit confirmation.

Hardware diagnostics are read-only. CPU, GPU and storage information is displayed only when the required tools are available. Drive-health checks may require root privileges; LAC does not request those privileges automatically.

Network diagnostics are also read-only. LAC checks the IPv4 default gateway, DNS resolution and external IP reachability without modifying network interfaces, routes or DNS settings. Configurable test targets are validated before they are passed to `ping` or `getent`. Non-responsive ICMP targets are reported carefully because ping traffic may be blocked even when other network functions work.

The default diagnostic targets can be overridden temporarily:

```bash
LAC_DNS_TEST_HOST=example.org \
LAC_INTERNET_TEST_TARGET=9.9.9.9 \
lac --network-diagnostics
```

Gaming Readiness is the fast compatibility overview. It reports the graphical session, active graphics drivers, Vulkan verification, Steam availability, custom Proton tools and optional gaming utilities. Missing `vulkaninfo` is reported as `not verified`; it is not treated as proof that the Vulkan runtime itself is absent.

Gaming Diagnostics provides a deeper, still read-only compatibility analysis. It reports Vulkan runtime details, detected Vulkan devices and drivers, 32-bit Vulkan support, Steam library roots, installed Proton runtimes, compatibility-prefix counts and gaming integration tools. Native Steam uses conservative host-library checks for 32-bit Vulkan; Flatpak Steam reports this support as managed by Flatpak instead of evaluating host i386 library paths. User-visible Steam and Proton lists use deterministic `C`-locale ordering.

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
2. an explicit `LAC_USER_CONFIG`, otherwise `${XDG_CONFIG_HOME}/lac/lac.conf`, otherwise `$HOME/.config/lac/lac.conf`

If no user configuration path can be constructed because neither the explicit path, `XDG_CONFIG_HOME` nor `HOME` is available, LAC simply keeps its defaults. User settings override system settings.

Currently supported:

```ini
DEBUG=false
```

The installer does not create or overwrite either configuration file. An example is installed at:

```text
/usr/local/share/linux-admin-center/lac.conf.example
```

when the default prefix is used.

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

Run the distribution-independent portability subset:

```bash
bash tests/portability_test.sh
```

Run ShellCheck:

```bash
shellcheck install.sh uninstall.sh src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

GitHub Actions runs the complete test suite and ShellCheck on Ubuntu for pull requests and pushes to `main`. A separate portability matrix runs Bash syntax checks, validates the actual container distribution/package-manager mapping, and executes distribution-independent configuration, installation, network-hardening, package-manager and Self Check tests inside Debian stable, Fedora, Arch Linux and openSUSE Tumbleweed containers.

Test fixtures use neutral example values. Personal home paths, hostnames and real development-machine hardware fingerprints are intentionally not used as fixtures or documentation examples.

## Project structure

```text
.github/workflows/                  Automated quality and portability checks
install.sh                          System installation and staged packaging
uninstall.sh                        Safe system removal workflow
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
src/modules/self_check/             LAC runtime and dependency self-check
tests/                              Automated shell and portability tests
docs/                               Project documentation
```

## Roadmap

Version `0.9.0-alpha` introduced a reproducible installation, update and removal workflow with standard Linux filesystem locations and `DESTDIR` support for future packaging.

Version `1.0.0-rc1` established the validated release-candidate baseline for the first stable release, including runtime/deployment hardening, Self Check, cross-distribution portability coverage, code and consistency reviews, neutral test fixtures and real-system validation.

Version `1.0.0` is the first stable release and promotes that validated RC1 baseline without functional feature changes.

Planned areas for later development include:

- Distribution-specific package formats and release automation
- Additional cleanup categories after separate safety reviews
- Further diagnostic modules where they provide clear administrative value

## License

This project is licensed under the MIT License.
