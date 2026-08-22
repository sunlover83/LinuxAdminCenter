# Debian- und Ubuntu-Paketierung

## Status

Linux Admin Center 1.1 erweitert die bisherige manuelle Systeminstallation um ein Debian-Paket für Debian-, Ubuntu- und kompatible APT-basierte Systeme.

Der aktuelle Alpha3-Validierungsstand ist:

```text
LAC:            1.3.0-alpha3 (Storage Analysis)
Debian-Paket:   1.3.0~alpha3-1
Paketname:      linux-admin-center
Architektur:    all
```

Die neueste stabile Paketversion bleibt `1.2.0-1`, bis Alpha3 veröffentlicht und vollständig verifiziert wurde.

Das Paket ist architekturunabhängig, weil LAC aus Bash-Skripten und Dokumentation besteht und keine architekturspezifischen Binärdateien enthält.

## Unterschied zur manuellen Installation

Die bisherige Installation über `install.sh` bleibt erhalten und verwendet standardmäßig `/usr/local`:

```text
/usr/local/bin/lac
/usr/local/bin/lac-uninstall
/usr/local/lib/linux-admin-center/
/usr/local/share/linux-admin-center/
```

Das Debian-Paket wird dagegen durch APT und dpkg verwaltet und installiert nach `/usr`:

```text
/usr/bin/lac
/usr/lib/linux-admin-center/
/usr/share/linux-admin-center/
/usr/share/doc/linux-admin-center/
```

Eine paketverwaltete Installation enthält bewusst keinen Befehl `lac-uninstall`. Sie wird ausschließlich über APT beziehungsweise dpkg entfernt.

## Wechsel von einer manuellen Installation zum Paket

Eine vorhandene manuelle Installation unter `/usr/local` muss vor der Paketinstallation entfernt werden. Das Paket prüft diesen Konflikt vor der Installation und bricht mit einer Anleitung ab, wenn eine manuelle LAC-Installation erkannt wird.

Die manuelle Installation wird entfernt mit:

```bash
sudo /usr/local/bin/lac-uninstall
```

Dabei bleiben die aktive Systemkonfiguration unter `/etc/lac` und die Benutzerkonfiguration unter `$HOME/.config/lac` erhalten.

Eine bereits laufende Shell kann den alten Pfad `/usr/local/bin/lac` noch in ihrem Command-Hash zwischengespeichert haben. Nach der Entfernung der manuellen Installation sollte deshalb einmal ausgeführt werden:

```bash
hash -r
```

Alternativ genügt eine neue Shell-Sitzung. Danach sollte `command -v lac` nach erfolgreicher Paketinstallation `/usr/bin/lac` melden.

Anschließend kann das Debian-Paket installiert werden.

## Build-Voraussetzungen

Auf einem Debian- oder Ubuntu-basierten Entwicklungssystem werden für den Paketbau mindestens die üblichen Debian-Buildwerkzeuge benötigt:

```bash
sudo apt install build-essential debhelper dpkg-dev
```

Für die zusätzliche Paketprüfung wird außerdem Lintian verwendet:

```bash
sudo apt install lintian
```

## Paket lokal bauen

Der wiederverwendbare Build-Helfer erzeugt das Paket standardmäßig im Verzeichnis `dist/`:

```bash
bash scripts/build_debian_package.sh
```

Alternativ kann ein anderes Ausgabeverzeichnis angegeben werden:

```bash
bash scripts/build_debian_package.sh /tmp/lac-packages
```

Der Build verwendet die Debian-Metadaten unter `debian/` und den vorhandenen LAC-Installer mit `DESTDIR` und dem Paketpräfix `/usr`.

Wenn `DEB_BUILD_OPTIONS=nocheck` gesetzt ist, überspringt der Debian-Build die im Paketbau eingebettete vollständige Testsuite. Die GitHub-CI verwendet dies nur bei zusätzlichen Paket-Builds, nachdem die reguläre Testsuite bereits separat erfolgreich gelaufen ist.

## Paket installieren

Ein lokaler Build des aktuellen Validierungsstands verwendet den nativen Debian-Paketnamen:

```text
linux-admin-center_1.3.0~alpha3-1_all.deb
```

Für GitHub Releases wird nur der veröffentlichte Assetname in `linux-admin-center_1.3.0-alpha3-1_all.deb` umgewandelt. Die Paketmetadaten enthalten weiterhin `1.3.0~alpha3-1`.

Installation:

```bash
sudo apt install ./linux-admin-center_1.3.0~alpha3-1_all.deb
```

Danach prüfen:

```bash
hash -r
command -v lac
lac --version
lac --self-check
```

Bei einer Paketinstallation sollte `command -v lac` auf `/usr/bin/lac` zeigen, `lac --version` `Linux Admin Center 1.3.0-alpha3 (Storage Analysis)` ausgeben und der Self Check den Installationstyp `debian-package` melden.

## Paket erneut installieren oder aktualisieren

Ein lokales Paket kann erneut installiert werden mit:

```bash
sudo apt install --reinstall ./linux-admin-center_1.3.0~alpha3-1_all.deb
```

Ein späteres Paket mit höherer Debian-Version kann normal mit `apt install ./<paket>.deb` aktualisiert werden.

Aktive LAC-Konfigurationen werden vom Paket nicht erzeugt oder überschrieben.

## Paket entfernen

Entfernen:

```bash
sudo apt remove linux-admin-center
```

Dabei werden die paketverwalteten LAC-Dateien entfernt. Die Konfiguration unter `/etc/lac` und die Benutzerkonfiguration bleiben erhalten.

## Automatische Prüfungen

Die GitHub-CI prüft für das Debian-Paket zusätzlich zur normalen LAC-Testsuite:

- erfolgreichen Paketbau mit `dpkg-buildpackage`
- Paketname, Version und `Architecture: all`
- vollständigen Runtime-Inhalt
- Abwesenheit des manuellen `lac-uninstall`
- Erkennung als `debian-package` im Self Check
- gesunden Self Check aus dem Paketinhalt
- Blockierung einer Paketinstallation über einer vorhandenen manuellen `/usr/local`-Installation
- Installation über APT in einem sauberen Debian-Container
- erneute Paketinstallation
- Erhalt vorhandener Konfiguration
- Entfernung über APT
- Entfernung aller paketverwalteten LAC-Dateien
- Lintian-Prüfung ohne Error- oder Warning-Befunde
- ShellCheck des Debian-Maintainer-Skripts und Paket-Build-Helfers

Bei erfolgreichen Pull-Request-Builds wird zusätzlich eine gebaute `.deb` als GitHub-Actions-Artefakt bereitgestellt.

## Reale Validierung

Der Paket-Lifecycle wurde zusätzlich auf einem realen APT-basierten Desktop-System validiert. Dabei wurden folgende Schritte erfolgreich durchgeführt:

1. Erkennung und Blockierung der vorhandenen manuellen `1.0.0`-Installation unter `/usr/local`.
2. Saubere Entfernung der manuellen Installation bei Erhalt der Benutzerkonfiguration.
3. Installation des `.deb` über APT.
4. Erkennung als `debian-package` und `healthy` im LAC Self Check.
5. Reinstallation des Pakets.
6. Entfernung über `apt remove` bei Erhalt der Konfiguration.
7. Erneute Paketinstallation und abschließender gesunder Self Check.

Dabei wurde zusätzlich bestätigt, dass eine laufende Bash-Sitzung nach dem Entfernen der alten `/usr/local/bin/lac` gegebenenfalls `hash -r` benötigt, bevor die neue `/usr/bin/lac`-Installation über die normale Befehlsauflösung verwendet wird.

## Paketdateien im Repository

```text
debian/control                         Paketmetadaten und Abhängigkeiten
debian/changelog                       Debian-Paket-Changelog
debian/copyright                       Copyright- und Lizenzinformationen
debian/rules                           Build-Regeln
debian/preinst                         Prüfung auf manuelle /usr/local-Installation
debian/lac.1                           Manpage für lac(1)
debian/linux-admin-center.manpages     Manpage-Installation
debian/linux-admin-center.lintian-overrides
                                       dokumentierte Lintian-Ausnahmen
debian/source/format                   Debian-Quellpaketformat
```

## Sicherheitsprinzipien

Die Paketierung folgt denselben Grundsätzen wie LAC selbst:

- keine automatische Löschung einer vorhandenen manuellen Installation
- keine verdeckten Änderungen an `/usr/local`
- Paketdateien werden ausschließlich über APT/dpkg verwaltet
- bestehende aktive LAC-Konfiguration bleibt erhalten
- der Paket-Self-Check bleibt vollständig lesend
- Paket-Build und Paket-Lifecycle werden automatisiert getestet
