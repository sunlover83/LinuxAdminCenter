# Changelog

All notable changes to Linux Admin Center are documented in this file.

The format is based on Keep a Changelog. The project currently follows an early alpha development model.

## [Unreleased]

No changes yet.

## [0.7.0-alpha] - 2026-08-05

### Added

- Interactive Service Health module
- Read-only service report through `-e` and `--service-health`
- Init-system detection with explicit systemd support
- Systemd system-state reporting
- Active, inactive and failed service counts
- Failed-service listing and detailed unit information
- Total boot-time reporting through `systemd-analyze time`
- Slowest-service reporting through `systemd-analyze blame`
- Overall service assessment using `healthy`, `warning` and `failed`
- Explanatory messages for healthy, degraded, failed and unsupported states
- Automated tests for service metrics, assessment logic, formatted output, CLI behavior and menu integration

### Changed

- Version and codename updated to `0.7.0-alpha (Services)`
- Main menu extended with Service Health
- CLI help extended with the service health option
- Existing CLI and UI tests now cover the service health module
- README, installation guide, user manual and architecture documentation updated for Service Health

### Security

- Service Health is completely read-only
- LAC does not start, stop, restart, enable, disable or mask services
- LAC does not modify systemd unit files or boot targets
- LAC does not request elevated privileges for service checks
- Service names are validated before detailed information is requested
- Service and boot diagnostics use non-interactive, pageless systemd commands

## [0.6.0-alpha] - 2026-08-05

### Added

- Interactive Gaming Readiness module
- Read-only gaming report through `-g` and `--gaming-readiness`
- Wayland, X11 and desktop-environment detection
- Active graphics-driver reporting through `lspci`
- NVIDIA driver-version reporting through `nvidia-smi`
- Vulkan verification through `vulkaninfo --summary`
- Detection of native and Flatpak Steam installations
- Discovery of custom Proton compatibility tools in native and Flatpak Steam directories
- Availability reporting for GameMode, MangoHud and Gamescope
- Overall gaming assessment using `ready`, `limited` and `incomplete`
- Explanatory messages for missing or unverified core gaming requirements
- Automated tests for gaming metrics, assessment logic, formatted output, CLI behavior and menu integration

### Changed

- Version and codename updated to `0.6.0-alpha (Gaming)`
- Main menu extended with Gaming Readiness
- CLI help extended with the gaming readiness option
- Missing `vulkaninfo` is reported as `not verified` instead of claiming that Vulkan is not installed
- Optional gaming tools are displayed but do not reduce the core readiness assessment
- Existing CLI and UI tests now cover the gaming module

### Security

- Gaming readiness is completely read-only
- LAC does not install packages or change Steam, Proton, graphics-driver or Vulkan settings
- LAC does not enable GameMode, MangoHud or Gamescope automatically
- LAC does not request elevated privileges for gaming checks
- Compatibility-tool discovery is limited to known Steam directories beneath the current user's home directory

## [0.5.0-alpha] - 2026-08-04

### Added

- Interactive network diagnostics module
- Read-only network diagnostics through `-r` and `--network-diagnostics`
- IPv4 default-gateway detection for connectivity tests
- Gateway reachability checks
- DNS resolution checks through `getent`
- External IP reachability checks
- Packet-loss and average-latency reporting
- Availability reporting for `ip`, `ping` and `getent`
- Overall network assessment using `healthy`, `warning` and `failed`
- Explanatory assessment messages for common connectivity states
- Automated tests for network diagnostic metrics, formatted output, CLI behavior and menu integration

### Changed

- Version and codename updated to `0.5.0-alpha (Connectivity)`
- Main menu extended with network diagnostics
- CLI help extended with the network diagnostics option
- Network information and active connectivity tests are kept in separate modules
- Non-responsive ICMP targets are treated as warnings when other connectivity checks succeed
- DNS failures are distinguished from general IP connectivity failures

### Security

- Network diagnostics are read-only
- LAC does not modify interfaces, routes, gateways or DNS configuration
- LAC does not request elevated privileges for network diagnostics
- External tests use a limited number of ICMP packets with explicit timeouts
- Test targets can be overridden through environment variables without changing system configuration

## [0.4.0-alpha] - 2026-08-01

### Added

- Interactive hardware diagnostics module
- Read-only hardware diagnostics through `-d` and `--hardware-diagnostics`
- CPU temperature detection through `sensors`
- NVIDIA GPU temperature, utilization and memory reporting through `nvidia-smi`
- Physical storage-device detection including device models
- SMART health checks for SATA and other supported block devices
- NVMe health checks through `nvme smart-log`
- Automated tests for hardware metrics, diagnostic output and menu integration

### Changed

- Version and codename updated to `0.4.0-alpha (Diagnostics)`
- Main menu extended with hardware diagnostics
- CLI help extended with the hardware diagnostics option
- CPU temperatures are formatted to one decimal place
- Virtual ZRAM devices and zero-size storage devices are excluded from storage diagnostics
- Missing diagnostic tools and unavailable measurements are reported explicitly

### Security

- Hardware diagnostics are read-only
- LAC does not request elevated privileges automatically for drive-health checks
- Drive-health checks without sufficient privileges report `requires root`
- Empty card readers and virtual ZRAM devices are not passed to drive-health tools

## [0.3.0-alpha] - 2026-08-01

### Added

- Interactive system cleanup menu
- Read-only cleanup report through `-c` and `--cleanup-report`
- Package-cache size detection
- System journal disk-usage reporting
- Review and removal workflow for packages classified as no longer required
- Package-cache cleanup for APT, DNF, Pacman and Zypper
- Cleanup tests covering all supported package managers

### Changed

- Version and codename updated to `0.3.0-alpha (Cleanup)`
- Main menu extended with the system cleanup module
- Package-manager abstraction extended with cleanup operations
- Pacman cache cleanup retains the two newest cached versions

### Security

- Cleanup reports are read-only
- Package-cache cleanup requires interactive confirmation
- Package removal requires entering the exact word `REMOVE`
- Journal files and package repository metadata are not deleted

## [0.2.0-alpha] - 2026-08-01

### Added

- Complete German architecture documentation
- Complete German user manual
- Complete German developer guide
- Installation and update documentation
- GitHub Actions workflow for automated tests and ShellCheck
- Project-wide ShellCheck configuration for sourced files
- Dedicated network information module and CLI option
- Network interface, IPv4 address, gateway and DNS detection
- System resource information for CPU, GPU, memory, disk, load and uptime
- CLI options for help, version, system information, network information and update checks
- Configuration loading from system-wide and user-specific files
- Debug logging support
- Automated tests for CLI behavior, configuration, package managers, system information and network metrics
- Package-manager abstraction for APT, DNF, Pacman and Zypper
- Interactive update checking and installation
- Restart-requirement detection

### Changed

- Version and codename updated to `0.2.0-alpha (Consolidation)`
- General system information and network information are now shown separately
- README updated to describe the current feature set, documentation and quality checks
- Refactored the initial application into shared core components and feature modules
- Improved update-check error handling
- Improved CPU and GPU detection
- Strengthened APT command availability checks

### Fixed

- System information tests now explicitly load the system metrics they use
- System information tests verify that network details are not duplicated
- Minor update-module formatting issue

### Removed

- Empty duplicate English documentation placeholders
- Unused color constant

## [0.1.0-alpha] - 2026-07-25

### Added

- Initial project structure
- Main Bash entry point
- Shared UI and common modules
- Development-editor configuration
- MIT license
