title: Handbuch Publisher
---
Einbinden von Schriftdateien
============================

Formate
-------

Der speedata Publisher kann Schriftdateien in den Formaten

-   PostScript Type1 (`.afm`, `.pfb`)
-   OpenType (`.otf`)
-   TrueType (`.ttf`)

verabeiten.

Vorgehensweise
--------------

Dazu muss im Layoutregelwerk erstens der Name der Schriftdatei mit einem
internen Namen verbunden werden. Zweitens muss eine Schriftfamilie
definiert werden, die mehrere Schriftdateien zu einer Familie gruppiert
(Normal, Fett, Kursiv, Fettkursiv). Der erste Schritt wird mit dem
Element [LadeSchriftdatei](../commands-de/loadfontfile.html) gemacht:

    <LadeSchriftdatei name="Helvetica" dateiname="texgyreheros-regular.otf" />
    <LadeSchriftdatei name="Helvetica Fett" dateiname="texgyreheros-bold.otf" />
    <LadeSchriftdatei name="Helvetica Kursiv" dateiname="texgyreheros-italic.otf" />
    <LadeSchriftdatei name="Helvetica Fett Kursiv" dateiname="texgyreheros-bolditalic.otf" />

Mit diesen Anweisungen sind die Schriftdateien unter den Namen
`Helvetica`, `Helvetica Fett` u.s.w ansprechbar. Das wird dann im
zweiten Schritt mit
[DefiniereSchriftfamilie](../commands-de/definefontfamily.html) gemacht:

    <DefiniereSchriftfamilie name="Überschrift" schriftgröße="12" zeilenabstand="14">
      <Normal schriftart="Helvetica"/>
      <Fett schriftart="Helvetica Fett"/>
      <Kursiv schriftart="Helvetica Kursiv"/>
      <FettKursiv schriftart="Helvetica Fett Kursiv"/>
    </DefiniereSchriftfamilie>

Hier wird die Schriftfamilie `Überschrift` aus den vier oben definierten
Schriftdateien zusammengesetzt.

Tipp
----

Die `LadeSchriftdatei`- Anweisungen lassen sich mithilfe der
Befehlszeile leicht erzeugen. Dazu muss der Publisher mit folgenden
Anweisungen aufgerufen werden:

    sp --xml [--extra-dir=...] list-fonts

Die Ausgabe enthält alle Schriftdateien, die im angegebenen Verzeichnis
zu finden sind. Der Wert im Attribut `name` wird mit dem PostScript
Namen der Schriftart vorbelegt, sie kann im Layoutregelwerk später
geändert werden.
