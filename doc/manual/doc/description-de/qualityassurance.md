title: Handbuch Publisher
---
Qualitätssicherung und PDF Vergleich
====================================

Um zu gewährleisten, dass neue Versionen des Publishers auch exakt
dieselben Ergebnisse liefern wie vorhergehende, hat der Publisher eine
Funktionalität eingebaut, mit der man unerwünschte Verhaltensänderungen
erkennen kann.

Die Idee ist folgende: ausgehend von einer Layout-Datei und einem
überprüften Ergebnis (Referenz PDF) kann der Publisher kontrollieren, ob
mit der aktuellen Version noch immer dasselbe Ergebnis erzielt wird.
Dazu erstellt man eine Layoutdatei und Datendatei im XML Format, lässt
eine PDF Datei daraus erzeugen und speichert diese unter dem Namen
`reference.pdf` ab. Bei dem Aufruf von `sp compare <Verzeichnis>` wird
nun der Publisher erneut aufgerufen und prüft visuell, Seite für Seite,
ob die resultierende Datei mit der vorher angelegten PDF Datei
`reference.pdf` übereinstimmt.

Voraussetzungen für den Vergleich
---------------------------------

Der Publisher sucht rekursiv ausgehend von dem angegebenen Verzeichnis
nach Verzeichnissen, die eine Datei `layout.xml` oder eine Datei
`publisher.cfg` enthalten. In diesem Verzeichnis wird dann ein
Publisher-Durchlauf gestartet. Die Layoutdatei muss unter dem Namen
`layout.xml`, die Daten-Datei unter dem Namen `data.xml` zu finden sein,
falls das nicht in der (optionalen) Datei `publisher.cfg` anders
konfiguriert ist.

Der PDF-Vergleich benötigt eine Installation der kostenfreien
Programmbibliothek ImageMagick, die skriptbasiert Bilder manipulieren
und vergleichen kann. ImageMagick gibt es unter anderem für die
Betriebssysteme Windows, Mac und Linux.

Vorgehensweise
--------------

Ausgehend von einer Layout und einer Datendatei erzeugt man in gewohnter
Weise eine PDF Datei. Am einfachsten ist es, wenn sie direkt unter dem
Namen `reference.pdf` erscheint.

    sp --jobname reference

erzeugt die passende PDF-Datei. Mit

    sp --jobname reference clean

löscht man die übrigen und nicht weiter benötigten Zwischendateien. Das
Verzeichnis sieht nun so aus:

    beispiel/
    ├── data.xml
    ├── layout.xml
    └── reference.pdf
     
    0 directories, 3 files

Wird nun `sp compare beispiel` aufgerufen, sollte es keine Beanstandung
geben und als Ausgabe erscheinen:

    $ sp compare beispiel/
    Run comparison in directory beispiel
    OK
    Total run time: 1.62956s

Falls nun eine zukünftige Version des Publishers eine visuelle Änderung
des Layouts hervorrufen würde, wäre die Ausgabe z.B. folgende:

    $ sp compare beispiel/
    Run comparison in directory beispiel
    Comparison failed. Bad pages are: [1]
    Total run time: 862.898ms

Die Unterschiede sind als PNG Dateien in dem Verzeichnis enthalten:

    beispiel/
    ├── data.xml
    ├── layout.xml
    ├── pagediff.png
    ├── publisher.pdf
    ├── reference.pdf
    ├── reference.png
    └── source.png

Die Dateien `source.png` und `reference.png` (bzw. bei mehreren Seiten
mit einer Kennung für die Seitenzahl) enthalten die aktuelle Version und
die Referenz als Grafik. Die Datei `pagediff.png` (auch hier mit
Kennungen für die Seitenzahlen) stellt die Unterschiede zwischen den
ersten beiden Dateien hervorgehoben dar. Die Gemeinsamkeiten werden
abgeschwächt dargestellt.

Qualitätssicherung
------------------

Mit den Möglichkeiten des PDF-Vergleichs kann man nun eine Sammlung von
Beispieldokumenten erstellen, die produktionstypisch sind. Eine
Vorgehensweise besteht darin, eine Verzeichnisstruktur zu erstellen, die
wie folgt aufgebaut ist:

    qa/
    ├── beispiel1
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    ├── beispiel2
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    ├── beispiel3
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    ├── beispiel4
    │   ├── data.xml
    │   ├── layout.xml
    │   └── reference.pdf
    └── beispiel5
        ├── data.xml
        ├── layout.xml
        └── reference.pdf

Mit dem Aufruf `sp compare qa` werden alle Unterverzeichnisse
durchlaufen und überprüft. Im besten Fall ist die Ausgabe:

    $ sp compare qa/
    Run comparison in directory beispiel1
    OK
    Run comparison in directory beispiel2
    OK
    Run comparison in directory beispiel3
    OK
    Run comparison in directory beispiel4
    OK
    Run comparison in directory beispiel5
    OK
    Total run time: 4.541458s

