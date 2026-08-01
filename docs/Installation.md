# Installation

## Status

Linux Admin Center befindet sich in einer Alpha-Phase. Es gibt derzeit noch kein Distributionspaket und keinen systemweiten Installer. Die Anwendung wird direkt aus dem Git-Repository gestartet.

## Voraussetzungen

Erforderlich:

- Linux-System
- Bash ab Version 4.3
- Git zum Klonen und Aktualisieren des Repositorys
- Standardprogramme wie `awk`, `sed`, `uname`, `df` und `hostname`
- `ip` für die Netzwerkinformationen
- `sudo` für administrative Updatebefehle
- ein unterstützter Paketmanager

Unterstützte Paketmanager:

- APT
- DNF
- Pacman zusammen mit `checkupdates`
- Zypper

Optional für vollständigere Informationen:

- `lscpu` für das CPU-Modell
- `lspci` für Grafikkarten
- `nvidia-smi` als zusätzliche NVIDIA-Erkennung
- `resolvectl` für DNS-Informationen
- ShellCheck für die Entwicklung

Verfügbarkeit prüfen:

```bash
bash --version
command -v git
command -v ip
command -v sudo
```

Für die Entwicklung zusätzlich:

```bash
command -v shellcheck
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
git pull
```

Danach erneut prüfen:

```bash
bash tests/run_tests.sh
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
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
