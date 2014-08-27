title: Konfigurationsdatei
---
Konfiguration des Publishers
============================

Der Publisher ist auf verschiedene Weisen zu konfigurieren:

1.  Die Datei `publisher.cfg` in `/etc/speedata/`, im Homeverzeichnis
    (mit Punkt davor) bzw. im aktuellen Verzeichnis
2.  Die Parameter auf der Kommandozeile
3.  Die Angaben in der Layoutdatei

Die Datei `publisher.cfg` in `/etc/speedata/`, im Homeverzeichnis und im aktuellen Verzeichnis.
-----------------------------------------------------------------------------------------------

Die Datei `publisher.cfg` (`/etc/speedata/publisher.cfg`,
`/home/speedata/.publisher.cfg`) sowie im aktuellen Verzeichnis ist eine
Textdatei, die beim Starten des Publishers eingelesen wird. Im
Auslieferungszustand sieht sie wie folgt aus:

    data      = data.xml
    layout    = layout.xml
    autoopen  = false
    extra-dir = "/home/speedata/Desktop/speedata"

Das Format muss eingehalten werden, sonst wird die Datei nicht richtig
erkannt. Folgende Optionen werden unterstützt:

Wert | Beschreibung
-----|-------------
`autoopen` | wenn hier `true` anstelle von `false` steht, wird das PDF nach dem Publisher Durchlauf automatisch geöffnet. Derselbe Effekt lässt sich über die Kommandozeile mit `--autoopen` erreichen.
`data` | Name der XML-Daten. Wenn nicht vorhanden, wird die Datei `daten.xml` geladen.
`dummy` | Wenn `true`, dann wird die Datendatei nicht eingelesen. Anstatt dessen wird wird der folgende Inhalt angenommen: `<data />`. Das dient zum einfachen Testen von Layoutregelwerken.
`extra-dir` | Ein Verzeichnis im Dateisystem, das Dateien für den Publisherlauf enthält. Dazu gehören die Schriftdateien, die XML-Dateien (Daten und Layoutregelwerk) sowie die einzubindenden Bilddateien. Sollen mehrere Verzeichnisse hinzugefügt werden, müssen diese mit `:` oder `;` getrennt werden, je nach Betriebssystem (Windows: `;`, alle anderen: `:`). Das aktuelle Verzeichnis wird automatisch eingebunden.
`filter` | Führt die angegebene Datei als XPROC-Filter aus.
`fontpath` | Setzt den systemweiten Pfad für Fonts. Unter Windows ist dies `%WINDIR%\Fonts`, unter Mac OS X `/Library/Fonts:/System/Library/Fonts`.
`grid` | Bestimmt, ob das Raster angezeigt wird.
`imagecache` | Ordner für zwichengespeicherte Bilder (nur `href="http://..."`). Voreinstellung: `$TMPDIR/sp/images`.
`jobname` | Name der Ausgabedatei
`layout` | Name des Layoutregelwerks. `layout.xml` ist der voreingestellte Name.
`opencommand` | Kommando für das automatische Öffnen der Dokumentation bzw. PDF-Datei. Für MacOS X sollte das `open` sein, für Linux `xdg-open` oder `exo-open` (xfce).
`pathrewrite` | Kommaseparierte Liste der Form Pfadteil=Pfadteil. Beispiel: `/media/=%(projectdir)s/myfiles/`. Das würde absolute Pfadangaben wie `file:///media/XYZ` in `file:///Pfad/zum/Projekt/myfiles/XYZ` ändern.
`runs` | Setzt die Anzahl der Durchläufe fest.
`timeout` | Maximale Dauer des Publishing-Laufs. Wenn dieser überschritten wird, bricht der Lauf mit Fehler 1 ab.
`startpage` | Nummer der ersten Seite

In der Konfigurationsdatei kann mit `%(projectdir)s` auf das Verzeichnis
zugegriffen werden, in dem die Datei `publisher.cfg` liegt.

Alle Angaben in dieser Konfigurationsdatei sind optional. Alle folgenden
Konfigurationsdateien werden in dieser Reihenfolge eingelesen:
`/etc/speedata/publisher.cfg`, `~/.publisher.cfg` und im aktuellen
Verzeichnis `publisher.cfg`. Das aktuelle Verzeichnis kann beim Aufruf
des Publishers mittels `--wd=...` geändert werden.

Parameter auf der Kommandozeile
-------------------------------

Die erlaubten Parameter auf der Kommandozeile werden in einem [eigenen
Abschnitt](commandline.html) aufgeführt.

Angaben in der Layoutdatei
--------------------------

Das Layoutregelwerk erlaubt manche Parameter zu setzen. Dazu gehören die
Angaben, die im Element [Optionen](../commands-de/options.html) gesetzt
werden.

