# Installation

## Status

Ab Version `0.9.0-alpha` kann Linux Admin Center systemweit installiert, aktualisiert und wieder entfernt werden. Die Installation verwendet standardmäßig `/usr/local` und stellt anschließend die Befehle `lac` und `lac-uninstall` bereit.

Der aktuelle Stand ist `1.0.0 (Stable)`. Es gibt weiterhin noch keine distributionsspezifischen Pakete wie `.deb`, `.rpm` oder Arch-Pakete. Der Installer verwendet jedoch ein klassisches Linux-Verzeichnislayout und unterstützt `DESTDIR`, sodass spätere Paketformate darauf aufbauen können.

## Voraussetzungen

Erforderlich:

- Linux-System
- Bash ab Version 4.3
- Git zum Klonen und Aktualisieren des Repositorys
- Standardprogramme wie `awk`, `sed`, `find`, `sort`, `tr`, `cp`, `rm`, `uname`, `df`, `du` und `hostname`
- `ip` für Netzwerkinformationen und Gateway-Erkennung
- `ping` für Gateway- und Internet-Erreichbarkeitstests
- `getent` für die DNS-Auflösungsprüfung
- `sudo` für die systemweite Installation sowie administrative Update- und Cleanup-Befehle
- ein unterstützter Paketmanager

Unterstützte Paketmanager:

- APT
- DNF
- Pacman
- Zypper

Für Update-Prüfungen auf Arch-basierten Systemen wird zusätzlich `checkupdates` benötigt. Für die vollständige Cleanup-Funktion wird außerdem `paccache` benötigt. Beide Programme sind Bestandteil des Pakets `pacman-contrib`.

```bash
sudo pacman -S pacman-contrib
```

Service Health benötigt für die vollständige Auswertung ein systemd-System mit:

- `systemctl` für Systemzustand, Dienstlisten und Unit-Details
- `systemd-analyze` für Startzeit und langsame Dienste

Auf nicht-systemd-basierten Systemen startet LAC weiterhin, meldet Service Health jedoch als nicht unterstützt.

Optional für vollständigere Informationen und Diagnosen:

- `lscpu` für das CPU-Modell
- `lspci` für Grafikkarten und aktive Grafiktreiber
- `lsblk` für die Laufwerkserkennung
- `lm-sensors` beziehungsweise `sensors` für CPU-Temperaturen
- `nvidia-smi` für NVIDIA-GPU-Diagnosedaten und die NVIDIA-Treiberversion
- `smartmontools` beziehungsweise `smartctl` für SMART-Laufwerksprüfungen
- `nvme-cli` beziehungsweise `nvme` für NVMe-Gesundheitsdaten
- `resolvectl` für DNS-Informationen
- `journalctl` für die Anzeige der Journalbelegung
- `vulkaninfo` für Vulkan-Prüfung und detaillierte Vulkan-Diagnosen
- Steam als nativer Befehl oder Flatpak-Anwendung
- `gamemoderun` für die GameMode-Erkennung
- `mangohud` für die MangoHud-Erkennung
- `mangoapp` für die MangoApp-Erkennung bei Gamescope-Setups
- `gamescope` für Gamescope-Erkennung und Versionsabfrage
- ShellCheck für die Entwicklung

Fehlt `vulkaninfo`, funktionieren Gaming Readiness und Gaming Diagnostics weiterhin. Vulkan wird dann vorsichtig als `not verified` ausgegeben. Gaming Diagnostics kann in diesem Fall keine Vulkan-Geräte- oder API-Details anzeigen.

Bei nativer Steam-Installation prüft Gaming Diagnostics typische Pfade auf einen 32-Bit-Vulkan-Loader. Ein Ergebnis `not verified` bedeutet nur, dass LAC an diesen bekannten Orten keinen Loader gefunden hat. Bei Flatpak-Steam wird die 32-Bit-Grafikunterstützung als von Flatpak verwaltet ausgewiesen, statt Host-i386-Pfade zu bewerten.

Auf Debian- und Ubuntu-basierten Systemen können die Hardwarediagnosewerkzeuge beispielsweise installiert werden mit:

```bash
sudo apt install lm-sensors smartmontools nvme-cli
```

## Repository klonen

Ein möglicher Projektpfad ist:

```bash
mkdir -p ~/projects
cd ~/projects
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

Danach in das Repository wechseln:

```bash
cd ~/projects/LinuxAdminCenter
```

## Systemweite Installation

Die Standardinstallation erfolgt nach `/usr/local`:

```bash
sudo ./install.sh
```

Der Installer kopiert ausschließlich die für LAC vorgesehenen Laufzeit-, Dokumentations- und Hilfsdateien. Er installiert keine Betriebssystempakete und verändert keine aktive LAC-Konfiguration.

### Standardpfade

Nach einer Standardinstallation existieren folgende Bereiche:

| Pfad | Zweck |
|---|---|
| `/usr/local/bin/lac` | normaler Programmstart |
| `/usr/local/bin/lac-uninstall` | systemweite Deinstallation |
| `/usr/local/lib/linux-admin-center/` | Laufzeitdateien aus `src/` |
| `/usr/local/share/linux-admin-center/` | Beispielkonfiguration und installierter Uninstaller |
| `/usr/local/share/doc/linux-admin-center/` | README, Changelog, Lizenz und Projektdokumentation |

Die Beispielkonfiguration liegt bei Standardinstallation unter:

```text
/usr/local/share/linux-admin-center/lac.conf.example
```

Der Installer erstellt bewusst keine `/etc/lac/lac.conf` und überschreibt auch keine bereits vorhandene Konfiguration.

## Installation prüfen

Version anzeigen:

```bash
lac --version
```

Erwartete Ausgabe für die stabile Version:

```text
Linux Admin Center 1.0.0 (Stable)
```

LAC selbst prüfen:

```bash
lac --self-check
```

Der Self Check kontrolliert unter anderem Bash-Version, Runtime-Dateien, Launcher, Konfigurationszugriff, Kernwerkzeuge und den erkannten Paketmanager. Fehlende optionale Diagnosewerkzeuge werden angezeigt, verschlechtern den Gesamtstatus aber nicht.

Hilfe anzeigen:

```bash
lac --help
```

Interaktives Menü starten:

```bash
lac
```

Einzelne Funktionen prüfen:

```bash
lac --system-info
lac --network-info
lac --network-diagnostics
lac --hardware-diagnostics
lac --gaming-readiness
lac --gaming-diagnostics
lac --service-health
lac --self-check
lac --cleanup-report
```

## Benutzerdefiniertes Installationspräfix

Mit `--prefix` kann ein anderes absolutes Ziel gewählt werden:

```bash
sudo ./install.sh --prefix /opt/lac
```

Dann werden beispielsweise folgende Befehle erzeugt:

```text
/opt/lac/bin/lac
/opt/lac/bin/lac-uninstall
```

Bei einem benutzerdefinierten Präfix muss dessen `bin`-Verzeichnis gegebenenfalls zusätzlich in `PATH` aufgenommen werden.

Relative Präfixe, `PREFIX=/` sowie Präfixe mit `.`- oder `..`-Pfadkomponenten werden aus Sicherheitsgründen abgelehnt.

## DESTDIR für Paketbau und Tests

Der Installer unterstützt das unter Linux-Paketwerkzeugen übliche `DESTDIR`. Damit werden alle Dateien unter einem vorgeschalteten Zielverzeichnis abgelegt, ohne die endgültigen Laufzeitpfade innerhalb des Pakets zu verändern.

Beispiel:

```bash
DESTDIR=/tmp/lac-package-root \
    ./install.sh --prefix /usr
```

Dabei entstehen unter anderem:

```text
/tmp/lac-package-root/usr/bin/lac
/tmp/lac-package-root/usr/lib/linux-admin-center/
```

`DESTDIR` wird hauptsächlich für automatisierte Tests und spätere Paketformate verwendet. Ist `DESTDIR` gesetzt, verlangt der Installer keine Root-Rechte, da er nicht in das echte Systemziel schreibt. Relative Staging-Pfade, `/` sowie Pfade mit `.`- oder `..`-Komponenten werden abgelehnt.

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

Der Installer und der Uninstaller behandeln diese Konfigurationsdateien als Benutzerdaten. Sie werden bei Installation, Update und Deinstallation nicht verändert oder gelöscht.

## Anwendung aktualisieren

Eine bestehende Installation wird aus dem aktualisierten Repository erneut installiert:

```bash
cd ~/projects/LinuxAdminCenter
git switch main
git pull --ff-only
sudo ./install.sh
```

Die Neuinstallation ersetzt den vorhandenen LAC-Laufzeitbaum vollständig. Dadurch bleiben keine veralteten Dateien zurück, wenn Dateien in einer neuen Version entfernt oder umbenannt wurden.

Konfigurationen unter `/etc/lac` und `$HOME/.config/lac` liegen außerhalb dieses Laufzeitbaums und bleiben erhalten.

Danach prüfen:

```bash
lac --version
lac --self-check
lac --system-info
```

## Anwendung entfernen

Die empfohlene Deinstallation erfolgt über den installierten Befehl:

```bash
sudo lac-uninstall
```

Alternativ kann aus einem weiterhin vorhandenen Repository ausgeführt werden:

```bash
sudo ./uninstall.sh
```

Entfernt werden ausschließlich:

- `lac`
- `lac-uninstall`
- der LAC-Laufzeitbaum
- die installierten Shared-Dateien
- die installierte Dokumentation

Bewusst erhalten bleiben:

- `/etc/lac`
- `$HOME/.config/lac`

Dadurch kann LAC später erneut installiert werden, ohne dass eine vorhandene Konfiguration verloren geht.

Ein mehrfacher Aufruf des Uninstallers ist sicher. Ist LAC bereits entfernt, wird lediglich gemeldet, dass unter dem gewählten Präfix keine Installation vorhanden ist.

## Entwicklung ohne Installation

Für Entwicklung und Tests kann LAC weiterhin direkt aus dem Repository gestartet werden:

```bash
./src/lac.sh
```

Alle Tests ausführen:

```bash
bash tests/run_tests.sh
```

Portabilitätsprüfungen ausführen:

```bash
bash tests/portability_test.sh
```

ShellCheck ausführen:

```bash
shellcheck install.sh uninstall.sh src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

Der Installationstest verwendet ein temporäres `DESTDIR` und verändert das echte System nicht.

## Diagnosewerkzeuge prüfen

Verfügbarkeit wichtiger optionaler Werkzeuge:

```bash
command -v sensors
command -v nvidia-smi
command -v smartctl
command -v nvme
command -v lsblk
command -v lspci
command -v vulkaninfo
command -v steam
command -v flatpak
command -v gamemoderun
command -v mangohud
command -v mangoapp
command -v gamescope
command -v systemctl
command -v systemd-analyze
```

Auf Arch-basierten Systemen zusätzlich:

```bash
command -v checkupdates
command -v paccache
```

Gaming Diagnostics ist vollständig lesend. Zur unabhängigen Kontrolle können einige der zugrunde liegenden Daten betrachtet werden:

```bash
vulkaninfo --summary
gamescope --version
```

Service Health verwendet ausschließlich lesende systemd-Befehle. Die zugrunde liegenden Informationen können unabhängig geprüft werden:

```bash
systemctl is-system-running
systemctl --failed
systemd-analyze time
systemd-analyze blame
```
