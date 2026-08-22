# Architektur des Linux Admin Center

## Zielsetzung

Linux Admin Center (LAC) ist eine modulare Bash-Anwendung für wiederkehrende Administrationsaufgaben auf Linux-Desktop-Systemen. Die Anwendung bietet sowohl ein interaktives Terminalmenü als auch einzelne Kommandozeilenoptionen.

Die Architektur verfolgt folgende Grundsätze:

- administrative Aktionen bleiben sichtbar und nachvollziehbar
- gemeinsam genutzte Funktionen werden zentral bereitgestellt
- Funktionen zur Datenermittlung sind von der Darstellung getrennt
- neue Funktionsbereiche werden als eigenständige Module ergänzt
- schreibende Aktionen benötigen eine bewusste Benutzerbestätigung
- Diagnosemodule bleiben grundsätzlich schreibgeschützt
- fehlende Werkzeuge werden als Zustand behandelt und nicht durch automatische Installationen ersetzt
- Installation und Deinstallation verwenden klar begrenzte, reproduzierbare Zielpfade
- die dokumentierte Bash-Mindestversion wird vor dem Laden der übrigen Laufzeitmodule geprüft
- Distributionen werden über `ID` und `ID_LIKE` aus `/etc/os-release` Paketmanager-Familien zugeordnet
- Ausgaben, deren Reihenfolge Teil des sichtbaren oder getesteten Verhaltens ist, werden locale-unabhängig erzeugt
- Änderungen werden durch ShellCheck, automatisierte Tests und Multi-Distribution-Portabilitätsprüfungen abgesichert

## Verzeichnisstruktur

```text
LinuxAdminCenter/
├── .github/workflows/          GitHub-Actions-Workflows
├── .vscode/                    Editor-Empfehlungen und Einstellungen
├── config/                     Beispielkonfiguration
├── docs/                       Projektdokumentation
├── install.sh                  Systeminstallation und DESTDIR-Staging
├── uninstall.sh                Kontrollierte Deinstallation
├── src/
│   ├── lac.sh                  Einstiegspunkt
│   ├── core/                   Gemeinsame Kernfunktionen
│   └── modules/                Sichtbare Funktionsmodule
└── tests/                      Automatisierte Shell-Tests
```

## Installations- und Deployment-Schicht

Ab Version `0.9.0-alpha` kann LAC systemweit installiert werden. Die Deployment-Schicht besteht aus den beiden eigenständigen Root-Skripten `install.sh` und `uninstall.sh`. Sie ist bewusst von der Laufzeitlogik unter `src/` getrennt.

### Standardlayout

Bei einer Standardinstallation mit `PREFIX=/usr/local` werden folgende Ziele verwendet:

| Ziel | Inhalt |
|---|---|
| `/usr/local/bin/lac` | kleiner Launcher für die installierte Anwendung |
| `/usr/local/bin/lac-uninstall` | Launcher für den installierten Uninstaller |
| `/usr/local/lib/linux-admin-center/` | vollständiger Laufzeitbaum aus `src/` |
| `/usr/local/share/linux-admin-center/` | Beispielkonfiguration und installierter Uninstaller |
| `/usr/local/share/doc/linux-admin-center/` | README, Changelog, Lizenz und Markdown-Dokumentation |

Der installierte Befehl `lac` enthält keine Kopie der Programmlogik. Er bestimmt sein eigenes `bin`-Verzeichnis, leitet daraus das Installationspräfix ab und startet anschließend:

```text
<PREFIX>/lib/linux-admin-center/lac.sh
```

Dadurch funktioniert dasselbe Launcher-Prinzip sowohl unter `/usr/local` als auch unter einem benutzerdefinierten Präfix wie `/opt/lac`.

`lac-uninstall` verwendet dieselbe Präfixableitung und startet den unterhalb des Präfixes installierten Uninstaller. Das Quell-Repository wird für eine spätere Deinstallation deshalb nicht benötigt.

### PREFIX und DESTDIR

`PREFIX` beschreibt den späteren Laufzeitpfad der Installation. Standard ist:

```text
/usr/local
```

Der Installer akzeptiert zusätzlich `--prefix` und lässt ausschließlich absolute Präfixe zu. `PREFIX=/` sowie Werte mit `.`- oder `..`-Pfadkomponenten werden ausdrücklich abgelehnt.

`DESTDIR` ist ein vorgeschaltetes Staging-Verzeichnis. Es verändert nicht die späteren Laufzeitpfade, sondern legt die Dateien unter einem temporären Root ab. Beispiel:

```text
DESTDIR=/tmp/pkg-root
PREFIX=/usr
```

führt beim Paketbau zu:

```text
/tmp/pkg-root/usr/bin/lac
/tmp/pkg-root/usr/lib/linux-admin-center/
```

Diese Trennung entspricht dem üblichen Modell vieler Linux-Paketsysteme und bildet die Grundlage für spätere `.deb`-, `.rpm`- oder andere distributionsspezifische Pakete.

Ist `DESTDIR` gesetzt, kann die Installation ohne Root-Rechte getestet werden. Ohne `DESTDIR` verlangt die Deployment-Schicht explizite Root-Ausführung, ruft `sudo` aber niemals selbst auf. Relative Staging-Pfade, `DESTDIR=/` sowie `.`- und `..`-Pfadkomponenten werden abgelehnt.

### Reinstallation und veraltete Dateien

Eine Installation aus einer neueren LAC-Version ersetzt die verwalteten Runtime-, Shared- und Dokumentationsbäume vollständig. Dadurch können Dateien, die in einer neuen Version aus dem Projekt entfernt oder umbenannt wurden, nicht als veraltete Reste in der Installation verbleiben.

Aktive Konfigurationen liegen bewusst außerhalb dieser verwalteten Bäume:

```text
/etc/lac/lac.conf
$HOME/.config/lac/lac.conf
```

Sie werden durch Installation, Reinstallation und Deinstallation nicht erstellt, überschrieben oder entfernt.

## Programmstart

Der eigentliche Anwendungseinstiegspunkt ist `src/lac.sh`. Bei einer installierten Version befindet sich derselbe Laufzeitbaum unter `<PREFIX>/lib/linux-admin-center/` und wird über den `lac`-Launcher gestartet.

Beim Start geschieht Folgendes:

1. Bash aktiviert mit `set -euo pipefail` eine strikte Fehlerbehandlung.
2. Das Verzeichnis des Einstiegsskripts wird bestimmt.
3. `core/common.sh` wird eingebunden.
4. `require_supported_bash` prüft die Mindestversion Bash 4.3; eine ältere Bash beendet LAC mit Status `2`, bevor die übrigen Module geladen werden.
5. Die restlichen Core-Dateien und Funktionsmodule werden eingebunden.
6. Die System- und Benutzerkonfiguration wird geladen. Fehlt ein Benutzerkonfigurationspfad, weil weder `LAC_USER_CONFIG`, `XDG_CONFIG_HOME` noch `HOME` verfügbar ist, arbeitet LAC mit den Standardwerten weiter.
7. Bei einem übergebenen Argument wird der CLI-Modus verwendet.
8. Ohne Argument startet das interaktive Hauptmenü.

Die eingebundenen Dateien definieren ausschließlich Funktionen und gemeinsam verwendete Variablen. Sie starten beim Einbinden keine administrativen Aktionen.

## Core-Schicht

Die Dateien unter `src/core/` stellen gemeinsam genutzte Funktionen bereit.

| Datei | Aufgabe |
|---|---|
| `common.sh` | Version, Codename, Bash-Mindestversion, Farben, Meldungen, Distributionserkennung und Neustartstatus |
| `config.sh` | Laden und Prüfen der System- und Benutzerkonfiguration sowie sichere Ermittlung des Benutzerkonfigurationspfads |
| `cli.sh` | Verarbeitung der Kommandozeilenoptionen |
| `ui.sh` | Hauptmenü und Navigation im interaktiven Modus |
| `package_manager.sh` | Abstraktion für Update- und Cleanup-Befehle von APT, DNF, Pacman und Zypper sowie funktionsspezifische Fähigkeitsprüfungen |
| `system_metrics.sh` | Ermittlung von System-, Hardware- und Ressourcendaten |
| `hardware_metrics.sh` | Temperaturen, NVIDIA-GPU-Daten, Laufwerke sowie SMART- und NVMe-Gesundheitsstatus |
| `network_metrics.sh` | Netzwerkschnittstellen, IPv4-Adressen, Gateway und DNS-Server |
| `network_diagnostics_metrics.sh` | Gateway-Erkennung sowie validierte Ping-, DNS- und externe Verbindungstests |
| `gaming_metrics.sh` | Sitzung, Desktop, Grafiktreiber, Vulkan-Grundstatus, Steam, benutzerdefinierte Proton-Werkzeuge und optionale Gaming-Programme |
| `gaming_diagnostics_metrics.sh` | Vulkan-Details, 32-Bit-Vulkan-Prüfung, Steam-Bibliotheken, Proton-Runtimes, Kompatibilitätspräfixe und Gamescope-Version |
| `service_metrics.sh` | Init-System, systemd-Zustand, Dienstzahlen, fehlgeschlagene Units und Bootzeiten |
| `self_check_metrics.sh` | LAC-Runtime, Installationsart, Launcher, Konfiguration, Kern- und optionale Werkzeuge sowie Paketmanagerstatus |
| `cleanup_metrics.sh` | Paket-Cache-Pfad, Cache-Größe und Journalbelegung |

## Funktionsmodule

Die Dateien unter `src/modules/` bilden die sichtbaren Funktionsbereiche der Anwendung.

| Modul | Aufgabe |
|---|---|
| `update/` | Updates suchen, anzeigen und nach Bestätigung installieren |
| `cleanup/` | Cleanup-Bericht, Paket-Cache-Bereinigung und bestätigte Paketentfernung |
| `system_info/` | Allgemeine System- und Hardwareinformationen anzeigen |
| `network_info/` | Netzwerkinformationen anzeigen |
| `network_diagnostics/` | Schreibgeschützte aktive Netzwerkdiagnose und Gesamtbewertung |
| `hardware_diagnostics/` | Schreibgeschützte Hardware- und Laufwerksdiagnose |
| `gaming_readiness/` | Schnelle schreibgeschützte Gaming-Grundprüfung und Gesamtbewertung |
| `gaming_diagnostics/` | Detaillierte schreibgeschützte Vulkan-, Steam- und Proton-Kompatibilitätsdiagnose |
| `service_health/` | Schreibgeschützte systemd-Dienst- und Bootdiagnose mit Gesamtbewertung |
| `self_check/` | Schreibgeschützte Prüfung der LAC-Laufzeit und ihrer Abhängigkeiten |

Ein Modul verwendet die Funktionen der Core-Schicht, soll aber möglichst keine Implementierungsdetails eines anderen Funktionsmoduls voraussetzen. Gemeinsam benötigte Ermittlung gehört in die Core-Schicht.

## Gemeinsamer Zustand

Einige Variablen werden absichtlich zwischen den eingebundenen Dateien geteilt:

- `LAC_VERSION` und `LAC_CODENAME`
- `LAC_MIN_BASH_MAJOR` und `LAC_MIN_BASH_MINOR`
- `LAC_DEBUG`
- `DISTRO_ID`, `DISTRO_NAME` und `DISTRO_VERSION`
- `PKG_MANAGER`

Die Distributionserkennung liest `/etc/os-release`. Zuerst wird `ID` ausgewertet. Ist die Distribution kein direkt unterstützter Basistyp, wird `ID_LIKE` tokenweise ausgewertet und einer unterstützten Paketmanager-Familie zugeordnet. Dadurch müssen Derivate nicht einzeln im Code gepflegt werden.

Aktuelle Familienzuordnung:

| Familie aus `ID`/`ID_LIKE` | Paketmanager |
|---|---|
| Debian oder Ubuntu | APT |
| Fedora, RHEL oder CentOS | DNF |
| Arch | Pacman |
| openSUSE, SLES oder SUSE | Zypper |

Neue Funktionen sollen ihre Werte nach Möglichkeit als lokale Variablen führen.

Für Tests können einzelne Pfade umgeleitet werden:

- `LAC_PACKAGE_CACHE_DIR` für temporäre Paket-Cache-Verzeichnisse
- `LAC_HOME_DIR` für Steam- und Proton-Verzeichnistests
- `LAC_PROC_ROOT` für die Init-System-Erkennung ohne Zugriff auf das echte `/proc`
- `LAC_ROOT_DIR` für Tests der bekannten 32-Bit-Vulkan-Bibliothekspfade ohne Zugriff auf das echte Root-Dateisystem

Für Installation und Paketbau existieren zusätzlich:

- `PREFIX` für das logische Installationspräfix
- `DESTDIR` als vorgeschaltetes Staging-Root

Die Netzwerkdiagnose unterstützt:

- `LAC_DNS_TEST_HOST` für den DNS-Auflösungstest
- `LAC_INTERNET_TEST_TARGET` für den externen Erreichbarkeitstest

Diese Variablen verändern keine dauerhafte Systemkonfiguration und gelten nur für den jeweiligen Prozess beziehungsweise Installationsvorgang.

## Datenfluss

### Installation und Reinstallation

1. `install.sh` bestimmt das Quell-Repository relativ zu seinem eigenen Pfad.
2. Argumente und Umgebungsvariablen für `PREFIX` und `DESTDIR` werden geprüft.
3. Unsichere Zielwerte wie Root-Ziele, relative Pfade sowie `.`- oder `..`-Komponenten werden vor jeder Dateioperation abgelehnt.
4. Bei einer echten Systeminstallation ohne `DESTDIR` werden Root-Rechte vorausgesetzt.
5. Bestehende verwaltete LAC-Bäume werden ausschließlich an den erwarteten LAC-spezifischen Zielpfaden entfernt.
6. Der gesamte Inhalt von `src/` wird als Laufzeitbaum installiert.
7. Dateirechte werden vereinheitlicht; nur `lac.sh` wird im Runtime-Baum ausführbar gesetzt.
8. Beispielkonfiguration, Uninstaller, Lizenz und Dokumentation werden in die Shared-Pfade kopiert.
9. Die Launcher `lac` und `lac-uninstall` werden erzeugt und ausführbar gesetzt.
10. Aktive System- und Benutzerkonfigurationen werden nicht berührt.

### Deinstallation

1. `uninstall.sh` validiert `PREFIX` und optional `DESTDIR` mit denselben Regeln wie der Installer.
2. Bei echter Systemdeinstallation werden Root-Rechte vorausgesetzt.
3. Die beiden Launcher werden entfernt, falls sie vorhanden sind.
4. Runtime-, Shared- und Dokumentationsbäume werden nur entfernt, wenn ihre Pfade auf die erwarteten LAC-spezifischen Suffixe enden.
5. `/etc/lac` und Benutzerkonfigurationen werden ausdrücklich nicht entfernt.
6. Ein erneuter Aufruf nach bereits abgeschlossener Deinstallation ist erlaubt und meldet lediglich, dass keine Installation vorhanden ist.

### Systeminformationen

`system_metrics.sh` ermittelt einzelne Messwerte. `system_info.sh` sammelt diese Werte und formatiert die Ausgabe. Der Neustartstatus wird separat über `is_reboot_required` bestimmt.

### Storage Analysis

Storage Analysis trennt die Ermittlung lokaler Dateisystemdaten von Formatierung und Bewertung:

1. `src/core/storage_metrics.sh` prüft die Verfügbarkeit von `df`.
2. `df` wird mit `LC_ALL=C`, lokaler Einschränkung, einer festen Blockgröße von 1024 Byte und einer expliziten GNU-Ausgabespaltenliste aufgerufen.
3. Die Core-Schicht normalisiert jeden Datensatz in Quelle, Dateisystemtyp, gesamte, belegte und verfügbare KiB, Kapazitätsprozent, gesamte, belegte und verfügbare Inodes, Inode-Prozent und Einhängepunkt. Die drei Textfelder werden intern prozentkodiert, sodass die pipe-getrennten Feldgrenzen auch bei einem zulässigen `|` oder `%` im Dateisystemnamen erhalten bleiben.
4. Kernel-, Pseudo-, RAM- und Steuerdateisysteme, bekannte schreibgeschützte Image-Dateisysteme sowie ausgewählte virtuelle FUSE-Dateisysteme werden anhand ihres Typs ausgeschlossen. `df --local` schließt zusätzlich entfernte Dateisysteme aus.
5. Kapazitätsdatensätze ohne numerische oder sinnvolle Gesamtwerte werden verworfen. Liefert ein ansonsten gültiges Dateisystem keine aussagekräftigen Inode-Werte, werden nur seine Inode-Felder als `not-applicable` normalisiert.
6. Die Datensätze werden mit `LC_ALL=C` deterministisch nach Einhängepunkt und Quelle sortiert.
7. `src/modules/storage_analysis/storage_analysis.sh` bewertet Kapazität und Inodes getrennt, dekodiert die Textfelder vor der Anzeige, formatiert Größen und erzeugt den Gesamtbericht.

Die Bewertung verwendet feste Standardgrenzen:

- `healthy`: alle verfügbaren Prozentwerte liegen unter 80%
- `warning`: mindestens ein Kapazitäts- oder Inode-Wert liegt bei mindestens 80%, aber unter 90%
- `critical`: mindestens ein Kapazitäts- oder Inode-Wert liegt bei mindestens 90%
- `incomplete`: `df` fehlt oder ist fehlgeschlagen, es existiert kein auswertbarer Datensatz oder ein übergebener Bewertungswert ist unvollständig

Die Statuspriorität lautet `critical`, `warning`, `incomplete`, `healthy`. Nicht anwendbare Inode-Werte führen allein nicht zu `incomplete`.

CLI-Option `-s` beziehungsweise `--storage-analysis` und Menüpunkt 11 verwenden dieselben Core- und Modulfunktionen. Der Collector basiert bewusst auf den GNU-Coreutils-Optionen von `df`, die auf Debian, Fedora, Arch Linux und openSUSE zum unterstützten Systemumfang gehören. Andere `df`-Implementierungen werden nicht zugesichert.

Storage Analysis ist fachlich von anderen Bereichen getrennt: Hardware Diagnostics prüft physische Laufwerksgesundheit, System Cleanup verwaltet eng begrenzte und bestätigungspflichtige Bereinigungen. Verzeichnis-Hotspots, Dateisuche, Dateisystemreparatur und andere mögliche spätere Speicherwartung gehören nicht zum Analysemodul.

### Netzwerkinformationen

`network_metrics.sh` liest die verfügbaren Netzwerkdaten. `network_info.sh` stellt sie unabhängig von der allgemeinen Systemübersicht dar.

### Netzwerkdiagnose

1. `network_diagnostics_metrics.sh` prüft die Verfügbarkeit von `ip`, `ping` und `getent`.
2. Die IPv4-Standardroute wird aus `ip -4 route show default` ermittelt.
3. Testziele werden geprüft; optionsähnliche Werte mit führendem `-` und Werte mit Whitespace werden nicht an Systemprogramme weitergegeben.
4. Das Standard-Gateway wird mit einer begrenzten Zahl von Ping-Paketen geprüft.
5. `getent ahosts` prüft die DNS-Auflösung eines konfigurierbaren Testnamens.
6. Ein konfigurierbares externes IP-Ziel wird unabhängig von DNS geprüft.
7. Ping-Ausgaben werden in Status, Paketverlust und durchschnittliche Latenz zerlegt.
8. `network_diagnostics.sh` formatiert die Messwerte und erzeugt eine Gesamtbewertung.
9. Nicht reagierende Ping-Ziele werden mit anderen Ergebnissen abgeglichen, da ICMP blockiert sein kann.

Die Bewertung kennt die Zustände:

- `healthy`: Gateway, DNS und externes Ping-Ziel waren erfolgreich
- `warning`: mindestens ein Test ist unvollständig oder möglicherweise durch ICMP-Filterung beeinflusst
- `failed`: es fehlt beispielsweise ein Standard-Gateway oder DNS und externe Erreichbarkeit sind gleichzeitig ausgefallen

Die CLI-Option `--network-diagnostics` und der interaktive Menüpunkt verwenden dieselben Mess- und Bewertungsfunktionen.

### Hardwarediagnose

1. `hardware_metrics.sh` prüft die Verfügbarkeit der benötigten Diagnosewerkzeuge.
2. `sensors` liefert eine CPU-Temperatur, sofern ein unterstützter Sensor erkannt wird.
3. `nvidia-smi` liefert NVIDIA-GPU-Modell, Temperatur, Auslastung und Speichernutzung.
4. `lsblk` liefert physische Blockgeräte und deren Modelle.
5. Virtuelle ZRAM-Geräte, Partitionen, Loop-Geräte und Datenträger mit null Byte werden ausgeschlossen.
6. `smartctl -H` liefert den SMART-Gesundheitsstatus kompatibler Laufwerke.
7. `nvme smart-log` liefert den Gesundheitsstatus von NVMe-Laufwerken.
8. `hardware_diagnostics.sh` kombiniert die Messwerte zu einer einheitlichen Ausgabe.

Die CLI-Option `--hardware-diagnostics` und der interaktive Menüpunkt verwenden dieselben schreibgeschützten Messfunktionen.

### Gaming Readiness

Gaming Readiness ist absichtlich eine schnelle Grundprüfung und bleibt von der detaillierten Diagnose getrennt.

1. `gaming_metrics.sh` ermittelt den Display-Server aus `XDG_SESSION_TYPE`, `WAYLAND_DISPLAY` oder `DISPLAY`.
2. Die Desktop-Umgebung wird aus `XDG_CURRENT_DESKTOP` beziehungsweise `DESKTOP_SESSION` gelesen.
3. `lspci -k` liefert die aktiven Kernel-Treiber erkannter Grafikcontroller.
4. `nvidia-smi` liefert bei NVIDIA-Systemen die Treiberversion.
5. `vulkaninfo --summary` bestätigt die Vulkan-Funktion, sofern das Werkzeug installiert ist.
6. Steam wird als nativer Befehl oder Flatpak-Anwendung erkannt.
7. Bekannte native und Flatpak-Verzeichnisse werden nach benutzerdefinierten Proton-Werkzeugen durchsucht. Die sichtbare Reihenfolge wird mit `LC_ALL=C sort -u` deterministisch gehalten.
8. GameMode, MangoHud und Gamescope werden als optionale Werkzeuge erfasst.
9. `gaming_readiness.sh` formatiert die Werte und erzeugt die Gesamtbewertung.

Die Bewertung kennt:

- `ready`: grafische Sitzung, Grafiktreiber, bestätigtes Vulkan und Steam sind verfügbar
- `limited`: eine Kernvoraussetzung fehlt oder konnte nicht bestätigt werden
- `incomplete`: mehrere Kernvoraussetzungen fehlen oder die grafische Basis konnte nicht ermittelt werden

Fehlt `vulkaninfo`, wird Vulkan als `not verified` bezeichnet und nicht fälschlich als nicht installiert eingestuft.

Die CLI-Option `--gaming-readiness` und der interaktive Menüpunkt verwenden dieselben Funktionen.

### Gaming Diagnostics

Gaming Diagnostics baut auf den Grundfunktionen aus `gaming_metrics.sh` auf, führt aber eine tiefere Kompatibilitätsanalyse durch.

1. `get_vulkan_status` prüft weiterhin, ob `vulkaninfo --summary` erfolgreich ausgeführt werden kann.
2. `gaming_diagnostics_metrics.sh` liest zusätzlich die Vulkan-Instance-Version aus der Summary.
3. GPU-Blöcke der Summary werden in strukturierte Datensätze mit Gerätename, Treibername und Vulkan-API-Version zerlegt.
4. Für native Steam-Installationen werden bekannte Pfade auf einen 32-Bit-Vulkan-Loader geprüft.
5. Bei Flatpak-Steam wird die 32-Bit-Grafikunterstützung als `managed by Flatpak` behandelt, da die Runtime und Grafik-Erweiterungen nicht sinnvoll über Host-i386-Pfade bewertet werden können.
6. `get_steam_launch_target` unterscheidet native Steam-Ausführung und Flatpak-Anwendung.
7. Bekannte Steam-Wurzeln werden gesucht und über `pwd -P` kanonisiert, damit symbolische Links auf dieselbe Installation nicht doppelt erscheinen.
8. `steamapps/libraryfolders.vdf` liefert zusätzliche vom Benutzer konfigurierte Steam-Bibliotheken; auch diese Pfade werden kanonisiert, dedupliziert und mit `LC_ALL=C` deterministisch sortiert.
9. In `steamapps/common` werden Verzeichnisse `Proton*` nur dann als gebündelte Proton-Runtime gewertet, wenn darin eine `proton`-Datei vorhanden ist.
10. Benutzerdefinierte Kompatibilitätswerkzeuge aus `compatibilitytools.d` werden als `custom` ergänzt; die kombinierte Runtime-Liste wird locale-unabhängig sortiert.
11. Numerische Verzeichnisse unter `steamapps/compatdata` werden bibliotheksübergreifend als eindeutige Kompatibilitätspräfixe gezählt.
12. GameMode, MangoHud, MangoApp und Gamescope werden als Integrationswerkzeuge erfasst.
13. `gamescope --version` liefert ausschließlich Versionsinformationen und startet keine Sitzung.
14. `gaming_diagnostics.sh` formatiert die Daten und erzeugt die Gesamtbewertung.

Die Bewertung kennt:

- `healthy`: Vulkan und Steam sind verfügbar, 32-Bit-Grafikunterstützung ist bestätigt beziehungsweise wird von Flatpak verwaltet und mindestens eine Proton-Runtime wurde erkannt
- `warning`: Vulkan und Steam sind verfügbar, aber 32-Bit-Vulkan-Unterstützung oder Proton-Runtimes konnten nicht bestätigt werden
- `incomplete`: Vulkan oder Steam stehen für die Detaildiagnose nicht zur Verfügung

Die Bewertung von `not verified` ist bewusst konservativ. Der Zustand ist kein Nachweis dafür, dass eine Funktion tatsächlich fehlt.

Die CLI-Option `--gaming-diagnostics` und Menüpunkt 9 verwenden dieselben Ermittlungs- und Bewertungsfunktionen.

### Service Health

1. `service_metrics.sh` ermittelt Prozess 1 über `ps` und verwendet für Tests beziehungsweise als Fallback `${LAC_PROC_ROOT:-/proc}/1/comm`.
2. Das Init-System wird als `systemd`, `sysvinit`, `openrc`, `runit`, `s6` oder `unknown` klassifiziert.
3. Service Health wertet aktuell ausschließlich systemd-Systeme vollständig aus.
4. `systemctl is-system-running` liefert den systemweiten Zustand.
5. `systemctl list-units --type=service --all` liefert aktive, inaktive und fehlgeschlagene Dienstzahlen.
6. Eine getrennte Abfrage listet fehlgeschlagene Services.
7. Dienstnamen werden vor `systemctl show` validiert.
8. `systemctl show` liefert Beschreibung sowie Load-, Active- und Sub-State einer fehlgeschlagenen Unit.
9. `systemd-analyze time` liefert die gesamte Startzeit.
10. `systemd-analyze blame` liefert die langsamsten Service-Units.
11. `service_health.sh` formatiert alle Werte und erzeugt eine Gesamtbewertung.

Die Bewertung kennt die Zustände:

- `healthy`: systemd meldet `running` und es wurden keine fehlgeschlagenen Dienste erkannt
- `warning`: systemd meldet `initializing`, `starting` oder `degraded`, oder mindestens ein Dienst ist fehlgeschlagen
- `failed`: systemd meldet `maintenance`, `offline` oder `stopping`, wichtige Messwerte fehlen oder das Init-System wird nicht unterstützt

Inaktive Dienste werden nicht als Fehler bewertet. Die Bootzeit und die Liste langsamer Dienste dienen als Diagnosehinweise und lösen allein keine Warnung aus.

Die CLI-Option `--service-health` und der interaktive Menüpunkt verwenden dieselben Mess- und Bewertungsfunktionen.

### LAC Self Check

1. `self_check_metrics.sh` ermittelt Bash-Kompatibilität, Runtime-Wurzel und Installationsart.
2. Alle von `lac.sh` eingebundenen Core- und Moduldateien werden auf Lesbarkeit geprüft.
3. Bei systemweiter Installation werden `lac` und `lac-uninstall` auf Ausführbarkeit geprüft.
4. System- und Benutzerkonfigurationsdateien werden als `available`, `defaults` oder `not readable` eingestuft; eine fehlende Konfigurationsdatei ist kein Fehler.
5. Kernwerkzeuge wie `awk`, `sed`, `find`, `sort`, `tr`, `uname`, `df`, `du` und `hostname` werden geprüft.
6. Optionale beziehungsweise funktionsspezifische Werkzeuge wie `ip`, `lsblk`, `vulkaninfo`, `systemctl`, `checkupdates` oder `paccache` werden separat angezeigt.
7. Der erkannte Paketmanager wird geprüft, ohne optionale Diagnosewerkzeuge automatisch zu installieren.
8. `self_check.sh` erzeugt daraus die Gesamtbewertung.

Die Bewertung kennt:

- `healthy`: LAC-Runtime, Launcher, Konfigurationsbehandlung und Kernwerkzeuge sind einsatzbereit
- `warning`: beispielsweise ein Kernwerkzeug, eine lesbare Konfiguration oder ein nutzbarer Paketmanager fehlt
- `failed`: die Bash-Version ist zu alt, Runtime-Dateien fehlen oder eine systemweite Installation hat unvollständige Launcher

Fehlende optionale Diagnosewerkzeuge beeinflussen die Gesamtbewertung nicht.

Die CLI-Option `--self-check` und Menüpunkt 10 verwenden dieselben Ermittlungs- und Bewertungsfunktionen.

### Updateverwaltung

1. `detect_distribution` erkennt Distribution und Paketmanager-Familie über `ID` und optional `ID_LIKE`.
2. `is_package_manager_supported` prüft nur den grundlegenden Paketmanager.
3. `is_update_package_manager_supported` prüft zusätzlich update-spezifische Voraussetzungen. Bei APT gehört dazu `apt`; bei Pacman `checkupdates`.
4. `refresh_package_information` aktualisiert die Paketinformationen beziehungsweise nutzt beim Pacman-Workflow die separate `checkupdates`-Datenbank.
5. `list_available_updates` liefert eine vereinheitlichte Liste.
6. Das Update-Modul zeigt die Liste an oder ruft nach Bestätigung `install_available_updates` auf.

Die Trennung zwischen Basis- und Update-Fähigkeit verhindert, dass beispielsweise ein Arch-System ohne `checkupdates` vollständig als nicht unterstützter Paketmanager gilt. In diesem Fall ist lediglich die Update-Funktion nicht verfügbar; andere Pacman-basierte Funktionen bleiben nutzbar.

### Systembereinigung

1. `cleanup_metrics.sh` ermittelt Cache-Pfad, Cache-Größe und Journalbelegung.
2. `list_unneeded_packages` vereinheitlicht die paketmanagerspezifische Erkennung nicht mehr benötigter Abhängigkeiten.
3. `print_cleanup_report` kombiniert diese Informationen zu einem schreibgeschützten Bericht.
4. `clean_package_cache` entfernt ausschließlich heruntergeladene Paketdateien. Repository-Metadaten bleiben erhalten.
5. `remove_unneeded_packages` entfernt nur die zuvor vom Paketmanager ermittelten Kandidaten.
6. Das Cleanup-Modul fordert vor schreibenden Aktionen eine Benutzerbestätigung an.

Die CLI-Option `--cleanup-report` ruft ausschließlich den schreibgeschützten Bericht auf. Lösch- und Entfernungsvorgänge sind nicht als direkte CLI-Option verfügbar.

## Sicherheitsgrenzen

### Installation und Deinstallation

- keine automatische Verwendung von `sudo`; Root-Rechte müssen vom Benutzer ausdrücklich bereitgestellt werden
- `PREFIX` muss absolut sein und darf nicht `/` sein
- ein gesetztes `DESTDIR` muss absolut sein und darf nicht `/` sein
- `PREFIX` und `DESTDIR` dürfen keine `.`- oder `..`-Pfadkomponenten enthalten
- rekursive Löschungen sind zusätzlich an erwartete LAC-spezifische Pfadsuffixe gebunden
- Installation beschränkt sich auf den gewählten Präfixbaum
- aktive System- und Benutzerkonfiguration wird weder erstellt noch überschrieben
- Deinstallation entfernt weder `/etc/lac` noch Benutzerkonfigurationen
- keine automatische Installation von Betriebssystempaketen oder Abhängigkeiten
- Reinstallation ersetzt nur von LAC verwaltete Runtime-, Shared- und Dokumentationsbäume

### Cleanup

- keine automatische Ausführung beim Programmstart
- keine Journalbereinigung
- keine Entfernung von Repository-Metadaten
- keine Bereinigung beliebiger Benutzer- oder Systemverzeichnisse
- Paket-Cache-Bereinigung erst nach `y`-Bestätigung
- Paketentfernung erst nach Eingabe des exakten Wortes `REMOVE`
- Pacman behält zwei Cache-Versionen pro Paket

### Storage Analysis

- vollständig schreibgeschützt und ohne automatische Verwendung von `sudo`
- ausschließlich lesender Aufruf von `df`
- keine Mount-, Unmount-, Remount-, Resize-, Trim-, Repair- oder `fsck`-Befehle
- keine Datei- oder Verzeichnissuche zur Ermittlung von Speicher-Hotspots
- keine Löschung, Verschiebung oder Änderung von Daten
- keine automatische Übergabe erkannter Dateisysteme an System Cleanup
- fehlende Messwerte werden gemeldet und nicht durch zustandsverändernde Prüfungen erzwungen

### Hardwarediagnose

- keine SMART-Selbsttests
- keine Laufwerksreparaturen
- keine Firmwareaktionen
- keine Änderungen an Sensor- oder Lüftereinstellungen
- keine automatische Verwendung von `sudo`
- keine Prüfung virtueller ZRAM-Geräte oder leerer Kartenleser

### Netzwerkdiagnose

- keine Aktivierung oder Deaktivierung von Netzwerkschnittstellen
- keine Änderungen an Adressen, Routingtabellen, Gateways oder DNS
- keine automatische Verwendung von `sudo`
- begrenzte Zahl von Ping-Paketen mit Zeitüberschreitung
- konfigurierbare Testziele werden validiert, bevor sie an `ping` oder `getent` übergeben werden
- kein einzelner fehlgeschlagener Ping-Test wird als sicherer Internetausfall eingestuft

### Gaming Readiness

- keine Installation oder Entfernung von Paketen
- keine Änderungen an Grafiktreibern, Vulkan, Steam oder Proton
- keine automatische Aktivierung optionaler Gaming-Werkzeuge
- keine Anpassung von Startoptionen oder Leistungsprofilen
- keine automatische Verwendung von `sudo`
- Verzeichnissuche nur in bekannten Steam-Pfaden unterhalb des Benutzerverzeichnisses

### Gaming Diagnostics

- keine Installation, Entfernung oder Aktualisierung von Steam, Proton oder Grafikkomponenten
- keine Änderungen an Steam-Bibliotheken, Kompatibilitätsoptionen oder Proton-Präfixen
- keine Änderungen an Vulkan-Loadern, ICD-Dateien oder Grafiktreibern
- keine Spiele, Proton-Runtimes oder Steam-Clients werden zu Testzwecken gestartet
- keine aktiven GameMode-Leistungstests wie `gamemoded -t`
- Gamescope wird ausschließlich mit `--version` abgefragt
- keine automatische Verwendung von `sudo`
- Dateisystemsuche beschränkt sich auf bekannte Steam-Wurzeln und von Steam in `libraryfolders.vdf` konfigurierte Bibliotheken
- 32-Bit-Vulkan-Erkennung ist bei nativer Steam-Installation bewusst heuristisch und wird bei Unsicherheit als `not verified` ausgegeben
- Flatpak-Steam wird nicht anhand der Host-i386-Bibliotheken bewertet

### Service Health

- keine Start-, Stopp-, Neustart-, Enable-, Disable- oder Mask-Aktionen
- keine Änderungen an Unit-Dateien oder Boot-Zielen
- keine automatische Verwendung von `sudo`
- ausschließlich lesende `systemctl`- und `systemd-analyze`-Aufrufe
- validierte Service-Namen vor Detailabfragen
- nicht-systemd-Systeme werden ausdrücklich als nicht unterstützt gemeldet

### LAC Self Check

- vollständig schreibgeschützt
- keine automatische Installation, Reparatur oder Entfernung von Abhängigkeiten
- fehlende optionale Werkzeuge werden nur gemeldet
- Konfigurationsdateien werden nicht erzeugt oder verändert
- Runtime-Dateien und Launcher werden nur auf Vorhandensein beziehungsweise Les-/Ausführbarkeit geprüft

## Rückgabecodes im CLI-Modus

| Code | Bedeutung |
|---:|---|
| `0` | Befehl erfolgreich ausgeführt oder keine Updates verfügbar |
| `1` | Ausführung aufgrund eines Laufzeit- oder Analysefehlers fehlgeschlagen |
| `2` | Ungültige Option, nicht unterstützte Umgebung oder fehlende Voraussetzung für die angeforderte Funktion |
| `10` | Updates wurden gefunden |

Der Rückgabecode `10` erlaubt die Verwendung der Updateprüfung in weiteren Skripten, ohne eine gefundene Aktualisierung als technischen Fehler zu behandeln.

## Tests und Qualitätssicherung

Die Tests unter `tests/` verwenden für Systembefehle nach Möglichkeit Mocks und temporäre Verzeichnisse. Dadurch können Parser und Bewertungslogik reproduzierbar geprüft werden, ohne den Testrechner zu verändern.

Test-Fixtures verwenden neutrale, plausible Beispielwerte. Persönliche Home-Pfade, Hostnamen, reale Hardwarekonfigurationen oder andere maschinenspezifische Fingerprints sollen nicht in Testdaten oder Beispielausgaben übernommen werden.

Der Installationstest verwendet ein temporäres `DESTDIR`. Dadurch werden echte Systempfade weder beschrieben noch gelöscht. Geprüft werden unter anderem:

- Ausführungsrechte der Repository-Installer
- Erzeugung der beiden installierten Launcher
- Kopieren des Runtime-Baums, der Lizenz und der Dokumentation
- Ausführung der installierten Anwendung
- Entfernung absichtlich angelegter veralteter Runtime-Dateien bei Reinstallation
- vollständige Entfernung verwalteter Installationsdateien
- Erhalt einer vorhandenen Systemkonfiguration
- sicherer mehrfacher Uninstall-Aufruf
- Ablehnung relativer, Root- und traversal-artiger Präfix- und Staging-Werte

Für Gaming Diagnostics werden unter anderem geprüft:

- Parsing von Vulkan-Instance- und GPU-Daten
- konservative Behandlung fehlender Werkzeuge
- native 32-Bit-Vulkan-Pfade
- Flatpak-spezifische 32-Bit-Grafikbewertung
- Kanonisierung äquivalenter Steam-Wurzeln
- zusätzliche Steam-Bibliotheken
- gebündelte und benutzerdefinierte Proton-Runtimes
- eindeutige Compatdata-Zählung
- locale-unabhängige Sortierung
- Gamescope-Versionsausgabe
- CLI- und Menüintegration

Für Storage Analysis werden unter anderem geprüft:

- GNU-`df`-Aufruf mit festem Locale und explizitem Spaltenschema
- Normalisierung von ext4-, XFS-, Btrfs-, vfat- sowie LUKS-/LVM-Beispieldaten
- getrennte Kapazitäts- und Inode-Bewertung an den Grenzen 80% und 90%
- Statuspriorität und Behandlung nicht anwendbarer Inode-Werte
- Filterung von Pseudo-, Image- und ausgewählten FUSE-Dateisystemen
- deterministische Sortierung und Fehlerzustände bei fehlendem oder fehlschlagendem `df`
- CLI-, Menü-, Self-Check-, Installations- und Paketintegration

`tests/common_test.sh` prüft die Bash-Mindestversion sowie die direkte und über `ID_LIKE` abgeleitete Paketmanager-Zuordnung. `tests/config_test.sh` prüft auch Umgebungen ohne `HOME`. `tests/package_manager_test.sh` trennt grundlegende Paketmanager-Fähigkeiten von update-spezifischen Helfern.

Die gesamte Testsuite wird mit `tests/run_tests.sh` ausgeführt. ShellCheck prüft `install.sh`, `uninstall.sh`, Einstiegspunkt, Core-Schicht, Module und Tests.

GitHub Actions verwendet zwei Ebenen:

1. Ubuntu führt die vollständige Testsuite und ShellCheck aus.
2. Debian stable, Fedora, Arch Linux und openSUSE Tumbleweed führen `tests/portability_test.sh` in Containern aus.

Der Portabilitätstest prüft zusätzlich die tatsächlich laufende Distribution und verifiziert, dass LAC sie einem vorhandenen unterstützten Paketmanager zuordnet. Danach folgen Bash-Syntaxprüfung und ein distributionsunabhängiger Testumfang für Konfiguration, Installation, Netzwerk-Hardening, Paketmanager-Abstraktion, Storage Analysis und Self Check. Der Installationstest ruft dabei den installierten Storage-Analysis-CLI-Pfad gegen das reale `df` des jeweiligen Containers auf; ergänzende Mocks decken reproduzierbar unterstützte Dateisystemvarianten und Fehlerzustände ab.

## Erweiterung der Anwendung

Ein neuer Funktionsbereich sollte grundsätzlich aus folgenden Bestandteilen bestehen:

1. Core-Funktionen zur Datenermittlung, falls diese auch anderweitig nutzbar sind
2. ein Modul unter `src/modules/<name>/`
3. Einbindung in `src/lac.sh`
4. optionaler Menüeintrag in `src/core/ui.sh`
5. optionale CLI-Option in `src/core/cli.sh`
6. passende Tests unter `tests/`
7. Aktualisierung von README, Dokumentation und Changelog

Neue Dateien im Laufzeitbaum unter `src/` werden durch den Installer automatisch in zukünftige Installationen übernommen. Dateien außerhalb von `src/`, die für eine installierte Laufzeit benötigt werden, müssen dagegen ausdrücklich in `install.sh` aufgenommen und durch `installation_test.sh` abgesichert werden.

Neue Cleanup-Kategorien benötigen zusätzlich eine separate Sicherheitsbewertung, eine Vorschau der betroffenen Objekte und eine ausdrückliche Bestätigung vor jeder Veränderung. Neue Diagnosemodule sollen ohne Root-Rechte arbeiten, sofern der zugrunde liegende Messwert das zulässt, und dürfen fehlende Informationen nicht durch schreibende oder zustandsverändernde Tests erzwingen.
