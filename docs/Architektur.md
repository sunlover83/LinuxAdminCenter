# Architektur des Linux Admin Center

## Zielsetzung

Linux Admin Center (LAC) ist eine modulare Bash-Anwendung für wiederkehrende Administrationsaufgaben auf Linux-Desktop-Systemen. Die Anwendung bietet sowohl ein interaktives Terminalmenü als auch einzelne Kommandozeilenoptionen.

Die Architektur verfolgt folgende Grundsätze:

- administrative Aktionen bleiben sichtbar und nachvollziehbar
- gemeinsam genutzte Funktionen werden zentral bereitgestellt
- Funktionen zur Datenermittlung sind von der Darstellung getrennt
- neue Funktionsbereiche werden als eigenständige Module ergänzt
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
| `package_manager.sh` | Abstraktion für APT, DNF, Pacman und Zypper |
| `system_metrics.sh` | Ermittlung von System-, Hardware- und Ressourcendaten |
| `network_metrics.sh` | Ermittlung von Netzwerkschnittstellen, IPv4-Adressen, Gateway und DNS-Servern |

## Funktionsmodule

Die Dateien unter `src/modules/` bilden die sichtbaren Funktionsbereiche der Anwendung.

| Modul | Aufgabe |
|---|---|
| `update/` | Updates suchen, anzeigen und nach Bestätigung installieren |
| `system_info/` | Allgemeine System- und Hardwareinformationen anzeigen |
| `network_info/` | Netzwerkinformationen anzeigen |

Ein Modul verwendet die Funktionen der Core-Schicht, soll aber möglichst keine Implementierungsdetails eines anderen Funktionsmoduls voraussetzen.

## Gemeinsamer Zustand

Einige Variablen werden absichtlich zwischen den eingebundenen Dateien geteilt:

- `LAC_VERSION` und `LAC_CODENAME`
- `LAC_DEBUG`
- `DISTRO_ID`, `DISTRO_NAME` und `DISTRO_VERSION`
- `PKG_MANAGER`

Die Distributionserkennung setzt diese Werte anhand von `/etc/os-release`. Nach Möglichkeit sollen neue Funktionen ihre Werte als lokale Variablen führen und globale Variablen nur verwenden, wenn sie für mehrere Module benötigt werden.

## Datenfluss

### Systeminformationen

`system_metrics.sh` ermittelt einzelne Messwerte. `system_info.sh` sammelt diese Werte und formatiert die Ausgabe. Der Neustartstatus wird separat über `is_reboot_required` bestimmt.

### Netzwerkinformationen

`network_metrics.sh` liest die verfügbaren Netzwerkdaten. `network_info.sh` stellt sie unabhängig von der allgemeinen Systemübersicht dar.

### Updateverwaltung

1. `detect_distribution` erkennt Distribution und Paketmanager.
2. `is_package_manager_supported` prüft die benötigten Programme.
3. `refresh_package_information` aktualisiert die Paketinformationen.
4. `list_available_updates` liefert eine vereinheitlichte Liste.
5. Das Update-Modul zeigt die Liste an oder ruft nach Bestätigung `install_available_updates` auf.

## Rückgabecodes im CLI-Modus

| Code | Bedeutung |
|---:|---|
| `0` | Befehl erfolgreich ausgeführt oder keine Updates verfügbar |
| `1` | Ausführung aufgrund eines Laufzeitfehlers fehlgeschlagen |
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
