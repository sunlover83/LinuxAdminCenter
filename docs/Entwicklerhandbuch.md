# Entwicklerhandbuch

## Ziel

Dieses Dokument beschreibt die Arbeitsweise für Änderungen am Linux Admin Center. Es ergänzt die technische Übersicht in `Architektur.md` und konzentriert sich auf Entwicklung, Tests, Installation und Pull Requests.

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
git pull --ff-only
```

Für Änderungen wird ein eigener Branch verwendet:

```bash
git switch -c feature/kurze-beschreibung
```

## Projektstruktur

```text
install.sh                  Systeminstallation und DESTDIR-Staging
uninstall.sh                kontrollierte Deinstallation
src/lac.sh                  Einstiegspunkt
src/core/                   gemeinsam genutzte Funktionen
src/modules/                sichtbare Funktionsbereiche
tests/                      automatisierte Tests
docs/                       Dokumentation
config/                     Beispielkonfiguration
.github/workflows/          automatisierte GitHub-Prüfungen
```

Die detaillierte Zuordnung der Dateien und die installierten Zielpfade sind in `Architektur.md` beschrieben.

## Bash-Konventionen

### Grundregeln

- Dateien beginnen mit `#!/usr/bin/env bash`.
- Einrückung erfolgt mit vier Leerzeichen.
- Variablen werden grundsätzlich in Anführungszeichen verwendet.
- Funktionsvariablen werden mit `local` deklariert.
- Arrays werden verwendet, wenn mehrere getrennte Werte verarbeitet werden.
- Befehle werden vor ihrer Verwendung bei Bedarf mit `command -v` geprüft.
- Administrative Aktionen müssen sichtbar sein und dürfen nicht unerwartet ausgeführt werden.
- Installationen, Löschungen oder andere verändernde Aktionen benötigen eine ausdrückliche Benutzeraktion.
- Für schreibende Funktionen muss nach Möglichkeit zuerst eine schreibgeschützte Vorschau existieren.
- Skripte dürfen `sudo` nicht selbst aufrufen, wenn der Benutzer die erforderlichen Rechte auch beim Start des Skripts bereitstellen kann.

### Strikte Fehlerbehandlung

Der Einstiegspunkt, Installer, Uninstaller und die Testskripte verwenden:

```bash
set -euo pipefail
```

Eingebundene Core- und Moduldateien setzen diese Optionen nicht erneut, da sie im Kontext des aufrufenden Skripts laufen.

### Ausgabe

Gemeinsame Statusmeldungen der Anwendung werden über folgende Funktionen ausgegeben:

- `log_info`
- `log_debug`
- `log_success`
- `log_warning`
- `log_error`

Für den nicht interaktiven CLI-Modus sowie Installer und Uninstaller werden normale `printf`-Ausgaben und aussagekräftige Rückgabecodes bevorzugt.

### Gemeinsam verwendete Variablen

Globale Variablen sollen auf Werte beschränkt bleiben, die tatsächlich mehrere Dateien benötigen. Aktuell betrifft dies insbesondere Version, Konfiguration, Distribution und Paketmanager.

Wenn ShellCheck eine absichtlich gemeinsam verwendete Variable nicht erkennen kann, muss die Ausnahme möglichst eng begrenzt und kommentiert werden.

`LAC_PACKAGE_CACHE_DIR` ist eine optionale Test- und Diagnosevariable. Sie überschreibt den automatisch ermittelten Paket-Cache-Pfad und darf nicht als dauerhaft notwendige Benutzerkonfiguration vorausgesetzt werden.

`PREFIX` und `DESTDIR` gehören zur Installations- und Paketbauschicht. Sie sind keine LAC-Laufzeitkonfiguration und dürfen nicht in `lac.conf` übernommen werden.

## ShellCheck

Die Projektdatei `.shellcheckrc` sorgt dafür, dass eingebundene Dateien relativ zum geprüften Skript aufgelöst und verfolgt werden.

Vollständige Prüfung:

```bash
shellcheck \
    install.sh \
    uninstall.sh \
    src/lac.sh \
    src/core/*.sh \
    src/modules/*/*.sh \
    tests/*.sh
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

Verändernde Systembefehle werden in Tests immer gemockt oder auf ein temporäres Ziel umgeleitet. Tests dürfen weder Pakete installieren beziehungsweise entfernen noch echte System-Caches oder Installationspfade verändern.

### Benennung

```text
<funktionsbereich>_test.sh
```

Beispiele:

- `cli_test.sh`
- `cleanup_test.sh`
- `config_test.sh`
- `installation_test.sh`
- `network_metrics_test.sh`
- `package_manager_test.sh`

## Installation und Deployment entwickeln

Die Dateien `install.sh` und `uninstall.sh` bilden eine eigene Deployment-Schicht. Änderungen daran benötigen dieselbe Sorgfalt wie Cleanup-Code, weil sie rekursiv Dateien unter systemweiten Pfaden verwalten.

### Installationsmodell

Der Installer verwendet zwei getrennte Pfadkonzepte:

- `PREFIX`: logischer späterer Installationspfad, standardmäßig `/usr/local`
- `DESTDIR`: optional vorgeschaltetes Staging-Root für Tests und Paketbau

Beispiel für eine Test- oder Paketinstallation:

```bash
DESTDIR=/tmp/lac-root bash install.sh --prefix /usr
```

Der resultierende Dateibaum liegt dann unter `/tmp/lac-root/usr/...`, während die späteren Laufzeitpfade im Paket weiterhin `/usr/...` sind.

### Pflichtanforderungen für Installer-Änderungen

- `PREFIX` muss absolut sein.
- `PREFIX=/` bleibt verboten.
- `DESTDIR` muss, wenn gesetzt, absolut sein.
- Das Skript darf `sudo` nicht selbst aufrufen.
- Bei echter Systeminstallation ohne `DESTDIR` müssen Root-Rechte explizit geprüft werden.
- Rekursive Löschungen dürfen nur auf fest definierte LAC-Zielbäume angewendet werden.
- Reinstallation muss veraltete Runtime-Dateien zuverlässig entfernen.
- Aktive Konfiguration unter `/etc/lac` und `$HOME/.config/lac` darf nicht überschrieben werden.
- Neue Laufzeitdateien unter `src/` werden automatisch mitkopiert; zusätzliche Dateien außerhalb von `src/` müssen ausdrücklich in den Installer aufgenommen werden.

### Pflichtanforderungen für Uninstaller-Änderungen

- Nur LAC-eigene Launcher, Runtime-, Shared- und Dokumentationspfade dürfen entfernt werden.
- Aktive System- und Benutzerkonfiguration muss erhalten bleiben.
- Ein erneuter Uninstall-Aufruf muss sicher sein.
- Benutzerdefinierte Präfixe müssen mit denselben Regeln wie im Installer behandelt werden.
- Änderungen an Löschpfaden benötigen einen passenden Test in `installation_test.sh`.

### Installationstest

`tests/installation_test.sh` verwendet ausschließlich ein temporäres `DESTDIR`. Dadurch kann der vollständige Installations- und Deinstallationsablauf ohne Root-Rechte und ohne Änderungen am Testrechner geprüft werden.

Der Test muss mindestens absichern:

- installierte Launcher
- installierten Runtime-Baum
- Beispielkonfiguration und Dokumentation
- Ausführung des installierten `lac`-Launchers
- Entfernung veralteter Runtime-Dateien bei Reinstallation
- Entfernung verwalteter Dateien beim Uninstall
- Erhalt aktiver Konfiguration
- idempotente Deinstallation
- Ablehnung unsicherer Präfixe

Bei späteren `.deb`-, `.rpm`- oder anderen Paketformaten soll diese `DESTDIR`-fähige Installationslogik möglichst wiederverwendet werden, statt separate Dateilisten mit abweichendem Verhalten aufzubauen.

## Neuen Funktionsbereich hinzufügen

1. Wiederverwendbare Mess- oder Hilfsfunktionen unter `src/core/` ergänzen.
2. Das sichtbare Modul unter `src/modules/<name>/<name>.sh` erstellen.
3. Beide Dateien in der erforderlichen Reihenfolge in `src/lac.sh` einbinden.
4. Bei Bedarf einen Menüeintrag in `src/core/ui.sh` ergänzen.
5. Bei Bedarf eine einzelne CLI-Option in `src/core/cli.sh` ergänzen.
6. Tests für Core-Funktionen, Modulverhalten und CLI-Ausgabe erstellen.
7. README, Dokumentation und Changelog aktualisieren.

Ein Funktionsmodul soll nicht direkt von einem anderen Funktionsmodul abhängen. Gemeinsam benötigte Logik gehört in die Core-Schicht.

Neue Dateien unter `src/` werden durch die aktuelle Installation automatisch in den Runtime-Baum übernommen. Benötigt ein neues Modul zusätzliche Dateien außerhalb von `src/`, muss auch die Deployment-Schicht angepasst und getestet werden.

## Paketmanager erweitern

Für einen zusätzlichen Paketmanager müssen mindestens diese Update-Funktionen geprüft werden:

- `detect_distribution`
- `is_package_manager_supported`
- `refresh_package_information`
- `list_available_updates`
- `install_available_updates`

Für die Cleanup-Unterstützung müssen zusätzlich geprüft werden:

- `is_package_cache_cleanup_supported`
- `list_unneeded_packages`
- `clean_package_cache`
- `remove_unneeded_packages`
- `get_package_cache_directory`

Die Ausgabe von `list_available_updates` und `list_unneeded_packages` muss jeweils eine Zeile pro Paket liefern. Besondere erfolgreiche Rückgabecodes eines Paketmanagers müssen explizit behandelt und getestet werden.

## Cleanup-Funktionen entwickeln

Cleanup-Code benötigt eine zusätzliche Sicherheitsprüfung.

### Pflichtanforderungen

- Zuerst muss eine schreibgeschützte Ermittlung der betroffenen Objekte möglich sein.
- Der Nutzer muss die vollständige Liste oder den betroffenen Pfad vor der Aktion sehen.
- Schreibende Aktionen dürfen nicht über den allgemeinen Analyse-CLI-Aufruf ausgelöst werden.
- Die Bestätigung muss zur möglichen Auswirkung passen. Paketentfernungen verlangen derzeit das exakte Wort `REMOVE`.
- Shell-Arrays müssen verwendet werden, wenn Paketnamen an einen Löschbefehl übergeben werden.
- Ungeprüfte Wortaufteilung durch Konstruktionen wie `command $(other-command)` ist zu vermeiden.
- Metadaten, Journale oder Benutzerdateien dürfen nur nach eigener Sicherheitsbewertung in einen späteren Cleanup-Umfang aufgenommen werden.

### Aktuelle Paketmanager-Strategien

| Paketmanager | Kandidaten ermitteln | Paket-Cache bereinigen | Kandidaten entfernen |
|---|---|---|---|
| APT | simuliertes `autoremove` | `apt-get clean` | `apt-get autoremove` |
| DNF | `repoquery --unneeded` | `dnf clean packages` | `dnf autoremove` |
| Pacman | `pacman -Qtdq` | `paccache -rk2` | `pacman -Rns` mit Array |
| Zypper | `packages --unneeded` | standardmäßiges `zypper clean` | `zypper remove --clean-deps` mit Array |

Neue oder geänderte Befehle müssen gegen die offizielle Dokumentation des jeweiligen Paketmanagers geprüft werden.

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
- relevante Dateien unter `docs/`

Neue Änderungen werden zunächst unter `[Unreleased]` dokumentiert. Bei einer Versionsanhebung werden die Einträge in einen datierten Versionsabschnitt verschoben.

Bei einer Release-Version mit Installationsänderungen muss zusätzlich eine Installation über temporäres `DESTDIR` und nach Möglichkeit vor dem Tag eine reale Installation auf einem unterstützten System geprüft werden.

## Pull-Request-Checkliste

Vor dem Push:

```bash
bash tests/run_tests.sh
shellcheck \
    install.sh \
    uninstall.sh \
    src/lac.sh \
    src/core/*.sh \
    src/modules/*/*.sh \
    tests/*.sh
git status --short
```

Der Pull Request sollte enthalten:

- kurze Beschreibung der Änderung
- Grund für die Änderung
- Auswirkungen auf Nutzer oder Entwickler
- durchgeführte Tests
- bekannte Einschränkungen
- bei Cleanup- oder Deployment-Änderungen die ausdrücklich geltenden Sicherheitsgrenzen

GitHub Actions führt Tests und ShellCheck zusätzlich automatisch aus. Ein fehlgeschlagener Workflow muss vor dem Merge untersucht werden.
