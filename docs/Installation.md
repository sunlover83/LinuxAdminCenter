# Installation

## Status

Linux Admin Center kann systemweit installiert, aktualisiert und wieder entfernt werden. Seit Version `1.1.0` stehen dafür zwei unterstützte Wege zur Verfügung:

- Debian-/Ubuntu-Paket über APT/dpkg nach `/usr`
- manuelle Installation über `install.sh` standardmäßig nach `/usr/local`

Der aktuelle Entwicklungsstand ist `1.3.0-alpha2 (Storage Analysis)`. Die neueste stabile Version bleibt `1.2.0 (Release Automation)`. Für Debian-, Ubuntu- und kompatible APT-basierte Systeme steht ein architekturunabhängiges `.deb`-Paket zur Verfügung. Die bisherige manuelle Installation bleibt weiterhin unterstützt.

## Voraussetzungen

Erforderlich:

- Linux-System
- Bash ab Version 4.3
- Standardprogramme wie `awk`, `sed`, `find`, `sort`, `tr`, `cp`, `rm`, `uname`, `df`, `du` und `hostname`
- `ip` für Netzwerkinformationen und Gateway-Erkennung
- `ping` für Gateway- und Internet-Erreichbarkeitstests
- `getent` für die DNS-Auflösungsprüfung
- `sudo` für systemweite Installation sowie administrative Update- und Cleanup-Befehle
- ein unterstützter Paketmanager

Für eine manuelle Installation aus dem Repository wird zusätzlich Git benötigt.

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

## Installation als Debian-/Ubuntu-Paket

Das neueste stabile Paket für Version 1.2.0 heißt:

```text
linux-admin-center_1.2.0-1_all.deb
```

Installation über APT:

```bash
sudo apt install ./linux-admin-center_1.2.0-1_all.deb
```

APT übernimmt dabei Registrierung, Abhängigkeiten und spätere Entfernung des Pakets.

Der aktuelle Quellstand erzeugt für die Alpha2-Validierung lokal stattdessen:

```text
linux-admin-center_1.3.0~alpha2-1_all.deb
```

Bei einer späteren Veröffentlichung wird ausschließlich der GitHub-Assetname als `linux-admin-center_1.3.0-alpha2-1_all.deb` normalisiert. Die internen Paketmetadaten behalten die Debian-Version `1.3.0~alpha2-1`. Bis die Vorabversion ihre Release-Prüfungen abgeschlossen hat, bleibt `1.2.0` die stabile Installationsreferenz.

### Paketpfade

Die paketverwaltete Installation verwendet:

| Pfad | Zweck |
|---|---|
| `/usr/bin/lac` | normaler Programmstart |
| `/usr/lib/linux-admin-center/` | LAC-Laufzeitdateien |
| `/usr/share/linux-admin-center/` | Beispielkonfiguration und Paketmarker |
| `/usr/share/doc/linux-admin-center/` | Dokumentation und Paketinformationen |
| `/usr/share/man/man1/lac.1.gz` | Manpage |

Eine Paketinstallation enthält bewusst **keinen** Befehl `lac-uninstall`. Paketdateien werden ausschließlich über APT beziehungsweise dpkg verwaltet.

### Wechsel von einer manuellen Installation

Eine bisherige Standardinstallation aus `install.sh` liegt unter `/usr/local`. Sie darf nicht parallel zur Paketinstallation bestehen, weil `/usr/local/bin` üblicherweise vor `/usr/bin` im `PATH` liegt.

Das Paket prüft vor dem Entpacken typische LAC-Pfade unter `/usr/local`. Wird dort eine manuelle Installation erkannt, bricht die Paketinstallation mit einer klaren Migrationsanleitung ab und verändert die manuelle Installation nicht.

Die alte Installation entfernen:

```bash
sudo /usr/local/bin/lac-uninstall
```

Die Konfiguration unter `/etc/lac` und `$HOME/.config/lac` bleibt dabei erhalten.

Eine bereits laufende Bash-Sitzung kann den alten Programmpfad `/usr/local/bin/lac` noch zwischengespeichert haben. Deshalb anschließend einmal ausführen:

```bash
hash -r
```

Alternativ kann eine neue Shell geöffnet werden.

Danach das Paket installieren:

```bash
sudo apt install ./linux-admin-center_1.2.0-1_all.deb
```

Anschließend sollte gelten:

```bash
command -v lac
lac --version
lac --self-check
```

Erwartet:

```text
/usr/bin/lac
Linux Admin Center 1.2.0 (Release Automation)
```

Der Self Check muss den Installationstyp `debian-package` erkennen. Auf einem vollständig verfügbaren System sollte der Gesamtstatus `healthy` sein.

### Paket erneut installieren

```bash
sudo apt install --reinstall ./linux-admin-center_1.2.0-1_all.deb
```

Vorhandene aktive LAC-Konfiguration wird dabei nicht überschrieben.

### Paket entfernen

```bash
sudo apt remove linux-admin-center
```

APT entfernt die paketverwalteten Dateien. Bewusst erhalten bleiben:

- `/etc/lac`
- `$HOME/.config/lac`

Dadurch kann LAC später erneut installiert werden, ohne dass die vorhandene Konfiguration verloren geht.

Weitere Details zum Paketbau und zu den automatisierten Paketprüfungen stehen in [Packaging.md](Packaging.md).

## Repository klonen

Dieser Abschnitt ist nur für die manuelle Installation oder Entwicklung erforderlich.

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

## Manuelle systemweite Installation

Die Standardinstallation erfolgt nach `/usr/local`:

```bash
sudo ./install.sh
```

Der Installer kopiert ausschließlich die für LAC vorgesehenen Laufzeit-, Dokumentations- und Hilfsdateien. Er installiert keine Betriebssystempakete und verändert keine aktive LAC-Konfiguration.

### Standardpfade

Nach einer manuellen Standardinstallation existieren folgende Bereiche:

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

Erwartete Ausgabe für den aktuellen Entwicklungsstand:

```text
Linux Admin Center 1.3.0-alpha2 (Storage Analysis)
```

LAC selbst prüfen:

```bash
lac --self-check
```

Der Self Check kontrolliert unter anderem Bash-Version, Installationstyp, Runtime-Dateien, Launcher, Konfigurationszugriff, Kernwerkzeuge und den erkannten Paketmanager. Fehlende optionale Diagnosewerkzeuge werden angezeigt, verschlechtern den Gesamtstatus aber nicht.

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
lac --storage-analysis
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

Dieser Abschnitt gilt für die manuelle Installation.

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

`DESTDIR` wird für automatisierte Tests und den Paketbau verwendet. Ist `DESTDIR` gesetzt, verlangt der Installer keine Root-Rechte, da er nicht in das echte Systemziel schreibt. Relative Staging-Pfade, `/` sowie Pfade mit `.`- oder `..`-Komponenten werden abgelehnt.

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

Sowohl die manuelle Installation als auch die Paketinstallation behandeln diese Konfigurationsdateien als Benutzerdaten. Sie werden bei Installation, Reinstallation, Update und normaler Deinstallation nicht verändert oder gelöscht.

## Manuelle Installation aktualisieren

Eine bestehende manuelle Installation wird aus dem aktualisierten Repository erneut installiert:

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

## Manuelle Installation entfernen

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

Ein mehrfacher Aufruf des manuellen Uninstallers ist sicher. Ist LAC bereits entfernt, wird lediglich gemeldet, dass unter dem gewählten Präfix keine Installation vorhanden ist.

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

Debian-Paket lokal bauen:

```bash
bash scripts/build_debian_package.sh
```

ShellCheck ausführen:

```bash
shellcheck install.sh uninstall.sh debian/preinst scripts/*.sh \
    src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

Der Installationstest verwendet ein temporäres `DESTDIR` und verändert das echte System nicht. Der Paket-Lifecycle-Test läuft in einem isolierten Debian-Container.

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
