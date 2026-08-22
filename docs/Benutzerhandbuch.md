# Benutzerhandbuch

## Überblick

Linux Admin Center (LAC) bündelt grundlegende Administrationsaufgaben in einer modularen Bash-Anwendung. Es kann über ein interaktives Menü oder mit einzelnen Kommandozeilenoptionen verwendet werden.

Ab Version `0.9.0-alpha` kann LAC systemweit installiert werden. Danach steht der Befehl `lac` unabhängig vom Repository-Pfad zur Verfügung. Diagnosefunktionen sind grundsätzlich schreibgeschützt. Schreibende Update- und Cleanup-Aktionen werden nur nach einer ausdrücklichen Bestätigung ausgeführt.

Die aktuelle Version richtet sich an Linux-Desktop-Systeme mit APT, DNF, Pacman oder Zypper. Linux-Derivate werden über die Angaben `ID` und `ID_LIKE` aus `/etc/os-release` einer unterstützten Paketmanager-Familie zugeordnet.

## Installation und Programmstart

Die Standardinstallation aus dem geklonten Repository erfolgt mit:

```bash
cd ~/projects/LinuxAdminCenter
sudo ./install.sh
```

Danach kann LAC aus jedem Verzeichnis gestartet werden:

```bash
lac
```

Version prüfen:

```bash
lac --version
```

LAC-Installation und Laufzeitumgebung prüfen:

```bash
lac --self-check
```

Für Entwicklung und Tests ist weiterhin der direkte Start aus dem Repository möglich:

```bash
./src/lac.sh
```

Eine bestehende Installation wird nach einem Repository-Update durch erneutes Ausführen des Installers aktualisiert:

```bash
cd ~/projects/LinuxAdminCenter
git switch main
git pull --ff-only
sudo ./install.sh
```

Die Anwendung kann systemweit entfernt werden mit:

```bash
sudo lac-uninstall
```

Der Uninstaller entfernt die installierten LAC-Dateien, lässt aber `/etc/lac` und Benutzerkonfigurationen unter `$HOME/.config/lac` unangetastet.

Weitere Installationsdetails, benutzerdefinierte Präfixe und `DESTDIR` sind in [Installation.md](Installation.md) beschrieben.

## Interaktives Hauptmenü

```text
1) System Updates
2) System Information
3) Network Information
4) System Cleanup
5) Hardware Diagnostics
6) Network Diagnostics
7) Gaming Readiness
8) Service Health
9) Gaming Diagnostics
10) LAC Self Check
11) Storage Analysis

0) Exit
```

## Funktionsbereiche

### System Updates

Das Update-Menü bietet zwei Funktionen:

1. verfügbare Updates suchen
2. verfügbare Updates installieren

Vor einer Installation zeigt LAC die gefundenen Pakete an und verlangt eine ausdrückliche Bestätigung. Ohne Bestätigung werden keine Updates installiert. Abhängig von Distribution und lokaler Konfiguration kann `sudo` nach einem Passwort fragen.

Unterstützte Paketmanager-Familien:

| Distributionen | Paketmanager |
|---|---|
| Debian- und Ubuntu-basierte Systeme | APT |
| Fedora- und RHEL-basierte Systeme | DNF |
| Arch-basierte Systeme | Pacman |
| openSUSE- und SUSE-basierte Systeme | Zypper |

Für Update-Prüfungen auf Arch-basierten Systemen wird zusätzlich `checkupdates` benötigt. Fehlt dieses Werkzeug, bleiben andere Pacman-basierte LAC-Funktionen weiterhin nutzbar; nur die Update-Funktion wird als unvollständig gemeldet.

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

Netzwerkdaten werden bewusst nicht wiederholt. Sie stehen im Bereich „Network Information“ zur Verfügung.

### Storage Analysis

Storage Analysis zeigt die Belegung der eingehängten lokalen persistenten Dateisysteme. Der Bericht kann über Menüpunkt 11 oder direkt aufgerufen werden:

```bash
lac --storage-analysis
```

Für jedes berücksichtigte Dateisystem zeigt LAC:

- Einhängepunkt, Dateisystemtyp und Quelle
- belegte und gesamte Kapazität
- prozentuale Belegung und noch verfügbare Kapazität
- belegte und gesamte Inodes sowie deren prozentuale Belegung, sofern der Dateisystemtyp aussagekräftige Inode-Werte liefert
- Einzelstatus des Dateisystems

Kapazität und Inodes werden unabhängig mit denselben Standardgrenzen bewertet. Der Bericht erklärt die Zustände direkt:

| Status | Bedeutung |
|---|---|
| `healthy` | alle auswertbaren Kapazitäts- und Inode-Werte liegen unter 80% |
| `warning` | mindestens ein Wert liegt zwischen 80% und 89%, kein Wert ist kritisch |
| `critical` | mindestens ein Wert liegt bei 90% oder höher |
| `incomplete` | die verfügbaren Daten reichen für die jeweilige Bewertung nicht aus |

Der jeweils schwerwiegendere Kapazitäts- oder Inode-Status bestimmt den Status eines Dateisystems. Der schwerwiegendste Einzelstatus bestimmt anschließend die Gesamtbewertung. Nicht verfügbare Inode-Werte erscheinen als `not applicable` und verschlechtern die Bewertung allein nicht. Kann `df` nicht ausgeführt werden, können die Dateisystemdaten nicht gelesen werden oder existiert kein auswertbares lokales persistentes Dateisystem, lautet die Gesamtbewertung `incomplete`.

Nach der Gesamtbewertung zeigt LAC sichere, statusabhängige Empfehlungen. Bei Kapazitätsdruck wird auf das Archivieren oder Entfernen ausschließlich geprüfter unnötiger Daten hingewiesen; bei Inode-Druck auf Verzeichnisse mit sehr vielen kleinen Dateien. `lac --cleanup-report` bietet dafür zunächst eine rein lesende Übersicht der unterstützten Cleanup-Kandidaten. Bei `warning` und `critical` empfiehlt LAC vor Bereinigung, Größenänderung oder Speichererweiterung ausdrücklich eine Sicherung wichtiger Daten. Die Empfehlungen führen selbst keine Änderung aus.

Ein hoch belegtes Dateisystem am Einhängepunkt `/recovery` behält seinen gemessenen Status. LAC erklärt jedoch direkt am Datensatz, dass eine hohe Belegung normal sein kann, wenn die Partition ein Recovery-Installationsmedium enthält. Löst ausschließlich `/recovery` einen erhöhten Status aus, entfallen die dafür ungeeigneten Cleanup- und Archivierungshinweise. Stattdessen verweist der Bericht auf die unterstützten Recovery- oder Update-Werkzeuge der jeweiligen Distribution und warnt ausdrücklich davor, Recovery-Dateien manuell zu löschen. Sind gleichzeitig andere Dateisysteme betroffen, bleiben für diese die allgemeinen Hinweise sichtbar.

LAC berücksichtigt nur bereits eingehängte lokale Dateisysteme. Pseudo- und RAM-Dateisysteme wie `proc`, `sysfs` oder `tmpfs`, entfernte Dateisysteme, bekannte schreibgeschützte Image-Dateisysteme wie `squashfs` und ausgewählte virtuelle FUSE-Dateisysteme werden ausgefiltert. Die Ermittlung verwendet die GNU-Coreutils-Ausgabe von `df`, die auf den unterstützten Zielsystemen Debian, Fedora, Arch Linux und openSUSE verfügbar ist. Andere `df`-Implementierungen mit abweichenden Optionen gehören nicht zum zugesicherten Portabilitätsumfang.

Storage Analysis führt ausschließlich `df` lesend aus. Die Funktion verwendet kein `sudo`, hängt keine Dateisysteme ein oder aus, startet weder `fsck` noch Trim-, Resize- oder Reparaturbefehle und löscht oder schreibt keine Daten.

Die Funktionsgrenzen sind bewusst klar:

- Hardware Diagnostics bewertet physische Laufwerke und deren SMART- beziehungsweise NVMe-Gesundheitsdaten.
- System Cleanup zeigt Cache- und Journalbelegung und bietet ausschließlich nach Bestätigung begrenzte Cleanup-Aktionen an.
- Storage Analysis bewertet nur Kapazitäts- und Inode-Druck bereits eingehängter lokaler Dateisysteme.
- Verzeichnis-Hotspots, Dateisuche und mögliche spätere Speicherwartung sind nicht Bestandteil dieser Version.

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
- Gesamtbewertung als `healthy`, `warning` oder `failed`
- erklärende Zusammenfassung des Ergebnisses

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
lac --network-diagnostics
```

Ungültige beziehungsweise optionsähnliche Werte und Werte mit Whitespace werden abgewiesen, bevor sie an `ping` oder `getent` übergeben werden.

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

Für SMART- und NVMe-Gesundheitsdaten sind häufig Root-Rechte erforderlich. LAC fordert diese Rechte nicht automatisch an. Ohne ausreichende Rechte erscheint:

```text
requires root
```

Die Diagnose kann bei Bedarf ausdrücklich mit Root-Rechten gestartet werden:

```bash
sudo lac --hardware-diagnostics
```

Virtuelle ZRAM-Geräte und Laufwerke mit einer Größe von null Byte, beispielsweise leere Kartenleser, werden nicht geprüft.

### Gaming Readiness

Gaming Readiness ist der schnelle schreibgeschützte Überblick über die grundlegende Linux-Gaming-Umgebung. Angezeigt werden:

- verwendeter Display-Server (`wayland`, `x11` oder `unknown`)
- erkannte Desktop-Umgebung
- aktive Grafiktreiber
- NVIDIA-Treiberversion, sofern `nvidia-smi` verfügbar ist
- Vulkan-Grundstatus über `vulkaninfo --summary`
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

Fehlt `vulkaninfo`, erscheint `not verified`. Das bedeutet nur, dass LAC Vulkan nicht prüfen konnte. Es ist kein Beleg dafür, dass die Vulkan-Laufzeit tatsächlich fehlt.

`Custom Proton tools: none` bedeutet, dass keine separat installierten Werkzeuge wie Proton-GE in den üblichen Steam-Verzeichnissen gefunden wurden. Die mit Steam ausgelieferten Proton-Versionen werden dadurch nicht als fehlend bewertet.

Gaming Readiness installiert keine Pakete, verändert keine Grafik- oder Steam-Einstellungen und benötigt keine Root-Rechte.

### Gaming Diagnostics

Gaming Diagnostics ergänzt Gaming Readiness um eine detaillierte Kompatibilitätsanalyse. Der Bereich bleibt vollständig schreibgeschützt und startet weder Steam noch Spiele oder Proton.

Angezeigt werden:

- Vulkan-Runtime-Status
- Vulkan-Instance-Version
- erkannte Vulkan-Geräte
- Vulkan-Treibername je Gerät
- gemeldete Vulkan-API-Version je Gerät
- Status der 32-Bit-Vulkan-Unterstützung
- erkannte Steam-Installationsart
- nativer Steam-Startpfad oder Flatpak-Anwendungskennung
- erkannte Steam-Bibliothekswurzeln
- Anzahl eindeutiger Steam-Kompatibilitätspräfixe aus `compatdata`
- mit Steam ausgelieferte Proton-Runtimes
- benutzerdefinierte Proton-Werkzeuge wie Proton-GE
- Verfügbarkeit von GameMode, MangoHud, MangoApp und Gamescope
- Gamescope-Version, sofern verfügbar
- Gesamtbewertung als `healthy`, `warning` oder `incomplete`

Gaming Readiness und Gaming Diagnostics haben unterschiedliche Aufgaben:

| Bereich | Zweck |
|---|---|
| Gaming Readiness | schnelle Prüfung, ob die grundlegende Gaming-Umgebung vorhanden ist |
| Gaming Diagnostics | detaillierte Prüfung von Vulkan-, Steam- und Proton-Kompatibilitätsdaten |

Die Gaming-Diagnostics-Bewertung verwendet folgende Zustände:

| Status | Bedeutung |
|---|---|
| `healthy` | Vulkan und Steam sind verfügbar, 32-Bit-Grafikunterstützung ist bestätigt beziehungsweise wird von Flatpak verwaltet und mindestens eine Proton-Runtime wurde erkannt |
| `warning` | Vulkan und Steam sind verfügbar, aber 32-Bit-Vulkan-Unterstützung oder Proton-Runtimes konnten nicht bestätigt werden |
| `incomplete` | Vulkan oder Steam stehen für die Detaildiagnose nicht zur Verfügung |

#### 32-Bit-Vulkan-Unterstützung

Bei einer nativen Steam-Installation sucht LAC an üblichen distributionsabhängigen Pfaden nach einem 32-Bit-Vulkan-Loader. Das Ergebnis ist bewusst konservativ:

```text
available
```

bedeutet, dass ein bekannter Loader-Pfad gefunden wurde.

```text
not verified
```

bedeutet nur, dass LAC an den geprüften Standardpfaden keinen Loader gefunden hat. Es ist kein sicherer Nachweis dafür, dass 32-Bit-Vulkan tatsächlich nicht funktioniert.

Bei Flatpak-Steam erscheint:

```text
managed by Flatpak
```

Flatpak stellt seine Grafik-Runtime über eigene Runtime- und Treibererweiterungen bereit. Deshalb bewertet LAC in diesem Fall nicht die 32-Bit-Bibliotheken des Host-Systems.

#### Steam-Bibliotheken

LAC berücksichtigt bekannte Steam-Verzeichnisse sowie zusätzliche Bibliotheken aus:

```text
steamapps/libraryfolders.vdf
```

Symbolische Links auf dieselbe physische Steam-Installation werden kanonisiert und nicht doppelt angezeigt.

#### Proton-Runtimes

Gebündelte Proton-Runtimes werden in `steamapps/common` gesucht. Ein Verzeichnis wird nur dann als Proton-Runtime gewertet, wenn eine passende `proton`-Datei vorhanden ist.

Benutzerdefinierte Kompatibilitätswerkzeuge werden weiterhin aus den bekannten `compatibilitytools.d`-Verzeichnissen gelesen und als `custom` ausgegeben.

Die Zahl `Compatibility prefixes` entspricht der Anzahl eindeutiger numerischer App-ID-Verzeichnisse unter `steamapps/compatdata` über alle erkannten Bibliotheken. Sie ist keine Aussage darüber, ob jedes zugehörige Spiel derzeit installiert ist oder fehlerfrei funktioniert.

Gaming Diagnostics verändert keine Steam-Bibliotheken, Proton-Präfixe, Vulkan-Konfigurationen, Treiber oder Leistungsprofile. Aktive GameMode-Tests wie `gamemoded -t` werden bewusst nicht ausgeführt.

### Service Health

Service Health erstellt einen schreibgeschützten Überblick über Dienste und Systemstart auf systemd-Systemen. Angezeigt werden:

- erkanntes Init-System
- Verfügbarkeit von `systemctl` und `systemd-analyze`
- systemd-Systemzustand
- Anzahl aktiver, inaktiver und fehlgeschlagener Dienste
- Namen und Zustände fehlgeschlagener Dienste
- gesamte von systemd gemeldete Startzeit
- fünf langsamste Dienste beim Systemstart
- Gesamtbewertung als `healthy`, `warning` oder `failed`
- erklärende Zusammenfassung des Ergebnisses

| Status | Bedeutung |
|---|---|
| `healthy` | systemd läuft und es wurden keine fehlgeschlagenen Dienste erkannt |
| `warning` | systemd ist noch im Start, meldet `degraded` oder es existieren fehlgeschlagene Dienste |
| `failed` | die Auswertung ist nicht möglich oder systemd meldet einen kritischen Zustand wie `maintenance`, `offline` oder `stopping` |

Inaktive Dienste sind nicht automatisch fehlerhaft. Viele Units werden nur bei Bedarf gestartet oder beenden sich nach erfolgreicher Ausführung.

Die angezeigte Gesamtstartzeit stammt aus `systemd-analyze time`. Sie kann Firmware, Bootloader, Kernel und Userspace umfassen. Die Liste der langsamsten Dienste stammt aus `systemd-analyze blame` und ist ein Diagnosehinweis, aber kein automatischer Beleg für einen Fehler.

Service Health startet, stoppt, aktiviert, deaktiviert oder verändert keine Dienste und benötigt keine Root-Rechte. Nicht-systemd-Systeme werden derzeit als nicht unterstützt gemeldet.

### LAC Self Check

Der Self Check prüft die LAC-Laufzeit selbst und ist vollständig schreibgeschützt. Er zeigt:

- aktive Bash-Version und Kompatibilität mit der Mindestversion 4.3
- Installationsart (`repository`, `system-wide` oder `custom`)
- Runtime-Wurzel und Vollständigkeit aller eingebundenen Core- und Moduldateien
- installierte Launcher bei einer systemweiten Installation
- Status von System- und Benutzerkonfiguration
- Verfügbarkeit der von LAC benötigten Kernwerkzeuge
- Verfügbarkeit optionaler Diagnosewerkzeuge
- erkannten Paketmanager
- Gesamtstatus `healthy`, `warning` oder `failed`

Fehlende optionale Diagnosewerkzeuge verschlechtern den Gesamtstatus nicht. Fehlende Runtime-Dateien, eine zu alte Bash-Version oder unvollständige systemweite Launcher führen zu `failed`. Fehlende Kernwerkzeuge, nicht lesbare Konfiguration oder ein nicht nutzbarer Paketmanager führen zu `warning`.

```bash
lac --self-check
```

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
-s, --storage-analysis       Schreibgeschützte Speicheranalyse anzeigen
-n, --network-info           Netzwerkinformationen anzeigen
-r, --network-diagnostics    Netzwerkdiagnose anzeigen
-d, --hardware-diagnostics   Hardwarediagnose anzeigen
-g, --gaming-readiness       Gaming-Bereitschaft anzeigen
-G, --gaming-diagnostics     Detaillierte Gaming-Diagnose anzeigen
-e, --service-health         Dienst- und Startzustand anzeigen
-S, --self-check             LAC-Laufzeit und Abhängigkeiten prüfen
-u, --check-updates          Nach verfügbaren Updates suchen
-c, --cleanup-report         Schreibgeschützten Cleanup-Bericht anzeigen
```

Beispiele mit einer installierten LAC-Version:

```bash
lac --version
lac --system-info
lac --storage-analysis
lac --network-info
lac --network-diagnostics
lac --hardware-diagnostics
lac --gaming-readiness
lac --gaming-diagnostics
lac --service-health
lac --self-check
lac --check-updates
lac --cleanup-report
```

Es darf jeweils genau eine Option übergeben werden.

## Rückgabecodes

| Code | Bedeutung |
|---:|---|
| `0` | erfolgreich ausgeführt oder keine Updates gefunden |
| `1` | Laufzeitfehler, zum Beispiel fehlgeschlagene Paketaktualisierung oder Analyse |
| `2` | ungültige Option, nicht unterstützte Umgebung oder fehlende Voraussetzung für die angeforderte Funktion |
| `10` | verfügbare Updates wurden gefunden |

Beispiel:

```bash
lac --check-updates
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

Ist weder ein expliziter Benutzerpfad noch `XDG_CONFIG_HOME` oder `HOME` verfügbar, wird einfach keine Benutzerkonfigurationsdatei geladen.

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

Bei Standardinstallation liegt eine Beispielkonfiguration unter:

```text
/usr/local/share/linux-admin-center/lac.conf.example
```

Installer und Uninstaller überschreiben oder löschen aktive Konfigurationsdateien nicht.

## Fehlerbehebung

### `lac: command not found`

Prüfe zunächst, ob LAC installiert wurde:

```bash
ls -l /usr/local/bin/lac
```

Falls die Datei fehlt, im Repository erneut installieren:

```bash
sudo ./install.sh
```

Bei einem benutzerdefinierten Präfix muss dessen `bin`-Verzeichnis in `PATH` enthalten sein.

### Direkter Entwicklungsstart meldet `Permission denied`

Beim direkten Start aus dem Repository kann das Ausführungsrecht gesetzt werden:

```bash
chmod +x src/lac.sh
```

Alternativ funktioniert:

```bash
bash src/lac.sh
```

### Paketmanager oder Update-Funktion wird nicht unterstützt

Prüfe zunächst:

```bash
lac --self-check
lac --system-info
```

Auf Arch-basierten Systemen reicht `pacman` für die grundlegende Paketmanager-Unterstützung. Für Update-Prüfungen benötigt LAC zusätzlich `checkupdates`. Fehlt `checkupdates`, bleiben beispielsweise Systeminformationen und andere Pacman-basierte Funktionen verfügbar.

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

```bash
lac --network-diagnostics
```

Typische Fälle:

- Gateway-Ping fehlgeschlagen, aber Internetziel erreichbar: Der Router beantwortet wahrscheinlich keine ICMP-Anfragen.
- DNS funktioniert, aber das externe Ping-Ziel antwortet nicht: Das Ziel oder eine Firewall blockiert möglicherweise ICMP.
- externe IP erreichbar, aber DNS fehlgeschlagen: Die IP-Verbindung funktioniert, die Namensauflösung jedoch nicht.
- kein Standard-Gateway: Es ist keine verwendbare IPv4-Standardroute konfiguriert.

### Storage Analysis zeigt `warning`, `critical` oder `incomplete`

```bash
lac --storage-analysis
```

`warning` bedeutet, dass mindestens ein berücksichtigtes Dateisystem bei Kapazität oder Inodes 80% erreicht hat. `critical` bedeutet, dass mindestens ein Wert 90% erreicht hat. Ein hoher Inode-Verbrauch kann auftreten, obwohl noch ausreichend Datenkapazität verfügbar ist.

`incomplete` bedeutet, dass keine vollständige Bewertung möglich war. Prüfe in diesem Fall zunächst die rein lesenden Grundlagen:

```bash
command -v df
df --local --human-readable
df --local --inodes
```

Storage Analysis führt selbst keine Bereinigung oder Reparatur aus. Vor manuellen Änderungen sollte geprüft werden, welches Dateisystem betroffen ist und ob die Kapazitäts- oder die Inode-Grenze ausgelöst wurde.

Ist ausschließlich `/recovery` betroffen, kann die hohe Belegung bei einer dedizierten Partition mit Recovery-Installationsmedium erwartet sein. Dateien dort nicht manuell löschen. Stattdessen mit den von der Distribution vorgesehenen Recovery- oder Update-Werkzeugen prüfen, ob das Medium aktuell und nutzbar ist. Weiterer Kapazitätsbedarf ist insbesondere dann zu untersuchen, wenn dieser unterstützte Vorgang unzureichenden Speicher meldet oder fehlschlägt.

### Gaming Readiness zeigt `limited`

```bash
lac --gaming-readiness
```

Typische Fälle:

- `Vulkan: not verified`: `vulkaninfo` ist nicht installiert; LAC kann Vulkan deshalb nicht bestätigen.
- `Steam: not installed`: Weder eine native noch eine Flatpak-Steam-Installation wurde erkannt.
- `Custom Proton tools: none`: Keine separat installierte Proton-Version wurde gefunden; Steams integrierte Proton-Versionen können trotzdem vorhanden sein.
- GameMode, MangoHud oder Gamescope fehlen: Diese Werkzeuge sind optional und ändern die Kernbewertung nicht.

Prüfe die verwendeten Programme mit:

```bash
command -v lspci
command -v nvidia-smi
command -v vulkaninfo
command -v steam
command -v flatpak
command -v gamemoderun
command -v mangohud
command -v gamescope
```

### Gaming Diagnostics zeigt `warning`

```bash
lac --gaming-diagnostics
```

Typische Ursachen:

- `32-bit Vulkan support: not verified`: Bei nativer Steam-Installation wurde an den bekannten Host-Pfaden kein 32-Bit-Vulkan-Loader gefunden.
- `Proton runtimes: none`: In den erkannten Steam-Bibliotheken wurde keine gebündelte oder benutzerdefinierte Proton-Runtime gefunden.
- einzelne Integrationstools wie MangoApp oder Gamescope fehlen. Diese Werkzeuge werden angezeigt, sind für den Gesamtstatus aber nicht zwingend erforderlich.

Bei Flatpak-Steam ist `32-bit Vulkan support: managed by Flatpak` ein normaler Zustand und keine Warnung.

### Gaming Diagnostics zeigt `incomplete`

Der Status `incomplete` bedeutet, dass die Detailanalyse ihre Kernvoraussetzungen nicht vollständig vorfindet. Prüfe insbesondere:

```bash
command -v vulkaninfo
command -v steam
command -v flatpak
```

Gaming Diagnostics versucht nicht, fehlende Pakete automatisch zu installieren.

### Service Health zeigt `warning`

```bash
lac --service-health
```

Eine Warnung kann entstehen, wenn systemd den Zustand `degraded` meldet oder mindestens ein Dienst fehlgeschlagen ist. Die betroffenen Service-Namen und Details werden direkt im Bericht angezeigt.

Die langsamsten Dienste beim Systemstart verursachen allein keine Warnung. `systemd-analyze blame` dient nur als Diagnosehinweis.

### Service Health zeigt `failed`

Prüfe zunächst:

```bash
systemctl is-system-running
systemctl --failed
```

Nicht-systemd-Systeme werden derzeit nicht vollständig unterstützt und deshalb nicht als gesund bewertet.

### Self Check zeigt `warning` oder `failed`

```bash
lac --self-check
```

Ein `warning` weist auf eine eingeschränkte Umgebung hin, beispielsweise ein fehlendes Kernwerkzeug, eine nicht lesbare Konfiguration oder einen nicht nutzbaren Paketmanager. Ein `failed` weist auf ein grundlegendes Laufzeitproblem hin, etwa fehlende LAC-Dateien oder unvollständige Launcher.

Optionale Diagnoseprogramme werden separat angezeigt und erzeugen allein keine Warnung.

### Laufwerksdiagnose zeigt `requires root`

SMART- und NVMe-Gesundheitsdaten sind auf vielen Systemen nur mit administrativen Rechten zugänglich.

Einzelne Laufwerke können direkt geprüft werden:

```bash
sudo smartctl -H /dev/sda
sudo nvme smart-log /dev/nvme0n1
```

Oder die gesamte LAC-Hardwarediagnose:

```bash
sudo lac --hardware-diagnostics
```

Die Hardwarediagnose führt keine Schreib-, Reparatur- oder Selbsttestbefehle aus.

### Installation aktualisieren

Nach einem Update des Repositorys muss der Installer erneut ausgeführt werden:

```bash
cd ~/projects/LinuxAdminCenter
git switch main
git pull --ff-only
sudo ./install.sh
```

Der Installer ersetzt die Laufzeitdateien, lässt aber Konfigurationen erhalten.

### Deinstallation meldet „not installed“

Ein wiederholter Aufruf ist erlaubt:

```bash
sudo lac-uninstall
```

Ist LAC bereits entfernt oder unter einem anderen Präfix installiert, erfolgt nur eine entsprechende Meldung. Bei einem benutzerdefinierten Präfix kann aus dem Repository gezielt deinstalliert werden:

```bash
sudo ./uninstall.sh --prefix /opt/lac
```

### Debug-Ausgabe aktivieren

Setze in der Benutzerkonfiguration:

```ini
DEBUG=true
```

Anschließend LAC neu starten.
