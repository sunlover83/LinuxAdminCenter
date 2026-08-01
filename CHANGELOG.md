# Changelog

All notable changes to Linux Admin Center are documented in this file.

The format is based on Keep a Changelog. The project currently follows an early alpha development model.

## [Unreleased]

### Added

- Dedicated network information module and CLI option
- Network interface, IPv4 address, gateway and DNS detection
- System resource information for CPU, GPU, memory, disk, load and uptime
- CLI options for help, version, system information and update checks
- Configuration loading from system-wide and user-specific files
- Debug logging support
- Automated tests for CLI behavior, configuration, package managers, system information and network metrics
- Package-manager abstraction for APT, DNF, Pacman and Zypper
- Interactive update checking and installation
- Restart-requirement detection

### Changed

- Refactored the initial application into shared core components and feature modules
- Improved update-check error handling
- Improved CPU and GPU detection

## [0.1.0-alpha] - 2026-07-25

### Added

- Initial project structure
- Main Bash entry point
- Shared UI and common modules
- Development-editor configuration
- MIT license
