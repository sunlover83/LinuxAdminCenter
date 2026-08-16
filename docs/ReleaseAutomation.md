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
v1.2.0-alpha2
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
Tag:             v1.2.0-alpha2
LAC_VERSION:     1.2.0-alpha2
Debian-Version:  1.2.0~alpha2-1
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

Der Debian-Build selbst behält die native Debian-Dateibenennung. Für ein Pre-Release kann sie beispielsweise so aussehen:

```text
linux-admin-center_1.2.0~alpha2-1_all.deb
```

GitHub normalisiert Sonderzeichen in Release-Asset-Dateinamen. Deshalb bereitet `scripts/prepare_release_assets.sh` das Paket **vor** dem Upload auf einen GitHub-sicheren, deterministischen Namen vor:

```text
linux-admin-center_1.2.0-alpha2-1_all.deb
SHA256SUMS
```

Dabei wird ausschließlich der Dateiname des Release-Artefakts geändert. Die Paketmetadaten enthalten weiterhin die Debian-Version `1.2.0~alpha2-1`.

`SHA256SUMS` wird erst nach dieser Umbenennung erzeugt und referenziert deshalb exakt den Dateinamen, den Benutzer aus dem GitHub Release herunterladen. Ein normales `sha256sum -c SHA256SUMS` funktioniert damit direkt mit den heruntergeladenen Dateien.

Stabile Paketnamen enthalten keine Tilde und bleiben unverändert.

## Release-Notes

`scripts/generate_release_notes.sh` extrahiert ausschließlich den Abschnitt der zu veröffentlichenden Version aus `CHANGELOG.md`.

Zusätzlich werden die tatsächlich erwarteten, GitHub-sicheren Release-Artefakte aufgeführt. Damit bleibt `CHANGELOG.md` die maßgebliche Quelle für die fachlichen Release-Informationen und Release-Notes werden nicht unabhängig davon manuell gepflegt.

## Veröffentlichung

Die eigentliche Veröffentlichung erfolgt mit GitHub CLI:

```text
gh release create
```

Der Workflow verwendet `--verify-tag`. Dadurch bricht GitHub CLI ab, wenn der Tag nicht bereits im Remote-Repository existiert. Der Release-Workflow erzeugt daher auch indirekt keinen fehlenden Tag.

Pre-Release-Tags wie `v1.2.0-alpha2` werden als GitHub Pre-Release veröffentlicht und ausdrücklich nicht als `Latest` markiert. Ein stabiler Tag wie `v1.2.0` wird als normaler Release veröffentlicht.

Nach der Veröffentlichung prüft der Workflow aktiv, dass genau das vorbereitete Debian-Paket und `SHA256SUMS` unter den erwarteten Namen vorhanden sind und dass der Pre-Release-Status dem Tag entspricht. Eine bloße erfolgreiche Upload-Antwort reicht damit nicht mehr als Release-Verifikation aus.

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
- das Release-Paket vor dem Upload nicht eindeutig bestimmt werden kann
- der Remote-Tag für `gh release create --verify-tag` nicht existiert

Nach einem erfolgreichen Upload schlägt die Verifikation zusätzlich fehl, wenn GitHub andere Assetnamen zurückliefert oder der erwartete Pre-Release-Status nicht gesetzt ist.

Eine fehlgeschlagene Release-Automation soll nicht durch Löschen oder automatisches Verschieben eines Tags selbst repariert werden. Tag-Korrekturen bleiben eine bewusste Administratorentscheidung.

## Noch nicht Bestandteil von 1.2.0

Kryptografisch signierte Git-Tags oder Release-Artefakt-Attestierungen sind nicht Teil der aktuellen Ausbaustufe. Die Architektur lässt diese Erweiterungen später zu, ohne den grundlegenden Tag- und Paket-Workflow neu zu entwerfen.
