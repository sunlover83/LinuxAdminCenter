# Release-Automation

## Ziel

Linux Admin Center 1.2 automatisiert den bisher manuellen GitHub-Release-Prozess. Ein bereits veröffentlichter Git-Tag soll nach erneuter vollständiger Validierung reproduzierbar in einen GitHub Release mit Debian-Paket und SHA256-Prüfsumme überführt werden.

Der Workflow erstellt bewusst **keinen Git-Tag selbst**. Der Release-Tag bleibt eine explizite, vorgelagerte Freigabeentscheidung.

## Auslöser

Der Workflow `.github/workflows/release.yml` startet bei einem Push eines Tags mit Präfix `v`.

Zulässige Release-Tags werden anschließend strikt geprüft:

```text
vMAJOR.MINOR.PATCH
vMAJOR.MINOR.PATCH-PRERELEASE
```

Beispiele:

```text
v1.2.0
v1.2.0-alpha1
v1.2.0-rc1
```

Ein nur syntaktisch passender Tag reicht nicht aus. Vor einer Veröffentlichung muss der Tag auf exakt denselben Commit zeigen wie der aktuelle Remote-Branch `main`.

## Metadatenprüfung

`scripts/validate_release_metadata.sh` gleicht folgende Werte gegeneinander ab:

- Git-Tag
- `LAC_VERSION` in `src/core/common.sh`
- Debian-Version in `debian/changelog`
- datierter Eintrag in `CHANGELOG.md`
- Versionsangabe in `debian/lac.1`

Für stabile Releases gilt beispielsweise:

```text
Tag:             v1.2.0
LAC_VERSION:     1.2.0
Debian-Version:  1.2.0-1
```

Für Pre-Releases wird die Debian-Tilde verwendet, damit die Vorabversion korrekt vor der finalen Version sortiert:

```text
Tag:             v1.2.0-alpha1
LAC_VERSION:     1.2.0-alpha1
Debian-Version:  1.2.0~alpha1-1
```

Stimmt einer dieser Werte nicht, endet der Workflow vor der Release-Erstellung.

## Qualitäts-Gates

Vor einer Veröffentlichung wiederholt der Release-Workflow die wesentlichen Prüfungen unabhängig von der normalen Pull-Request-CI:

1. vollständige Shell-Testsuite
2. Debian-Paketbau und Paketinhaltstest
3. APT/dpkg-Lifecycle-Test
4. Lintian
5. ShellCheck
6. finaler Paketbau

Dadurch hängt ein Release nicht ausschließlich davon ab, dass ein früherer CI-Lauf erfolgreich war.

## Release-Artefakte

Der Workflow erzeugt im Verzeichnis `dist/`:

```text
linux-admin-center_<Debian-Version>_all.deb
SHA256SUMS
```

`SHA256SUMS` enthält die SHA256-Prüfsumme des exakt veröffentlichten Debian-Pakets.

## Release-Notes

`scripts/generate_release_notes.sh` extrahiert ausschließlich den Abschnitt der zu veröffentlichenden Version aus `CHANGELOG.md`.

Zusätzlich werden die erwarteten Release-Artefakte aufgeführt. Damit bleibt `CHANGELOG.md` die maßgebliche Quelle für die fachlichen Release-Informationen und Release-Notes werden nicht unabhängig davon manuell gepflegt.

## Veröffentlichung

Die eigentliche Veröffentlichung erfolgt mit GitHub CLI:

```text
gh release create
```

Der Workflow verwendet `--verify-tag`. Dadurch bricht GitHub CLI ab, wenn der Tag nicht bereits im Remote-Repository existiert. Der Release-Workflow erzeugt daher auch indirekt keinen fehlenden Tag.

Pre-Release-Tags wie `v1.2.0-alpha1` werden als GitHub Pre-Release veröffentlicht und ausdrücklich nicht als `Latest` markiert. Ein stabiler Tag wie `v1.2.0` wird als normaler Release veröffentlicht.

## Berechtigungen

Das Workflow-weite Standardrecht bleibt:

```yaml
permissions:
  contents: read
```

Nur der eigentliche Release-Job erhält:

```yaml
permissions:
  contents: write
```

Beim Checkout des Release-Jobs wird zusätzlich `persist-credentials: false` gesetzt. Das Schreib-Token wird damit nicht als allgemeines Git-Credential für nachfolgende Shell-Schritte im Workspace bereitgestellt.

Der aktuelle `main`-Commit wird für die Tag-Prüfung gezielt über die GitHub-API abgefragt. Nur die dafür benötigten GitHub-CLI-Schritte sowie die spätere Release-Erstellung erhalten das Job-Token explizit über `GH_TOKEN`.

Damit erhält die normale Ausführung keine weitergehenden Repository-Schreibrechte als für die Release-Erstellung erforderlich, und Git-Schreiboperationen werden nicht unbeabsichtigt durch vom Checkout hinterlegte Zugangsdaten ermöglicht.

## Fehlerverhalten

Der Workflow veröffentlicht keinen Release, wenn unter anderem:

- das Tag-Format ungültig ist
- der Tag nicht auf dem aktuellen `main`-Commit liegt
- Runtime- und Tag-Version voneinander abweichen
- die Debian-Version nicht zur Release-Version passt
- der Changelog-Eintrag fehlt
- die Manpage eine andere Version nennt
- Tests, Paket-Lifecycle, Lintian oder ShellCheck fehlschlagen
- der Remote-Tag für `gh release create --verify-tag` nicht existiert

Eine fehlgeschlagene Release-Automation soll nicht durch Löschen oder automatisches Verschieben eines Tags selbst repariert werden. Tag-Korrekturen bleiben eine bewusste Administratorentscheidung.

## Noch nicht Bestandteil von 1.2.0-alpha1

Kryptografisch signierte Git-Tags oder Release-Artefakt-Attestierungen sind nicht Teil der ersten Ausbaustufe. Die Architektur lässt diese Erweiterungen später zu, ohne den grundlegenden Tag- und Paket-Workflow neu zu entwerfen.
