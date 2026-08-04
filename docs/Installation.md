# Installation

## Status

Linux Admin Center befindet sich in einer Alpha-Phase. Es gibt derzeit noch kein Distributionspaket und keinen systemweiten Installer. Die Anwendung wird direkt aus dem Git-Repository gestartet.

## Voraussetzungen

Erforderlich:

- Linux-System
- Bash ab Version 4.3
- Git zum Klonen und Aktualisieren des Repositorys
- Standardprogramme wie `awk`, `sed`, `uname`, `df`, `du` und `hostname`
- `ip` für Netzwerkinformationen und Gateway-Erkennung
- `ping` für Gateway- und Internet-Erreichbarkeitstests
- `getent` für die DNS-Auflösungsprüfung
- `sudo` für administrative Update- und Cleanup-Befehle
- ein unterstützter Paketmanager

Unterstützte Paketmanager:

- APT
- DNF
- Pacman zusammen mit `checkupdates`
- Zypper

Für die vollständige Cleanup-Funktion auf Arch-basierten Systemen wird außerdem `paccache` benötigt. Es ist Bestandteil des Pakets `pacman-contrib`.

```bash
sudo pacman -S pacman-contrib
```

Optional für vollständigere Informationen:

- `lscpu` für das CPU-Modell
- `lspci` für Grafikkarten
- `lm-sensors` beziehungsweise `sensors` für CPU-Temperaturen
- `nvidia-smi` für NVIDIA-GPU-Diagnosedaten
- `smartmontools` beziehungsweise `smartctl` für SMART-Laufwerksprüfungen
- `nvme-cli` beziehungsweise `nvme` für NVMe-Gesundheitsdaten
- `resolvectl` für DNS-Informationen
- `journalctl` für die Anzeige der Journalbelegung
- ShellCheck für die Entwicklung

Auf Debian, Ubuntu und Pop!_OS können die Diagnosewerkzeuge installiert werden mit:

```bash
sudo apt install lm-sensors smartmontools nvme-cli
```

Verfügbarkeit prüfen:

```bash
bash --version
command -v git
command -v ip
command -v ping
command -v getent
command -v sudo
command -v du
command -v sensors
command -v nvidia-smi
command -v smartctl
command -v nvme
command -v lsblk
```

Für die Entwicklung zusätzlich:

```bash
command -v shellcheck
```

Auf Arch-basierten Systemen:

```bash
command -v checkupdates
command -v paccache
```

## Repository klonen

Empfohlener Projektpfad:

```bash
mkdir -p ~/Projekte
cd ~/Projekte
```

Klonen per SSH:

```bash
git clone git@github.com:sunlover83/LinuxAdminCenter.git
```

Alternativ per HTTPS:

```bash
git clone https://github.com/sunlover83/LinuxAdminCenter.git
```

Da das Repository privat ist, muss das verwendete GitHub-Konto Zugriff besitzen. Bei SSH muss außerdem ein passender SSH-Schlüssel im GitHub-Konto hinterlegt sein.

## Ausführungsrechte setzen

```bash
cd ~/Projekte/LinuxAdminCenter
chmod +x src/lac.sh
chmod +x tests/*.sh
```

## Installation prüfen

Version anzeigen:

```bash
./src/lac.sh --version
```

Hilfe anzeigen:

```bash
./src/lac.sh --help
```

Schreibgeschützten Cleanup-Bericht anzeigen:

```bash
./src/lac.sh --cleanup-report
```

Netzwerkdiagnose anzeigen:

```bash
./src/lac.sh --network-diagnostics
```

Hardwarediagnose anzeigen:

```bash
./src/lac.sh --hardware-diagnostics
```

Interaktives Menü starten:

```bash
./src/lac.sh
```

## Konfiguration

### Benutzerkonfiguration

```bash
mkdir -p ~/.config/lac
cat > ~/.config/lac/lac.conf <<'EOF'
DEBUG=false
EOF
```

### Systemweite Konfiguration

```bash
sudo mkdir -p /etc/lac
sudo tee /etc/lac/lac.conf >/dev/null <<'EOF'
DEBUG=false
EOF
```

Die Benutzerkonfiguration überschreibt die systemweite Konfiguration.

## Funktionstest

Alle Tests ausführen:

```bash
bash tests/run_tests.sh
```

ShellCheck ausführen:

```bash
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

## Anwendung aktualisieren

```bash
cd ~/Projekte/LinuxAdminCenter
git switch main
git pull --ff-only
```

Danach erneut prüfen:

```bash
bash tests/run_tests.sh
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
./src/lac.sh --cleanup-report
./src/lac.sh --network-diagnostics
./src/lac.sh --hardware-diagnostics
```

## Anwendung entfernen

Da aktuell keine systemweite Installation erfolgt, genügt das Löschen des Projektverzeichnisses:

```bash
rm -rf ~/Projekte/LinuxAdminCenter
```

Optional können die Konfigurationsdateien entfernt werden:

```bash
rm -rf ~/.config/lac
sudo rm -rf /etc/lac
```

Vor dem Löschen sollte geprüft werden, ob sich im Projektverzeichnis noch nicht übertragene eigene Änderungen befinden:

```bash
cd ~/Projekte/LinuxAdminCenter
git status
```
