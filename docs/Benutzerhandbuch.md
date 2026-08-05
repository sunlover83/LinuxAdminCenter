# Benutzerhandbuch

## Überblick

Linux Admin Center (LAC) bündelt grundlegende Administrationsaufgaben in einer Bash-Anwendung. Es kann über ein interaktives Menü oder mit einzelnen Kommandozeilenoptionen verwendet werden.

Die aktuelle Version richtet sich an Linux-Desktop-Systeme mit APT, DNF, Pacman oder Zypper.

## Anwendung starten

Wechsle in das Projektverzeichnis und starte LAC:

```bash
cd ~/Projekte/LinuxAdminCenter
./src/lac.sh
```

Falls die Datei noch nicht ausführbar ist:

```bash
chmod +x src/lac.sh
```

## Interaktives Hauptmenü

Im Hauptmenü stehen derzeit folgende Bereiche zur Verfügung:

```text
1) System Updates
2) System Information
3) Network Information
4) System Cleanup
5) Hardware Diagnostics
6) Network Diagnostics
7) Gaming Readiness
0) Exit
```

### System Updates

Das Update-Menü bietet zwei Funktionen:

1. verfügbare Updates suchen
2. verfügbare Updates installieren

Vor einer Installation zeigt LAC die gefundenen Pakete an und verlangt eine ausdrückliche Bestätigung. Ohne Bestätigung werden keine Updates installiert.

Abhängig von Distribution und lokaler Konfiguration kann `sudo` nach einem Passwort fragen.

Unterstützte Paketmanager:

| Distributionen | Paketmanager |
|---|---|
| Debian, Ubuntu, Pop!_OS, Linux Mint | APT |
| Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux | DNF |
| Arch Linux, Manjaro | Pacman und `checkupdates` |
| openSUSE, SUSE Linux Enterprise | Zypper |

Für openSUSE Tumbleweed verwendet LAC `zypper dist-upgrade`. Andere Zypper-Systeme werden mit `zypper update` aktualisiert.

### System Information

Die Systemübersicht zeigt:

- Distribution und Versionsnummer
- erkannten Paketmanager
- Hostname
- Kernelversion
- Systemarchitektur
- CPU-Modell und Anzahl logischer CPUs
- erkannte Grafikkarte oder Grafikkarten
- Laufzeit seit dem letzten Start
- Arbeitsspeichernutzung
- Belegung des Root-Dateisystems
- Load Average für 1, 5 und 15 Minuten
- erforderlichen Neustartstatus

Netzwerkdaten werden bewusst nicht in dieser Übersicht wiederholt. Sie stehen im eigenen Bereich „Network Information“ zur Verfügung.

### Network Information

Die Netzwerkübersicht zeigt:

- aktive Netzwerkschnittstellen ohne Loopback-Interface
- globale IPv4-Adressen einschließlich Schnittstellenname
- Standard-Gateway
- erkannte DNS-Server

Falls ein benötigtes Systemprogramm oder eine Information nicht verfügbar ist, gibt LAC je nach Messwert `unknown` oder `none` aus.

### Network Diagnostics

Die Netzwerkdiagnose führt aktive, aber vollständig schreibgeschützte Verbindungstests durch. Sie zeigt:

- Verfügbarkeit von `ip`, `ping` und `getent`
- erkannte IPv4-Standard-Gateway-Adresse
- Erreichbarkeit des Standard-Gateways
- Paketverlust und durchschnittliche Latenz zum Gateway
- DNS-Auflösung eines Testnamens
- Erreichbarkeit eines externen IP-Testziels
- Paketverlust und durchschnittliche Latenz zum externen Ziel
- eine Gesamtbewertung als `healthy`, `warning` oder `failed`
- eine erklärende Zusammenfassung des Ergebnisses

Die Bewertung berücksichtigt, dass ICMP beziehungsweise Ping in einigen Netzwerken blockiert wird. Funktioniert beispielsweise die DNS-Auflösung, während das externe Ping-Ziel nicht antwortet, wird deshalb eine Warnung statt eines eindeutigen Internetausfalls ausgegeben.

Die Diagnose verändert keine Netzwerkschnittstellen, Routen, Gateway- oder DNS-Einstellungen und benötigt keine Root-Rechte.

Standardmäßig werden folgende Testziele verwendet:

| Test | Standardziel |
|---|---|
| DNS-Auflösung | `example.com` |
| externe IP-Erreichbarkeit | `1.1.1.1` |

Die Ziele können für einen einzelnen Aufruf überschrieben werden:

```bash
LAC_DNS_TEST_HOST=example.org \
LAC_INTERNET_TEST_TARGET=9.9.9.9 \
./src/lac.sh --network-diagnostics
```

### Hardware Diagnostics

Die Hardwarediagnose ist vollständig schreibgeschützt. Sie zeigt abhängig von den installierten Werkzeugen:

- Verfügbarkeit der Diagnoseprogramme
- CPU-Temperatur
- NVIDIA-GPU-Modell
- GPU-Temperatur
- GPU-Auslastung
- belegten und gesamten GPU-Speicher
- erkannte physische Laufwerke und deren Modelle
- SMART-Gesundheitsstatus von SATA- und kompatiblen Laufwerken
- NVMe-Gesundheitsstatus

Verwendete Programme:

| Werkzeug | Aufgabe |
|---|---|
| `sensors` | CPU-Temperatur ermitteln |
| `nvidia-smi` | NVIDIA-GPU-Daten ermitteln |
| `lsblk` | physische Laufwerke erkennen |
| `smartctl` | SMART-Gesundheitsstatus prüfen |
| `nvme` | NVMe-Gesundheitsstatus prüfen |

Fehlende Programme werden als `not installed` beziehungsweise Messwerte als `unavailable` angezeigt.

Für den Zugriff auf SMART- und NVMe-Gesundheitsdaten sind häufig Root-Rechte erforderlich. LAC fordert diese Rechte nicht automatisch an. Ohne ausreichende Rechte erscheint:

```text
requires root
```

Die Diagnose kann bei Bedarf ausdrücklich mit Root-Rechten gestartet werden:

```bash
sudo ./src/lac.sh --hardware-diagnostics
```

Virtuelle ZRAM-Geräte und Laufwerke mit einer Größe von null Byte, beispielsweise leere Kartenleser, werden nicht geprüft.

### Gaming Readiness

Gaming Readiness erstellt einen vollständig schreibgeschützten Überblick über die grundlegende Linux-Gaming-Umgebung. Angezeigt werden:

- verwendeter Display-Server (`wayland`, `x11` oder `unknown`)
- erkannte Desktop-Umgebung
- aktive Grafiktreiber
- NVIDIA-Treiberversion, sofern `nvidia-smi` verfügbar ist
- Vulkan-Status über `vulkaninfo --summary`
- Steam als native oder Flatpak-Installation
- benutzerdefinierte Proton-Kompatibilitätswerkzeuge
- Verfügbarkeit von GameMode, MangoHud und Gamescope
- Gesamtbewertung als `ready`, `limited` oder `incomplete`
- erklärende Zusammenfassung des Ergebnisses

Die Gesamtbewertung verwendet nur die Kernvoraussetzungen: grafische Sitzung, aktiver Grafiktreiber, Vulkan-Prüfung und Steam. Optionale Werkzeuge werden angezeigt, verschlechtern den Status aber nicht.

| Status | Bedeutung |
|---|---|
| `ready` | grafische Sitzung, Treiber, Vulkan-Prüfung und Steam sind verfügbar |
| `limited` | mindestens eine Kernvoraussetzung fehlt oder konnte nicht bestätigt werden |
| `incomplete` | mehrere Kernvoraussetzungen fehlen oder die grafische Basis konnte nicht ermittelt werden |

Fehlt `vulkaninfo`, erscheint `not verified`. Das bedeutet nur, dass LAC Vulkan nicht prüfen konnte. Es ist kein Beleg dafür, dass die Vulkan-Laufzeit oder Vulkan-Unterstützung tatsächlich fehlt.

`Custom Proton tools: none` bedeutet, dass keine separat installierten Werkzeuge wie Proton-GE in den üblichen Steam-Verzeichnissen gefunden wurden. Die mit Steam ausgelieferten Proton-Versionen werden dadurch nicht als fehlend bewertet.

Gaming Readiness installiert keine Pakete, verändert keine Grafik- oder Steam-Einstellungen und benötigt keine Root-Rechte.

### System Cleanup

Das Cleanup-Menü enthält drei Funktionen:

1. Cleanup-Bericht anzeigen
2. Paket-Cache bereinigen
3. nicht mehr benötigte Pakete entfernen

#### Cleanup-Bericht

Der Bericht ist vollständig schreibgeschützt. Er zeigt:

- erkannten Paketmanager
- Pfad des Paket-Caches
- derzeitige Größe des Paket-Caches
- vom Systemjournal belegten Speicherplatz
- Anzahl und Namen der Pakete, die der Paketmanager als nicht mehr benötigt einstuft

Der Bericht löscht keine Dateien und entfernt keine Pakete.

#### Paket-Cache bereinigen

Vor der Bereinigung zeigt LAC den Cache-Pfad und seine aktuelle Größe an. Die Aktion startet erst nach einer Bestätigung mit `y` oder `Y`.

Je nach Paketmanager wird ausgeführt:

| Paketmanager | Verhalten |
|---|---|
| APT | heruntergeladene Paketdateien werden mit `apt-get clean` entfernt |
| DNF | nur heruntergeladene Pakete werden mit `dnf clean packages` entfernt |
| Pacman | `paccache` behält die zwei neuesten Versionen jedes Pakets |
| Zypper | der heruntergeladene Paket-Cache wird bereinigt; Metadaten bleiben erhalten |

Das Systemjournal wird lediglich analysiert. Die aktuelle Version löscht oder verkleinert keine Journaldateien.

#### Nicht mehr benötigte Pakete entfernen

LAC zeigt zuerst die vollständige Paketliste an. Die Entfernung beginnt nur, wenn anschließend exakt

```text
REMOVE
```

eingegeben wird.

Die Einstufung stammt vom jeweiligen Paketmanager. Trotzdem sollte die Liste vor der Bestätigung sorgfältig geprüft werden. Paketentfernungen verändern das System und können zusätzliche Abhängigkeiten betreffen.

## Kommandozeilenoptionen

```text
-h, --help                   Hilfe anzeigen
-v, --version                Version und Codename anzeigen
-i, --system-info            Systeminformationen anzeigen
-n, --network-info           Netzwerkinformationen anzeigen
-r, --network-diagnostics    Netzwerkdiagnose anzeigen
-d, --hardware-diagnostics   Hardwarediagnose anzeigen
-g, --gaming-readiness       Gaming-Bereitschaft anzeigen
-u, --check-updates          Nach verfügbaren Updates suchen
-c, --cleanup-report         Schreibgeschützten Cleanup-Bericht anzeigen
```

Beispiele:

```bash
./src/lac.sh --version
./src/lac.sh --system-info
./src/lac.sh --network-info
./src/lac.sh --network-diagnostics
./src/lac.sh --hardware-diagnostics
./src/lac.sh --gaming-readiness
./src/lac.sh --check-updates
./src/lac.sh --cleanup-report
```

Es darf jeweils genau eine Option übergeben werden.

## Rückgabecodes

Die Rückgabecodes sind besonders bei der Verwendung in Skripten hilfreich.

| Code | Bedeutung |
|---:|---|
| `0` | erfolgreich ausgeführt oder keine Updates gefunden |
| `1` | Laufzeitfehler, zum Beispiel fehlgeschlagene Paketaktualisierung oder Analyse |
| `2` | ungültige Option oder nicht unterstützter Paketmanager |
| `10` | verfügbare Updates wurden gefunden |

Beispiel:

```bash
./src/lac.sh --check-updates
status=$?

case "$status" in
    0)  echo "Keine Updates verfügbar." ;;
    10) echo "Updates verfügbar." ;;
    *)  echo "Updateprüfung fehlgeschlagen." ;;
esac
```

## Konfiguration

LAC lädt die Konfiguration in dieser Reihenfolge:

1. `/etc/lac/lac.conf`
2. `${XDG_CONFIG_HOME:-$HOME/.config}/lac/lac.conf`

Die Benutzerkonfiguration überschreibt die systemweite Konfiguration.

Derzeit unterstützte Einstellung:

```ini
DEBUG=false
```

Mit aktivierter Debug-Ausgabe:

```ini
DEBUG=true
```

Beispiel für eine Benutzerkonfiguration:

```bash
mkdir -p ~/.config/lac
printf '%s\n' 'DEBUG=true' > ~/.config/lac/lac.conf
```

## Fehlerbehebung

### „Permission denied“ beim Start

```bash
chmod +x src/lac.sh
```

### Paketmanager wird nicht unterstützt

Prüfe zunächst die Erkennung:

```bash
./src/lac.sh --system-info
```

Bei Arch-basierten Systemen muss zusätzlich zu Pacman das Programm `checkupdates` vorhanden sein.

### Pacman-Cache kann nicht bereinigt werden

Die sichere Pacman-Bereinigung verwendet `paccache`. Das Programm ist Bestandteil von `pacman-contrib`.

```bash
sudo pacman -S pacman-contrib
```

### Cleanup-Bericht zeigt `unavailable`

Ein nicht vorhandenes Cache-Verzeichnis oder ein fehlender Befehl wie `journalctl` wird als `unavailable` angezeigt. Das ist kein Lösch- oder Paketfehler.

### Netzwerkdaten werden als `unknown` angezeigt

Prüfe, ob der Befehl `ip` verfügbar ist:

```bash
command -v ip
```

Für die Hardwareerkennung sind unter anderem `lscpu`, `lspci` und bei NVIDIA-Systemen optional `nvidia-smi` hilfreich.

### Netzwerkdiagnose zeigt `warning`

Eine Warnung bedeutet nicht zwingend, dass die Internetverbindung ausgefallen ist. Router oder externe Systeme können Ping-Anfragen blockieren.

Prüfe zunächst die einzelnen Ergebnisse:

```bash
./src/lac.sh --network-diagnostics
```

Typische Fälle:

- Gateway-Ping fehlgeschlagen, aber Internetziel erreichbar: Der Router beantwortet wahrscheinlich keine ICMP-Anfragen.
- DNS funktioniert, aber das externe Ping-Ziel antwortet nicht: Das Ziel oder eine Firewall blockiert möglicherweise ICMP.
- externe IP erreichbar, aber DNS fehlgeschlagen: Die IP-Verbindung funktioniert, die Namensauflösung jedoch nicht.
- kein Standard-Gateway: Es ist keine verwendbare IPv4-Standardroute konfiguriert.

### Gaming Readiness zeigt `limited`

Prüfe zuerst die Detailmeldung:

```bash
./src/lac.sh --gaming-readiness
```

Typische Fälle:

- `Vulkan: not verified`: Das Programm `vulkaninfo` ist nicht installiert; LAC kann Vulkan deshalb nicht bestätigen.
- `Steam: not installed`: Weder eine native noch eine Flatpak-Steam-Installation wurde erkannt.
- `Custom Proton tools: none`: Keine separat installierte Proton-Version wurde gefunden; Steams integrierte Proton-Versionen können trotzdem vorhanden sein.
- GameMode, MangoHud oder Gamescope fehlen: Diese Werkzeuge sind optional und ändern die Kernbewertung nicht.

Prüfe die verwendeten Programme mit:

```bash
command -v lspci
command -v nvidia-smi
command -v vulkaninfo
command -v steam
command -v gamemoderun
command -v mangohud
command -v gamescope
```

### Laufwerksdiagnose zeigt `requires root`

SMART- und NVMe-Gesundheitsdaten sind auf vielen Systemen nur mit administrativen Rechten zugänglich.

Einzelne Laufwerke können direkt geprüft werden:

```bash
sudo smartctl -H /dev/sda
sudo nvme smart-log /dev/nvme0n1
```

Oder die gesamte LAC-Hardwarediagnose:

```bash
sudo ./src/lac.sh --hardware-diagnostics
```

Die Hardwarediagnose führt keine Schreib-, Reparatur- oder Selbsttestbefehle aus.

### Debug-Ausgabe aktivieren

Setze in der Benutzerkonfiguration:

```ini
DEBUG=true
```

Anschließend LAC neu starten.
