layout: main
title: Changelog
---
Liste der Änderungen
====================

{{/*
       changelog ist ab sofort in changelog.xml

*/}}{{ template "changelog" . }}

Version 2.0 (2014-07-01)
-----------

-   Neuer [Kommandozeilenschalter](commandline.html) `cutmarks` um Schnittmarken anzuzeigen. (1.99.46)
-   Neue [XPath-Funktion](xpath.html) sd:seitenzahlen-zusammenfassen() (1.99.44)
-   **Die Voreinstellung für die horizontale Ausrichtung einer
    Tabellenzelle ist nun `left`.**
-   Neue Option `justify` für horizontale Ausrichtung in
    [Tabelle](../commands-de/table.html) (1.99.43)
-   Neue Option für [Tabelle](../commands-de/table.html):
    `border-collapse` um Rahmen benachbarter Zellen überlappen zu
    lassen. (1.99.42)
-   Neue Optionen für [NeueSeite](../commands-en/newpage.html) um Seiten
    zu überspringen. (1.99.41)
-   Weitere Sprachen eingebaut, [Kommandozeile sp](commandline.html) um
    `--mainlanguage` erweitert. (1.99.40)
-   [Tlinie](../commands-de/tablerule.html) hat ein neues Attribut:
    `start`. Damit lässt sich die Startspalte bestimmen.
-   Neue Methode um Rasterbreite und -höhe zu definieren. Mit `nx` und
    `ny` kann man die Anzahl der Rasterzellen auf der Seite in x und
    y-Richtung festlegen.
-   Neuer Befehl [Until](../commands-de/until.html).
-   Neue Attribute `schusterjunge` und `hurenkind` bei
    [DefiniereTextformat](../commands-de/definetextformat.html). Die
    Voreinstellung für Text ist nun, dass Schusterjungen und Hurenkinder
    vermieden werden.
-   Neues Attribut `attribute` in
    [SpeichereDatensatzdatei](../commands-de/savedataset.html) um
    Attribute für das Root-Element zu erlauben.
-   Neue [XPath-Funktion](xpath.html) `sd:bildhöhe(<Dateiname>)`.
-   Das Schema wird nun aus der Dokumentation automatisch erzeugt.
-   [Bild](../commands-de/image.html) kann auch eie URL (`http://...`)
    als Argument für `url` erhalten.
-   Neues Feature `seitentyp` in
    [NeueSeite](../commands-de/newpage.html).
-   Neue [Option](../commands-de/options.html) `markerzurücksetzen`.
-   Auf Systemschriftarten kann mit `--systemfonts` zugegriffen werden.
    Funktioniert nicht unter Windows XP, und derzeit nicht unter Linux.
-   Funktionalität des Befehls [Mark](../commands-de/mark.html)
    geändert, um Daten (Seitenzahlen) anzuhängen. Außerdem wird eine
    Zwischendatei für folgende Läufe generiert.
-   Neue [XPath-Funktion](xpath.html) `sd:aktuelle-rahmennummer()` um im
    Positionierungsbereich die aktuelle Rahmennummer zu ermitteln.
-   Neuer Befehl [Indexerstellen](../commands-de/makeindex.html).
-   Neuer [Kommandozeilenparameter](commandline.html) `timeout` für
    Abbruch nach n Sekunden.
-   Neue [Konfiguration](configuration.html) `pathrewrite` um absolute
    Pfade (`file:///....`) für jeden Publishing-Lauf zu verändern.
-   Neuer [Kommandozeilenparameter](commandline.html)
    `show-gridallocation` um belegte Zellen zu zeigen.
-   `vreferenz` bei [ObjektAusgeben](../commands-de/placeobject.html).

Version 1.8
-----------

-   Kritischer Fehler behoben: Zeichen wie à die einen Leerraum-Wert in
    der UTF-8 Sequenz enthalten (z.B. A0), werden nicht verschluckt.
-   Neuer [Kommandozeilenparameter](commandline.html) `--profile`
    (1.7.2).
-   Neue Option in der Konfigurationsdatei: `fontpath` um
    Fallback-Verzeichnisse für Fonts anzugeben (1.7.1).

Version 1.6 (2013-05-24)
------------------------

-   Breite in [Textblock](../commands-de/textblock.html) und
    [Tabelle](../commands-de/table.html) optional (1.5.56)
-   [Gruppenspezifisches](../commands-de/group.html) Raster (1.5.49)
-   Neue [XPath-Funktion](xpath.html) `sd:html-dekodieren()` um `&lt;`
    und ähnliche Entitäten in echtes HTML zu wandeln. (1.5.47)
-   Neue Befehle [Ol](../commands-de/ol.html) und
    [Ul](../commands-de/ol.html), wie in HTML. `Ol` und `Ul` (mit `Li`)
    sind in den Daten erlaubt. (1.5.46)
-   Hyperlinks dürfen auch in den Daten enthalten sein:
    `<a href="http://...">Text</a>`. (1.5.46)
-   Neuer Befehl [A](../commands-de/a.html) für Hyperlinks (wie HTML).
    (1.5.45)
-   Neues Attribut `version` beim Befehl
    [Layout](../commands-de/layout.html) um Versionskompatibilität
    sicherzustellen (1.5.44).
-   Neuer Befehl [HLeerraum](../commands-de/hspace.html) um einen
    dehnbaren Leerraum einzufügen. (1.5.43)
-   Neuer sp-Befehl `compare` für
    [PDF-Vergleich/Qualitätssicherung](qualityassurance.html) (1.5.42)
-   Neuer Befehl [Br](../commands-de/br.html) um einen Zeilenumbruch
    einzufügen. Br Tags sind nun auch in
    [Wert](../commmands-de/value.html) erlaubt. (1.5.41)
-   Neue [XPath-Funktion](xpath.html) `sd:formatiere-zahl()` zum
    „Tausender formatieren“ (1.5.41)
-   [XPath-Funktion](xpath.html) `sd:formatiere-zahl()` in
    `sd:formatiere-string()` umbenannt (1.5.41)
-   Neuer Befehl [Schleife](../commands-de/loop.html) um den Inhalt des
    Elements mehrfach zu wiederholen. (1.5.38)
-   Neue [XPath-Funktionen](xpath.html) `sd:seitennummer(<marke>)` um
    die Seitennummer einer Marke zu bestimmen (1.5.36).
-   Neuer Befehl [Marke](../commands-de/mark.html) um unsichtbare
    Markierungen zu erstellen. (1.5.36)
-   Neue [XPath-Funktionen](xpath.html) `ceiling()` und `floor()`
    (1.5.36).
-   Neue Option: `sp --wd DIR`. Damit lässt sich das aktuelle
    Verzeichnis festlegen. Siehe [Kommandozeile](commandline.html)
    (1.5.36)
-   Neuer Befehl: `sp clean` zum „Aufräumen“. Siehe
    [Kommandozeile](commandline.html) (1.5.35)
-   [XPath-Funktion](xpath.html) `sd:alternierend()` geändert und
    `sd:alternierend-zurücksetzen()` eingeführt. (1.5.35)
-   Attribut `auswerten` in [Tabelle](../commands-de/table.html) um
    XPath Ausdrücke auszuführen. (1.5.35)
-   File uri hat nun `file:///c:/foo/bar.baz` als Format (drei
    Schrägstriche am Anfang) (siehe [File URI
    scheme](http://en.wikipedia.org/wiki/File_URI_scheme#Windows_2))
    (1.5.35)
-   Neuer XML-Parser. Benötigt kein spezielles Binary (1.5.35)
-   [Bild](../commands-de/image.html) kann auch ein URI (`file://...`)
    als Argument für den Dateinamen erhalten. Ebenso die
    [XPath-Ausdrücke](xpath.html) `sd:anzahl-seiten()`,
    `sd:bildbreite()` und `sd:datei-vorhanden()`. (1.5.33)
-   Wildcard (`*`) als [XPath-Ausdruck](xpath.html) (1.5.32)
-   [BearbeiteKnoten](../commands-de/processnode.html) erlaubt
    [XPath-Ausdrücke](xpath.html) (1.5.32)
-   [QR Codes](../commands-de/barcode.html) (1.5.28)
-   Neues Element [FürAlle](../commands-de/forall.html), um für alle
    Kindelemente Befehle auszuführen. (1.5.27)
-   sp based hotfolder (`sp watch`) (1.5.26)
-   [CSS Stylesheets](../commands-de/stylesheet.html)
-   [Barcodes](../commands-de/barcode.html "EAN13 und Code128")
-   XPath-Funktion [count](xpath.html)
-   Linienstärke bei [ObjektAusgeben](../commands-de/placeobject.html)
-   CDATA Abschnitte im lpeg-XML-Parser sind erlaubt
-   Neue XPath-Funktion [sd:aktuelle-spalte](xpath.html)
-   `sp` liest Daten von STDIN wenn der Datenname `-` ist.
-   [Td](../commands-de/td.html) Attribut `align` darf (wie im Handbuch
    beschrieben) nur noch ‘left’, ‘right’ oder ‘center’ als Werte
    enthalten.
-   [Tabellenfuß](../commands-de/tablefoot.html) und
    [Tabellenkopf](../commands-de/tablehead.html) erlauben eine
    Seitenangabe
-   `sp`: `--[no-]local` um das lokale Verzeichnis nicht zu beachten
-   `sp`: `--verbose` erzeugt zusätzliche Informationen
-   Neue XPath-Funktion [sd:formatiere-zahl](xpath.html)
-   `sp`: `--outputdir=VERZEICHNIS` kopiert das resultierende PDF und
    die Protokolldatei in das angegebene Verzeichnis
-   `sp`: `--dummy` benutzt `<data />` als Eingabedatei (Daten-XML)
-   `sp` nodejs durch `sp` in Go ersetzt für Cross-Plattform Ausführung
-   Keine Default-Sprache mehr, wird nun in
    [Optionen](../commands-de/options.html) festgelegt.
-   Schemadateien im Verzeichnis /usr/share/speedata-publisher/schema
-   Anzahl der Läufe kann nur noch über Kommandozeile bzw.
    Konfigurationsdatei angegeben werden.
-   `opencommand` Konfigurierbar (Programm zum Öffnen der Dokumentation
    / PDF-Dateien)
-   Konfigurationsdatei in `/etc/speedata` und im Homeverzeichnis
    `~/.publisher.cfg` werden eingelesen.
-   Default Textformat bei [Tabellen](../commands-de/table.html).
-   `zeilen`-Angabe bei Textformaten (inkl hängender Einzug). Siehe
    [DefiniereTextformat](../commands-de/definetextformat.html)
-   `sprun` durch `sp` ersetzt. Siehe [Kommandozeile](commandline.html)
-   `hreferenz` bei [ObjektAusgeben](../commands-de/placeobject.html).
-   Neue XPath-Funktion [empty](xpath.html)
-   Zeilenangabe in [NeueZeile](../commands-de/nextrow.html).
-   Linienfarbe veränderbar. [Linie](../commands-de/rule.html).
-   Bildumrisse können angegeben werden. Siehe
    [Bild](../commands-de/image.html) und
    [ObjektAusgeben](../commands-de/placeobject.html)
-   `--laeufe=...`-Option bei `sprun`
-   `Zeilennummer` in [NeueZeile](../commands-de/nextrow.html)
-   Defaults: Seitengröße: 210mm x 297mm, Raster: 10mm x 10mm,
    Schriftdateien: TeXGyreHeros, Schriftgröße 10pt/12pt, Seitentyp
    (Rand 1cm überall)
-   XPath-Funktionen nun übersetzt (de/en). Benötigt Namensraumpräfix
    `urn:speedata:2009/publisher/functions/de`
-   `-v`, `--variable` in [sprun](commandline.html)
-   `valign` in [Td](../commands-de/td.html),
    [Tr](../commands-de/tr.html): `middle` statt `center`
-   `valign` in [ObjektAusgeben](../commands-de/placeobject.html)
-   PDF [Lesezeichen](../commands-de/bookmark.html).
-   Zusätzlich auch englischsprachige Regelwerke
-   Sprache kann je [Absatz](../commands-de/paragraph.html) ausgewählt
    werden (Silbentrennung).
-   Änderungen bei
    [SpeichereDatensatzdatei](../commands-de/savedataset.html)

Version 1.4 (2011-06-09)
------------------------

-   Absolute Angaben von Breite und Höhe bei
    [Bildern](../commands-de/image.html)
-   [Tabellen](../commands-de/table.html) dürfen
    [Tabellen](../commands-de/table.html) enthalten
-   Anschnitt bei [Bildern](../commands-de/image.html)
    (`natürliche-größe`, `maximale-größe`)
-   Seitenzahl bei [Bild](../commands-de/image.html)
-   `sd:anzahl-seiten(<Dateiname>)`
-   Spalte bei [ObjektAusgeben](../commands-de/placeobject.html)
    optional
-   [Platzierungsbereich](../commands-de/positioningarea.html)
-   (X)[Include](../commands-de/include.html)
-   `zeige_silbentrennung` bei [Optionen](../commands-de/options.html)
-   [Trennvorschlag](../commands-de/hyphenation.html)
-   Microtype (HZ-Programm)
-   Leerraum als Parameter in
    [LadeSchriftdatei](../commands-de/../commands-de/loadfontfile.html)
-   [XPath-Funktion](xpath.html) `last()`
-   [Tabellenkopf](../commands-de/tablehead.html) und
    [Tabellenfuß](../commands-de/tablefoot.html)
-   [ObjektAusgeben](../commands-de/placeobject.html):
    `belegen`=“ja”/“nein”
-   [Linie](../commands-de/rule.html) zum Zeichnen von Linien
-   Mehrspaltigkeit im [Textblock](../commands-de/textblock.html)
-   `luatex` → `sdluatex` zwecks besserer Unterscheidung zum Original
-   [Hotfolder / Watchdog](hotfolder.html)
-   Unterstreichen von Texten [U](../commands-de/u.html)
-   Inhalt von [Absatz](../commands-de/paragraph.html) darf \<i\> und
    \<b\> enthalten.
-   Mit `node()` kann auf Kindelemente zugegriffen werden.
-   [Spalte](../commands-de/column.html): Breitenangabe auch in
    Rasterzellen möglich.
-   `sd:datei-vorhanden( <Dateiname> )`, `sd:bildbreite(<Dateiname> )`,
    `sd:variable( <Name>)`, `concat(...)`
-   [Leerzeile](../commands-de/emptyline.html)
-   Absolute Positionierung bei
    [ObjektAusgeben](../commands-de/placeobject.html)
-   Automatischer Tabellenumbruch
-   Winkel in [Textblock](../commands-de/textblock.html)
-   Neues Element: [Schriftart](../commands-de/fontface.html)
-   Tabellen: die minimale Zeilenhöhe bestimmt sich nun durch den
    Zeilenabstand der größten verwendeten Schriftart.
-   [Maßangaben](lengths.html): Die Einheit Pica-Punkt muss nun als `pp`
    angegeben werden, ein DTP-Punkt als `pt`.
-   [Bild](../commands-de/image.html) in
    [Absatz](../commands-de/paragraph.html).
-   `align` und `valign` für [Td](../commands-de/td.html) kann auch in
    [Spalte](../commands-de/column.html) bzw.
    [Tr](../commands-de/tr.html) gesetzt werden.
-   Farbige Rahmen in Tabellenzellen ([Td](../commands-de/td.html)).
-   Padding in Tabellenzellen ([Td](../commands-de/td.html))
-   [Sub](../commands-de/sub.html), [Sup](../commands-de/sup.html)
    (hoch- und tiefgestellter Text)
-   Seitenspezifisches Raster bei
    [Seitentyp](../commands-de/pagetype.html).
-   [Seitentyp](../commands-de/pagetype.html) Deklarationen werden in
    umgekehrter Reihenfolge abgearbeitet.
-   [BearbeiteKnoten](../commands-de/processnode.html) und
    [Datensatz](../commands-de/record.html) erlauben die Angabe eines
    Modus.
-   [Seitentyp](../commands-de/pagetype.html) neu gestaltet: Bedingungen
    werden nun im Attribut `bedingung` anstelle von einem Kindelement
    bestimmt.
-   `*`-Breitenangaben in [Spalten](../commands-de/columns.html) für
    dynamischen Breiten.
-   [Td](../commands-de/td.html): `border-left`, `border-right`,
    `border-top` und `border-bottom` beachtet.
-   `sprun -h` gibt keine Versionsinformation aus, das macht jetzt
    `sprun --version`.

Version 1.2 (2010-09-28)
------------------------

-   Attribut `minhoehe` in [Tr](../commands-de/tr.html) in `minhöhe`
    umbenannt.
-   Xproc-Filter
-   Aktionen ([Aktion](../commands-de/action.html))
-   Element Variable gelöscht
-   [SortiereSequenz](../commands-de/sortsequence.html)
-   [BearbeiteDatensatz](../commands-de/processrecord.html)
-   [Kopie-von](../commands-de/copy-of.html) ersetzt XML-Konstrukte
-   [Fallunterscheidung](../commands-de/switch.html) kann in beliebigen
    Elementen vorkommen.
-   [XPath-Ausdrücke](xpath.html) nur noch in den Attributen `bedingung`
    und `auswahl`. Ansonsten können [XPath-Ausdrücke](xpath.html) durch
    geschweifte Klammern (`"{`…`}"`) erzwungen werden.
-   [XPath-Funktionen](xpath.html) aufgeteilt. Alle
    [XPath-Funktionen](xpath.html), die auch im XPath 2.0 Standard
    enthalten sind, haben keinen Namensraum.
-   Weitere [XPath-Ausdrücke](xpath.html) sind hinzu gekommen.

Version 1.0 (2010-03-30)
------------------------

-   GruppeAusgeben ist in
    [ObjektAusgeben](../commands-de/placeobject.html) aufgegangen.
-   (Erneut): Rahmen und Hintergrund bei
    [ObjektAusgeben](../commands-de/placeobject).
-   [Zuweisung](../commands-de/setvariable.html): Variablenname nun
    [XPath-Ausdruck](xpath.html).
-   Bild in Tabelle

[Änderungen vor Version 1.0](changelogpre1.html)

