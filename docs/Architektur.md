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
- Änderungen werden durch ShellCheck und automatisierte Tests abgesichert

## Verzeichnisstruktur

```text
LinuxAdminCenter/
├── .github/workflows/          GitHub-Actions-Workflows
├── .vscode/                    Editor-Empfehlungen und Einstellungen
├── docs/                       Projektdokumentation
├── src/
│   ├── lac.sh                  Einstiegspunkt
│   ├── core/                   Gemeinsame Kernfunktionen
│   └── modules/                Sichtbare Funktionsmodule
└── tests/                      Automatisierte Shell-Tests
```

## Programmstart

Der Einstiegspunkt ist `src/lac.sh`.

Beim Start geschieht Folgendes:

1. Bash aktiviert mit `set -euo pipefail` eine strikte Fehlerbehandlung.
2. Das Verzeichnis des Einstiegsskripts wird bestimmt.
3. Die Core-Dateien und Funktionsmodule werden eingebunden.
4. Die System- und Benutzerkonfiguration wird geladen.
5. Bei einem übergebenen Argument wird der CLI-Modus verwendet.
6. Ohne Argument startet das interaktive Hauptmenü.

Die eingebundenen Dateien definieren ausschließlich Funktionen und gemeinsam verwendete Variablen. Sie starten beim Einbinden keine administrativen Aktionen.

## Core-Schicht

Die Dateien unter `src/core/` stellen gemeinsam genutzte Funktionen bereit.

| Datei | Aufgabe |
|---|---|
| `common.sh` | Version, Codename, Farben, Meldungen, Distributionserkennung und Neustartstatus |
| `config.sh` | Laden und Prüfen der System- und Benutzerkonfiguration |
| `cli.sh` | Verarbeitung der Kommandozeilenoptionen |
| `ui.sh` | Hauptmenü und Navigation im interaktiven Modus |
| `package_manager.sh` | Abstraktion für Update- und Cleanup-Befehle von APT, DNF, Pacman und Zypper |
| `system_metrics.sh` | Ermittlung von System-, Hardware- und Ressourcendaten |
| `hardware_metrics.sh` | Temperaturen, NVIDIA-GPU-Daten, Laufwerke sowie SMART- und NVMe-Gesundheitsstatus |
| `network_metrics.sh` | Netzwerkschnittstellen, IPv4-Adressen, Gateway und DNS-Server |
| `network_diagnostics_metrics.sh` | Gateway-Erkennung sowie Ping-, DNS- und externe Verbindungstests |
| `gaming_metrics.sh` | Sitzung, Desktop, Grafiktreiber, Vulkan, Steam, Proton-Werkzeuge und optionale Gaming-Programme |
| `service_metrics.sh` | Init-System, systemd-Zustand, Dienstzahlen, fehlgeschlagene Units und Bootzeiten |
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
| `gaming_readiness/` | Schreibgeschützte Gaming-Umgebungsanalyse und Gesamtbewertung |
| `service_health/` | Schreibgeschützte systemd-Dienst- und Bootdiagnose mit Gesamtbewertung |

Ein Modul verwendet die Funktionen der Core-Schicht, soll aber möglichst keine Implementierungsdetails eines anderen Funktionsmoduls voraussetzen.

## Gemeinsamer Zustand

Einige Variablen werden absichtlich zwischen den eingebundenen Dateien geteilt:

- `LAC_VERSION` und `LAC_CODENAME`
- `LAC_DEBUG`
- `DISTRO_ID`, `DISTRO_NAME` und `DISTRO_VERSION`
- `PKG_MANAGER`

Die Distributionserkennung setzt diese Werte anhand von `/etc/os-release`. Neue Funktionen sollen ihre Werte nach Möglichkeit als lokale Variablen führen.

Für Tests können einzelne Pfade umgeleitet werden:

- `LAC_PACKAGE_CACHE_DIR` für temporäre Paket-Cache-Verzeichnisse
- `LAC_HOME_DIR` für Proton-Verzeichnistests
- `LAC_PROC_ROOT` für die Init-System-Erkennung ohne Zugriff auf das echte `/proc`

Die Netzwerkdiagnose unterstützt:

- `LAC_DNS_TEST_HOST` für den DNS-Auflösungstest
- `LAC_INTERNET_TEST_TARGET` für den externen Erreichbarkeitstest

Diese Variablen verändern keine Systemkonfiguration und gelten nur für den jeweiligen Prozess.

## Datenfluss

### Systeminformationen

`system_metrics.sh` ermittelt einzelne Messwerte. `system_info.sh` sammelt diese Werte und formatiert die Ausgabe. Der Neustartstatus wird separat über `is_reboot_required` bestimmt.

### Netzwerkinformationen

`network_metrics.sh` liest die verfügbaren Netzwerkdaten. `network_info.sh` stellt sie unabhängig von der allgemeinen Systemübersicht dar.

### Netzwerkdiagnose

1. `network_diagnostics_metrics.sh` prüft die Verfügbarkeit von `ip`, `ping` und `getent`.
2. Die IPv4-Standardroute wird aus `ip -4 route show default` ermittelt.
3. Das Standard-Gateway wird mit einer begrenzten Zahl von Ping-Paketen geprüft.
4. `getent ahosts` prüft die DNS-Auflösung eines konfigurierbaren Testnamens.
5. Ein konfigurierbares externes IP-Ziel wird unabhängig von DNS geprüft.
6. Ping-Ausgaben werden in Status, Paketverlust und durchschnittliche Latenz zerlegt.
7. `network_diagnostics.sh` formatiert die Messwerte und erzeugt eine Gesamtbewertung.
8. Nicht reagierende Ping-Ziele werden mit anderen Ergebnissen abgeglichen, da ICMP blockiert sein kann.

Die Bewertung kennt die Zustände:

- `healthy`: Gateway, DNS und externes Ping-Ziel waren erfolgreich
- `warning`: mindestens ein Test ist unvollständig oder möglicherweise durch ICMP-Filterung beeinflusst
- `failed`: es fehlt beispielsweise ein Standard-Gateway oder DNS und externe Erreichbarkeit sind gleichzeitig ausgefallen

### Hardwarediagnose

1. `hardware_metrics.sh` prüft die Verfügbarkeit der benötigten Diagnosewerkzeuge.
2. `sensors` liefert eine CPU-Temperatur, sofern ein unterstützter Sensor erkannt wird.
3. `nvidia-smi` liefert NVIDIA-GPU-Modell, Temperatur, Auslastung und Speichernutzung.
4. `lsblk` liefert physische Blockgeräte und deren Modelle.
5. Virtuelle ZRAM-Geräte, Partitionen, Loop-Geräte und Datenträger mit null Byte werden ausgeschlossen.
6. `smartctl -H` liefert den SMART-Gesundheitsstatus kompatibler Laufwerke.
7. `nvme smart-log` liefert den Gesundheitsstatus von NVMe-Laufwerken.
8. `hardware_diagnostics.sh` kombiniert die Messwerte zu einer einheitlichen Ausgabe.

### Gaming Readiness

1. `gaming_metrics.sh` ermittelt den Display-Server aus `XDG_SESSION_TYPE`, `WAYLAND_DISPLAY` oder `DISPLAY`.
2. Die Desktop-Umgebung wird aus `XDG_CURRENT_DESKTOP` beziehungsweise `DESKTOP_SESSION` gelesen.
3. `lspci -k` liefert die aktiven Kernel-Treiber erkannter Grafikcontroller.
4. `nvidia-smi` liefert bei NVIDIA-Systemen die Treiberversion.
5. `vulkaninfo --summary` bestätigt die Vulkan-Funktion, sofern das Werkzeug installiert ist.
6. Steam wird als nativer Befehl oder Flatpak-Anwendung erkannt.
7. Bekannte native und Flatpak-Verzeichnisse werden nach benutzerdefinierten Proton-Werkzeugen durchsucht.
8. GameMode, MangoHud und Gamescope werden als optionale Werkzeuge erfasst.
9. `gaming_readiness.sh` formatiert die Werte und erzeugt die Gesamtbewertung.

Die Bewertung kennt `ready`, `limited` und `incomplete`. Fehlt `vulkaninfo`, wird Vulkan als `not verified` bezeichnet und nicht fälschlich als nicht installiert eingestuft.

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

### Updateverwaltung

1. `detect_distribution` erkennt Distribution und Paketmanager.
2. `is_package_manager_supported` prüft die benötigten Programme.
3. `refresh_package_information` aktualisiert die Paketinformationen.
4. `list_available_updates` liefert eine vereinheitlichte Liste.
5. Das Update-Modul zeigt die Liste an oder ruft nach Bestätigung `install_available_updates` auf.

### Systembereinigung

1. `cleanup_metrics.sh` ermittelt Cache-Pfad, Cache-Größe und Journalbelegung.
2. `list_unneeded_packages` vereinheitlicht die paketmanagerspezifische Erkennung nicht mehr benötigter Abhängigkeiten.
3. `print_cleanup_report` kombiniert diese Informationen zu einem schreibgeschützten Bericht.
4. `clean_package_cache` entfernt ausschließlich heruntergeladene Paketdateien.
5. `remove_unneeded_packages` entfernt nur die zuvor vom Paketmanager ermittelten Kandidaten.
6. Das Cleanup-Modul fordert vor schreibenden Aktionen eine Benutzerbestätigung an.

Die CLI-Option `--cleanup-report` ruft ausschließlich den schreibgeschützten Bericht auf. Lösch- und Entfernungsvorgänge sind nicht als direkte CLI-Option verfügbar.

## Sicherheitsgrenzen

### Cleanup

- keine automatische Ausführung beim Programmstart
- keine Journalbereinigung
- keine Entfernung von Repository-Metadaten
- keine Bereinigung beliebiger Benutzer- oder Systemverzeichnisse
- Paket-Cache-Bereinigung erst nach `y`-Bestätigung
- Paketentfernung erst nach Eingabe des exakten Wortes `REMOVE`
- Pacman behält zwei Cache-Versionen pro Paket

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
- kein einzelner fehlgeschlagener Ping-Test wird als sicherer Internetausfall eingestuft

### Gaming Readiness

- keine Installation oder Entfernung von Paketen
- keine Änderungen an Grafiktreibern, Vulkan, Steam oder Proton
- keine automatische Aktivierung optionaler Gaming-Werkzeuge
- keine Anpassung von Startoptionen oder Leistungsprofilen
- keine automatische Verwendung von `sudo`
- Verzeichnissuche nur in bekannten Steam-Pfaden unterhalb des Benutzerverzeichnisses

### Service Health

- keine Start-, Stopp-, Neustart-, Enable-, Disable- oder Mask-Aktionen
- keine Änderungen an Unit-Dateien oder Boot-Zielen
- keine automatische Verwendung von `sudo`
- ausschließlich lesende `systemctl`- und `systemd-analyze`-Aufrufe
- validierte Service-Namen vor Detailabfragen
- nicht-systemd-Systeme werden ausdrücklich als nicht unterstützt gemeldet

## Rückgabecodes im CLI-Modus

| Code | Bedeutung |
|---:|---|
| `0` | Befehl erfolgreich ausgeführt oder keine Updates verfügbar |
| `1` | Ausführung aufgrund eines Laufzeit- oder Analysefehlers fehlgeschlagen |
| `2` | Ungültige Option oder nicht unterstützter beziehungsweise nicht verfügbarer Paketmanager |
| `10` | Updates wurden gefunden |

Der Rückgabecode `10` erlaubt die Verwendung der Updateprüfung in weiteren Skripten, ohne eine gefundene Aktualisierung als technischen Fehler zu behandeln.

## Erweiterung der Anwendung

Ein neuer Funktionsbereich sollte grundsätzlich aus folgenden Bestandteilen bestehen:

1. Core-Funktionen zur Datenermittlung, falls diese auch anderweitig nutzbar sind
2. ein Modul unter `src/modules/<name>/`
3. Einbindung in `src/lac.sh`
4. optionaler Menüeintrag in `src/core/ui.sh`
5. optionale CLI-Option in `src/core/cli.sh`
6. passende Tests unter `tests/`
7. Aktualisierung von README, Dokumentation und Changelog

Neue schreibende Funktionen benötigen zusätzlich eine separate Sicherheitsbewertung, eine Vorschau der betroffenen Objekte und eine ausdrückliche Bestätigung vor jeder Veränderung.
