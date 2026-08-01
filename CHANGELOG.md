# Changelog

All notable changes to Linux Admin Center are documented in this file.

The format is based on Keep a Changelog. The project currently follows an early alpha development model.

## [Unreleased]

No changes yet.

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
