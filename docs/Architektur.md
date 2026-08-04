# Architektur des Linux Admin Center

## Zielsetzung

Linux Admin Center (LAC) ist eine modulare Bash-Anwendung für wiederkehrende Administrationsaufgaben auf Linux-Desktop-Systemen. Die Anwendung bietet sowohl ein interaktives Terminalmenü als auch einzelne Kommandozeilenoptionen.

Die Architektur verfolgt folgende Grundsätze:

- administrative Aktionen bleiben sichtbar und nachvollziehbar
- gemeinsam genutzte Funktionen werden zentral bereitgestellt
- Funktionen zur Datenermittlung sind von der Darstellung getrennt
- neue Funktionsbereiche werden als eigenständige Module ergänzt
- schreibende Aktionen benötigen eine bewusste Benutzerbestätigung
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
│   └── modules/                Funktionsmodule
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
| `hardware_metrics.sh` | Ermittlung von Temperaturen, NVIDIA-GPU-Daten, Laufwerken sowie SMART- und NVMe-Gesundheitsstatus |
| `network_metrics.sh` | Ermittlung von Netzwerkschnittstellen, IPv4-Adressen, Gateway und DNS-Servern |
| `network_diagnostics_metrics.sh` | Gateway-Erkennung sowie Ping-, DNS- und externe Verbindungstests |
| `cleanup_metrics.sh` | Ermittlung von Paket-Cache-Pfad, Cache-Größe und Journalbelegung |

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

Ein Modul verwendet die Funktionen der Core-Schicht, soll aber möglichst keine Implementierungsdetails eines anderen Funktionsmoduls voraussetzen.

## Gemeinsamer Zustand

Einige Variablen werden absichtlich zwischen den eingebundenen Dateien geteilt:

- `LAC_VERSION` und `LAC_CODENAME`
- `LAC_DEBUG`
- `DISTRO_ID`, `DISTRO_NAME` und `DISTRO_VERSION`
- `PKG_MANAGER`

Die Distributionserkennung setzt diese Werte anhand von `/etc/os-release`. Nach Möglichkeit sollen neue Funktionen ihre Werte als lokale Variablen führen und globale Variablen nur verwenden, wenn sie für mehrere Module benötigt werden.

Für Tests kann `LAC_PACKAGE_CACHE_DIR` gesetzt werden, um den Paket-Cache-Pfad auf ein temporäres Verzeichnis umzuleiten. Im normalen Betrieb ist diese Variable nicht erforderlich.

Die Netzwerkdiagnose unterstützt zwei optionale Umgebungsvariablen:

- `LAC_DNS_TEST_HOST` überschreibt den Namen für den DNS-Auflösungstest
- `LAC_INTERNET_TEST_TARGET` überschreibt die externe IP für den Erreichbarkeitstest

Die Variablen verändern keine Systemkonfiguration und gelten nur für den jeweiligen Prozess.

## Datenfluss

### Systeminformationen

`system_metrics.sh` ermittelt einzelne Messwerte. `system_info.sh` sammelt diese Werte und formatiert die Ausgabe. Der Neustartstatus wird separat über `is_reboot_required` bestimmt.

### Netzwerkinformationen

`network_metrics.sh` liest die verfügbaren Netzwerkdaten. `network_info.sh` stellt sie unabhängig von der allgemeinen Systemübersicht dar.

### Netzwerkdiagnose

1. `network_diagnostics_metrics.sh` prüft die Verfügbarkeit von `ip`, `ping` und `getent`.
2. Die IPv4-Standardroute wird aus der Ausgabe von `ip -4 route show default` ermittelt.
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

Die CLI-Option `--network-diagnostics` und der interaktive Menüpunkt verwenden dieselben schreibgeschützten Messfunktionen.

### Hardwarediagnose

1. `hardware_metrics.sh` prüft die Verfügbarkeit der benötigten Diagnosewerkzeuge.
2. `sensors` liefert eine CPU-Temperatur, sofern ein unterstützter CPU-Sensor erkannt wird.
3. `nvidia-smi` liefert NVIDIA-GPU-Modell, Temperatur, Auslastung und Speichernutzung.
4. `lsblk` liefert physische Blockgeräte und deren Modelle.
5. Virtuelle ZRAM-Geräte, Partitionen, Loop-Geräte und Datenträger mit einer Größe von null Byte werden ausgeschlossen.
6. `smartctl -H` liefert den SMART-Gesundheitsstatus kompatibler Laufwerke.
7. `nvme smart-log` liefert den Gesundheitsstatus von NVMe-Laufwerken.
8. `hardware_diagnostics.sh` kombiniert die Messwerte zu einer einheitlichen Ausgabe.

Die CLI-Option `--hardware-diagnostics` und der interaktive Menüpunkt verwenden dieselben schreibgeschützten Messfunktionen.

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
4. `clean_package_cache` entfernt ausschließlich heruntergeladene Paketdateien. Repository-Metadaten bleiben erhalten.
5. `remove_unneeded_packages` entfernt nur die zuvor vom Paketmanager ermittelten Kandidaten.
6. Das Cleanup-Modul fordert vor schreibenden Aktionen eine Benutzerbestätigung an.

Die CLI-Option `--cleanup-report` ruft ausschließlich den schreibgeschützten Bericht auf. Lösch- und Entfernungsvorgänge sind nicht als direkte CLI-Option verfügbar.

## Sicherheitsgrenzen des Cleanup-Moduls

Die erste Cleanup-Version ist absichtlich konservativ:

- keine automatische Ausführung beim Programmstart
- keine Journalbereinigung
- keine Entfernung von Repository-Metadaten
- keine Bereinigung beliebiger Benutzer- oder Systemverzeichnisse
- Paket-Cache-Bereinigung erst nach `y`-Bestätigung
- Paketentfernung erst nach Eingabe des exakten Wortes `REMOVE`
- Pacman behält zwei Cache-Versionen pro Paket

Diese Grenzen verhindern, dass ein allgemeiner Cleanup-Aufruf unerwartet wichtige Dateien oder Diagnoseinformationen entfernt.

## Sicherheitsgrenzen der Hardwarediagnose

Die Hardwarediagnose ist ausschließlich lesend:

- keine SMART-Selbsttests
- keine Laufwerksreparaturen
- keine Firmwareaktionen
- keine Änderungen an Sensor- oder Lüftereinstellungen
- keine automatische Verwendung von `sudo`
- keine Prüfung virtueller ZRAM-Geräte
- keine Prüfung leerer Kartenleser oder anderer Datenträger mit null Byte

Wenn Laufwerksinformationen administrative Rechte benötigen, wird `requires root` ausgegeben. Der Benutzer entscheidet selbst, ob LAC ausdrücklich mit `sudo` gestartet wird.

## Sicherheitsgrenzen der Netzwerkdiagnose

Die Netzwerkdiagnose ist ausschließlich lesend:

- keine Aktivierung oder Deaktivierung von Netzwerkschnittstellen
- keine Änderungen an IPv4- oder IPv6-Adressen
- keine Änderungen an Routingtabellen oder Standard-Gateways
- keine Änderungen an DNS-Servern oder Resolver-Konfigurationen
- keine automatische Verwendung von `sudo`
- eine begrenzte Zahl von Ping-Paketen mit Zeitüberschreitung
- keine Einstufung eines einzelnen fehlgeschlagenen Ping-Tests als sicherer Internetausfall

Die externe Diagnose erzeugt normalen ICMP-Netzwerkverkehr zu einem konfigurierbaren Testziel. DNS- und Ping-Ziele können über Umgebungsvariablen geändert werden.

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

Neue Cleanup-Kategorien benötigen zusätzlich eine separate Sicherheitsbewertung, eine Vorschau der betroffenen Objekte und eine ausdrückliche Bestätigung vor jeder Veränderung.
