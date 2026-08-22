# Changelog

All notable changes to Linux Admin Center are documented in this file.

The format is based on Keep a Changelog. Release candidates use semantic pre-release versioning before the stable 1.0 release.

## [Unreleased]

No changes yet.

## [1.3.0-alpha1] - 2026-08-22

### Added

- Portable local-filesystem collector using deterministic GNU `df` output for capacity and inode metrics
- Read-only Storage Analysis report with per-filesystem and overall `healthy`, `warning`, `critical` and `incomplete` assessments
- `-s` and `--storage-analysis` CLI options plus interactive menu integration
- Automated Storage Analysis tests covering ext4, XFS, Btrfs, vfat, LUKS/LVM-style sources, filtering, missing inode data, error handling and threshold boundaries

### Changed

- Version and codename updated to `1.3.0-alpha1 (Storage Analysis)`
- Debian package version updated to `1.3.0~alpha1-1`
- LAC Self Check, manual installation and Debian package tests include the Storage Analysis runtime files and installed CLI path
- Debian, Fedora, Arch Linux and openSUSE portability selection now includes the storage metric and assessment tests
- README, user manual, architecture, developer guidance and `lac(1)` document Storage Analysis behavior, portability and interpretation

### Validation

- Storage metrics use neutral mocked fixtures alongside installed-runtime checks against the local `df` implementation
- CLI, menu, Self Check, manual installation and Debian package expectations cover the complete Storage Analysis runtime path
- Release metadata validation covers the `1.3.0-alpha1` runtime, Debian package, changelog and manpage contract

### Security

- Storage Analysis is strictly read-only, uses no `sudo` or modifying storage commands, and is separated from confirmed System Cleanup actions and any future storage-maintenance feature
- Pseudo-filesystems, remote mounts, known read-only image filesystems and selected virtual FUSE mounts are excluded from the capacity assessment

## [1.2.0] - 2026-08-16

### Changed

- Version and codename promoted to `1.2.0 (Release Automation)`
- Debian package version promoted to `1.2.0-1`
- Stable release promotes the validated `1.2.0-alpha2` release-automation baseline without functional runtime changes
- README, installation guidance and release-automation documentation now describe the completed stable release

### Validation

- The real `v1.2.0-alpha2` release completed the full release workflow, including tests, Debian package build and lifecycle validation, Lintian, ShellCheck, asset preparation, publication and post-publication verification
- The published `linux-admin-center_1.2.0-alpha2-1_all.deb` digest matched `SHA256SUMS`, while the package retained the internal Debian version `1.2.0~alpha2-1`
- The published Alpha2 package was downloaded and installed successfully through APT on Pop!_OS; its runtime reported the expected version and the packaged Self Check completed with status `healthy`
- Existing stable-release metadata, asset-name preservation and GitHub `Latest` behavior remain covered by the release test and workflow contracts

## [1.2.0-alpha2] - 2026-08-16

### Added

- Dedicated release-asset preparation test covering prerelease filename normalization and stable filename preservation
- Active post-publication verification of the exact GitHub release asset names and prerelease state

### Changed

- Version and codename promoted to `1.2.0-alpha2 (Release Automation)`
- Debian package version promoted to `1.2.0~alpha2-1`
- Prerelease Debian package files are renamed only for GitHub publication, for example from `linux-admin-center_1.2.0~alpha2-1_all.deb` to `linux-admin-center_1.2.0-alpha2-1_all.deb`
- `SHA256SUMS` is now generated after release-asset filename normalization and therefore references the exact published download name
- Generated release notes now list the GitHub-safe published package name rather than the internal Debian build filename

### Fixed

- The first real `v1.2.0-alpha1` release exposed GitHub's normalization of `~` in uploaded asset filenames, which caused the published package name to differ from both `SHA256SUMS` and the generated release notes
- Direct `sha256sum -c SHA256SUMS` verification of downloaded prerelease assets is restored by normalizing the filename before checksum generation and upload

### Validation

- Release-asset tests verify that prerelease `~` filenames become deterministic `-` filenames while stable package filenames remain unchanged
- Release-note tests verify that prerelease notes contain the published filename and never expose the GitHub-unsafe `~` build filename
- Workflow-invariant tests require release-asset preparation before publication and reject the previous pre-normalization checksum command
- Post-publication workflow verification now fails if the expected package asset, `SHA256SUMS`, exact asset count or prerelease state differs from the prepared release

## [1.2.0-alpha1] - 2026-08-15

### Added

- Tag-triggered GitHub Actions release workflow for automated package publication
- Release metadata validation across Git tag, runtime version, Debian version, project changelog and manpage
- Automatic release-note generation from the matching `CHANGELOG.md` section
- Automatic `SHA256SUMS` generation for the published Debian package
- Release automation tests for metadata contracts, release-note extraction and workflow safety invariants
- Dedicated release automation documentation

### Changed

- Version and codename updated to `1.2.0-alpha1 (Release Automation)`
- Debian package version updated to `1.2.0~alpha1-1`
- Release publication now repeats the full regression suite, Debian package build validation, APT/dpkg lifecycle validation, Lintian and ShellCheck before creating a GitHub Release
- Semantic pre-release tags are published as GitHub pre-releases and are not marked as `Latest`
- Stable releases remain eligible to become the GitHub `Latest` release

### Validation

- Release metadata fixture tests cover matching stable and pre-release versions plus deliberate tag, runtime, Debian, changelog and manpage mismatches
- Release-note tests verify that only the requested changelog section is published
- Workflow-invariant tests verify least-privilege permissions, exact-main tag checks, package lifecycle validation, checksum generation and `--verify-tag`
- The release automation foundation completed the full GitHub quality and portability matrix after resolving the initial ShellCheck formatting finding

### Security

- Release tags must already exist and must point to the exact current `main` commit before publication
- `gh release create --verify-tag` prevents the workflow from silently creating a missing tag
- Workflow-wide permissions remain `contents: read`; only the release job receives `contents: write`
- Release automation never deletes, moves or repairs a Git tag automatically after a validation failure

## [1.1.0] - 2026-08-15

### Added

- Architecture-independent Debian/Ubuntu package `linux-admin-center_1.1.0-1_all.deb`
- Debian package metadata and build rules under `debian/`
- `lac(1)` manual page for package-managed installations
- Package marker used by the LAC Self Check to identify Debian package installations
- Safe pre-installation detection of conflicting manual LAC installations under `/usr/local`
- Reusable `scripts/build_debian_package.sh` helper for local and CI package builds
- Dedicated Debian/Ubuntu packaging documentation
- Automated Debian package build validation
- Automated APT/dpkg lifecycle validation in a clean Debian stable container
- Lintian validation with Error and Warning findings treated as failures
- GitHub Actions upload of the validated `.deb` as a workflow artifact

### Changed

- Version and codename promoted to `1.1.0 (Packaging)`
- Debian package version promoted to `1.1.0-1`
- Package-managed installations use `/usr` and are removed exclusively through APT/dpkg
- Package-managed installations intentionally omit `lac-uninstall`
- Self Check now distinguishes Debian package installations from manual system-wide installs and validates the appropriate launcher set
- Debian package builds reuse the existing `DESTDIR` installer with `/usr` as the package prefix
- Debian package builds respect `DEB_BUILD_OPTIONS=nocheck` so CI can avoid redundant execution of the full test suite
- README and installation documentation now describe both package-managed and manual installation paths
- Migration documentation now includes `hash -r` for already-running Bash sessions that cached the former `/usr/local/bin/lac` path

### Validation

- Package build, extraction, metadata, runtime contents, package marker, version output and Self Check are validated automatically
- APT lifecycle validation covers manual-install conflict detection, package install, reinstall, execution, Self Check, removal and configuration preservation
- Lintian completes without Error or Warning findings after documented package-specific overrides
- ShellCheck covers the Debian maintainer script and reusable package build helper
- Existing Debian stable, Fedora, Arch Linux and openSUSE Tumbleweed portability jobs remain green
- The `1.1.0-alpha1` package lifecycle was additionally validated on a real APT-based desktop system, including migration from the manual 1.0.0 installation, healthy package Self Check, removal/reinstallation and preservation of user configuration

### Security

- The package never deletes an existing manual `/usr/local` installation automatically
- Package installation aborts before unpacking if a conflicting manual LAC installation is detected
- Existing `/etc/lac` and user configuration remain outside package-managed runtime files and are preserved during migration, reinstall and normal package removal
- Package removal stays under APT/dpkg control instead of exposing a separate package uninstaller

## [1.0.0] - 2026-08-15

### Changed

- Version and codename promoted to `1.0.0 (Stable)`
- Stable release promotes the validated `1.0.0-rc1` baseline without functional runtime changes
- CLI version regression tests now require the stable version string
- README and installation documentation now describe `1.0.0 (Stable)` as the current release

### Validation

- The RC1 baseline completed the full automated quality and portability matrix, installation lifecycle validation and subsequent normal-use testing without observed release-blocking defects before stable promotion

## [1.0.0-rc1] - 2026-08-08

### Added

- Read-only LAC Self Check through `-S` and `--self-check`
- Interactive `LAC Self Check` menu entry
- Self Check reporting for Bash compatibility, installation type, runtime files, launchers and configuration handling
- Required core-tool and optional diagnostic-tool availability reporting
- Detected package-manager availability in Self Check
- Overall Self Check assessment using `healthy`, `warning` and `failed`
- Automated tests for Self Check metrics, assessment logic, formatted output, CLI behavior and menu integration
- Installation of the MIT license alongside system documentation
- Distribution-independent portability test runner with project-wide Bash syntax validation
- GitHub Actions portability coverage for Debian stable, Fedora, Arch Linux and openSUSE Tumbleweed
- Common runtime tests for the Bash minimum version and package-manager family mapping through `ID` and `ID_LIKE`
- Configuration tests for explicit, XDG, HOME and HOME-less user configuration environments
- Package-manager capability tests that distinguish base Pacman support from the optional `checkupdates` update helper

### Changed

- Version and codename updated to `1.0.0-rc1 (Stable)`
- Repository `install.sh` and `uninstall.sh` are executable after a fresh checkout
- CLI help now documents the installed `lac` command instead of the repository entry-point name
- Self Check verifies the complete set of Core and module files sourced by the runtime
- Self Check now lists the actual core runtime dependencies including `find`, `sort` and `tr`, and reports additional feature-specific tools such as `lsblk`, `checkupdates` and `paccache`
- Ubuntu remains the full regression and ShellCheck environment while other Linux families run a focused portability suite for configuration, installation, network-target hardening, package-manager abstraction and Self Check behavior
- Portability jobs verify the actual container distribution and the package manager selected by LAC
- LAC enforces the documented Bash 4.3 minimum before loading the remaining runtime modules
- Distribution detection now uses `ID_LIKE` as a fallback instead of hard-coding individual distribution derivatives
- Base package-manager availability is separated from update-specific helper requirements
- Pacman remains a supported package manager when `checkupdates` is absent; only update functionality is then reported as unavailable
- Gaming compatibility-tool and Proton-runtime ordering is explicitly locale-independent with `LC_ALL=C`
- Service Health presentation code no longer contains an unused duplicate formatter
- Hardware metrics formatting and project documentation were normalized during the 1.0 code review
- Machine-specific test fixtures and personal development-path examples were replaced by neutral, plausible values
- Feature scope is frozen for RC1; subsequent pre-1.0 changes are limited to release blockers, validation findings and release documentation

### Fixed

- Restored the complete MIT license text in the previously empty `LICENSE` file
- User configuration discovery no longer assumes that `HOME` is always set under strict `set -u` execution

### Security

- Installer and uninstaller reject `PREFIX` and `DESTDIR` values containing `.` or `..` path components
- `DESTDIR=/` is rejected so staging cannot bypass normal system-install privilege handling
- Configurable network diagnostic targets reject option-like values and whitespace before being passed to `ping` or `getent`
- Self Check is completely read-only and does not install, remove or repair dependencies
- Test and documentation fixtures no longer expose the development machine's hardware profile, desktop environment or personal project-directory convention

## [0.9.0-alpha] - 2026-08-07

### Added

- System-wide installation through `install.sh`
- Safe removal through `uninstall.sh`
- Installed `lac` launcher for normal application use
- Installed `lac-uninstall` launcher so the repository is not required for removal
- Standard installation layout under `/usr/local/bin`, `/usr/local/lib` and `/usr/local/share`
- Configurable absolute installation prefix through `--prefix`
- Conventional `DESTDIR` staging support for tests and future package creation
- Installation of the example configuration and project documentation
- Automated installation, reinstallation and uninstallation tests
- Verification that the installed launcher executes the installed runtime

### Changed

- Version and codename updated to `0.9.0-alpha (Deployment)`
- Reinstalling LAC now replaces the previous runtime tree so removed source files cannot remain stale
- Installer and uninstaller are now included in ShellCheck quality checks
- README and installation documentation now describe the installed `lac` command as the normal usage path
- Project documentation now distinguishes system installation from future distribution-specific package formats

### Security

- Real system installation and removal require explicit root execution; the scripts never invoke `sudo` automatically
- `PREFIX` and `DESTDIR` must be absolute paths
- `PREFIX=/` is rejected to prevent unsafe installation or removal targets
- Recursive removal is guarded by expected LAC-specific path suffixes
- Uninstallation removes only LAC launchers, runtime files, shared files and installed documentation
- `/etc/lac` and user configuration under `$HOME/.config/lac` are deliberately preserved
- The installer does not create or overwrite active configuration files

## [0.8.0-alpha] - 2026-08-07

### Added

- Interactive Gaming Diagnostics module alongside the existing Gaming Readiness quick check
- Read-only detailed gaming diagnostics through `-G` and `--gaming-diagnostics`
- Vulkan instance-version reporting through `vulkaninfo --summary`
- Vulkan device, driver and API-version reporting
- Conservative verification of common native 32-bit Vulkan loader locations
- Flatpak-aware 32-bit graphics-support reporting
- Native Steam executable and Flatpak Steam launch-target reporting
- Steam library discovery from known locations and `libraryfolders.vdf`
- Detection of bundled Proton runtimes in Steam libraries
- Reuse of custom Proton compatibility-tool discovery
- Unique Steam compatibility-prefix counting across libraries
- Availability reporting for GameMode, MangoHud, MangoApp and Gamescope
- Gamescope version reporting through `gamescope --version`
- Overall gaming-diagnostics assessment using `healthy`, `warning` and `incomplete`
- Automated tests for diagnostic metrics, Flatpak handling, formatted output, CLI behavior and menu integration

### Changed

- Version and codename updated to `0.8.0-alpha (Compatibility)`
- Main menu extended with Gaming Diagnostics
- CLI help extended with the gaming diagnostics option
- Gaming Readiness remains a separate fast prerequisite check while Gaming Diagnostics provides deeper compatibility information
- Equivalent native Steam roots are canonicalized before library results are deduplicated
- Flatpak Steam no longer receives a warning merely because host 32-bit Vulkan loader files cannot be found
- README, installation guide, user manual and architecture documentation updated for Gaming Diagnostics

### Security

- Gaming Diagnostics is completely read-only
- LAC does not launch games or compatibility tools during diagnostics
- LAC does not change Steam, Proton, Vulkan, driver or performance settings
- LAC does not execute active GameMode performance tests such as `gamemoded -t`
- LAC does not request elevated privileges for gaming diagnostics
- Steam filesystem discovery is limited to known Steam roots and library paths explicitly listed by Steam
- Gamescope is queried only for version information

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
