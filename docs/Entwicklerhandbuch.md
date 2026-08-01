# Entwicklerhandbuch

## Ziel

Dieses Dokument beschreibt die Arbeitsweise für Änderungen am Linux Admin Center. Es ergänzt die technische Übersicht in `Architektur.md` und konzentriert sich auf Entwicklung, Tests und Pull Requests.

## Entwicklungsumgebung

Empfohlene Werkzeuge:

- Git
- Bash ab Version 4.3
- ShellCheck
- VSCodium oder Visual Studio Code
- die in `.vscode/extensions.json` empfohlenen Erweiterungen

Repository aktualisieren:

```bash
cd ~/Projekte/LinuxAdminCenter
git switch main
git pull
```

Für Änderungen wird ein eigener Branch verwendet:

```bash
git switch -c feature/kurze-beschreibung
```

## Projektstruktur

```text
src/lac.sh                  Einstiegspunkt
src/core/                   gemeinsam genutzte Funktionen
src/modules/                sichtbare Funktionsbereiche
tests/                      automatisierte Tests
docs/                       Dokumentation
.github/workflows/          automatisierte GitHub-Prüfungen
```

Die detaillierte Zuordnung der Dateien ist in `Architektur.md` beschrieben.

## Bash-Konventionen

### Grundregeln

- Dateien beginnen mit `#!/usr/bin/env bash`.
- Einrückung erfolgt mit vier Leerzeichen.
- Variablen werden grundsätzlich in Anführungszeichen verwendet.
- Funktionsvariablen werden mit `local` deklariert.
- Arrays werden verwendet, wenn mehrere getrennte Werte verarbeitet werden.
- Befehle werden vor ihrer Verwendung bei Bedarf mit `command -v` geprüft.
- Administrative Aktionen müssen sichtbar sein und dürfen nicht unerwartet ausgeführt werden.
- Installationen oder andere verändernde Aktionen benötigen eine ausdrückliche Bestätigung.

### Strikte Fehlerbehandlung

Der Einstiegspunkt und die Testskripte verwenden:

```bash
set -euo pipefail
```

Eingebundene Core- und Moduldateien setzen diese Optionen nicht erneut, da sie im Kontext des aufrufenden Skripts laufen.

### Ausgabe

Gemeinsame Statusmeldungen werden über folgende Funktionen ausgegeben:

- `log_info`
- `log_debug`
- `log_success`
- `log_warning`
- `log_error`

Für den nicht interaktiven CLI-Modus werden normale `printf`-Ausgaben und aussagekräftige Rückgabecodes bevorzugt.

### Gemeinsam verwendete Variablen

Globale Variablen sollen auf Werte beschränkt bleiben, die tatsächlich mehrere Dateien benötigen. Aktuell betrifft dies insbesondere Version, Konfiguration, Distribution und Paketmanager.

Wenn ShellCheck eine absichtlich gemeinsam verwendete Variable nicht erkennen kann, muss die Ausnahme möglichst eng begrenzt und kommentiert werden.

## ShellCheck

Die Projektdatei `.shellcheckrc` sorgt dafür, dass eingebundene Dateien relativ zum geprüften Skript aufgelöst und verfolgt werden.

Vollständige Prüfung:

```bash
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
```

Neue pauschale Deaktivierungen sollen vermieden werden. Eine Regel darf nur lokal deaktiviert werden, wenn der Grund direkt an der betroffenen Stelle dokumentiert ist.

## Automatisierte Tests

Alle Tests starten:

```bash
bash tests/run_tests.sh
```

Der Test-Runner führt jede Datei mit dem Muster `tests/*_test.sh` aus und beendet sich beim ersten fehlgeschlagenen Test.

### Aufbau eines Tests

Ein Testskript soll:

1. mit `set -euo pipefail` starten
2. temporäre Dateien über `mktemp -d` anlegen
3. temporäre Daten mit `trap` entfernen
4. externe Programme bei Bedarf über ein temporäres `PATH` mocken
5. verständliche PASS- und FAIL-Meldungen ausgeben
6. mit Status `1` enden, falls mindestens ein Test fehlgeschlagen ist

### Benennung

```text
<funktionsbereich>_test.sh
```

Beispiele:

- `cli_test.sh`
- `config_test.sh`
- `network_metrics_test.sh`
- `package_manager_test.sh`

## Neuen Funktionsbereich hinzufügen

1. Wiederverwendbare Mess- oder Hilfsfunktionen unter `src/core/` ergänzen.
2. Das sichtbare Modul unter `src/modules/<name>/<name>.sh` erstellen.
3. Beide Dateien in der erforderlichen Reihenfolge in `src/lac.sh` einbinden.
4. Bei Bedarf einen Menüeintrag in `src/core/ui.sh` ergänzen.
5. Bei Bedarf eine einzelne CLI-Option in `src/core/cli.sh` ergänzen.
6. Tests für Core-Funktionen, Modulverhalten und CLI-Ausgabe erstellen.
7. README, Dokumentation und Changelog aktualisieren.

Ein Funktionsmodul soll nicht direkt von einem anderen Funktionsmodul abhängen. Gemeinsam benötigte Logik gehört in die Core-Schicht.

## Paketmanager erweitern

Für einen zusätzlichen Paketmanager müssen mindestens diese Funktionen erweitert werden:

- `detect_distribution`
- `is_package_manager_supported`
- `refresh_package_information`
- `list_available_updates`
- `install_available_updates`

Die Ausgabe von `list_available_updates` muss eine Zeile pro Paket liefern. Besondere erfolgreiche Rückgabecodes eines Paketmanagers müssen explizit behandelt und getestet werden.

## Versionierung und Changelog

Die Versionsangaben befinden sich in `src/core/common.sh`:

```bash
readonly LAC_VERSION="..."
readonly LAC_CODENAME="..."
```

Bei einer Versionsänderung müssen mindestens folgende Stellen geprüft werden:

- `src/core/common.sh`
- `tests/cli_test.sh`
- `README.md`
- `CHANGELOG.md`

Neue Änderungen werden zunächst unter `[Unreleased]` dokumentiert. Bei einer Versionsanhebung werden die Einträge in einen datierten Versionsabschnitt verschoben.

## Pull-Request-Checkliste

Vor dem Push:

```bash
bash tests/run_tests.sh
shellcheck src/lac.sh src/core/*.sh src/modules/*/*.sh tests/*.sh
git status --short
```

Der Pull Request sollte enthalten:

- kurze Beschreibung der Änderung
- Grund für die Änderung
- Auswirkungen auf Nutzer oder Entwickler
- durchgeführte Tests
- bekannte Einschränkungen

GitHub Actions führt Tests und ShellCheck zusätzlich automatisch aus. Ein fehlgeschlagener Workflow muss vor dem Merge untersucht werden.
