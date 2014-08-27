title: Kommandozeile
---
Aufruf des Publishers über Kommandozeile
========================================

    $ sp --help
    Usage: [parameter] command
    -h, --help                   Show this help
        --autoopen               Open the PDF file (MacOS X and Linux only)
        --data=NAME              Name of the XML data file. Defaults to 'data.xml'. Use '-' for STDIN
        --dummy                  Don't read a data file, use '<data />' as input
    -c, --config=NAME            Read the config file with the given NAME. Default: 'publisher.cfg'
        --[no-]cutmarks          Display cutmarks in the document
    -x, --extra-dir=DIR          Additional directory for file search
        --filter=FILTER          Run XPROC filter before publishing starts
        --grid                   Display background grid. Disable with --no-grid
        --[no-]local             Add local directory to the search path. Default is true.
        --layout=NAME            Name of the layout file. Defaults to 'layout.xml'
        --jobname=NAME           The name of the resulting PDF file (without
                                 extension), default is 'publisher'
        --mainlanguage=NAME      The document's main language in locale format,
                                 for example 'en' or 'en_US'.
        --outputdir=DIR          Copy PDF and protocol to this directory
        --profile                Run publisher with profiling on (internal use)
        --quiet                  Run publisher in silent mode
        --runs=NUM               Number of publishing runs
        --startpage=NUM          The first page number
        --show-gridallocation    Show the allocated grid cells
        --systemfonts            Use system fonts
        --trace                  Show debug messages and some tracing PDF output
        --timeout=SEC            Exit after SEC seconds
    -v, --var=VAR=VALUE          Set a variable for the publishing run
        --verbose                Print a bit of debugging output
        --version                Show version information
        --wd=DIR                 Change working directory
        --xml                    Output as (pseudo-)XML (for list-fonts)

    Commands
          clean                  Remove publisher generated files
          compare                Compare files for quality assurance
          doc                    Open documentation
          list-fonts             List installed fonts (use together with --xml for copy/paste)
          run                    Start publishing (default)
          server                 Run as http-api server on port 5266 (configure with --port)
          watch                  Start watchdog / hotfolder



Erklärung der Kommandozeilenparameter
-------------------------------------

Parameter | Beschreibung
----------|-------------
`--autoopen`| Öffnet die PDF-Datei nach dem Publisher-Durchlauf. Kann auch in der [Konfigurationsdatei](configuration.html) eingestellt werden.  `--data=NAME`| Gibt den Namen der XML-Daten an. Voreinstellung ist `data.xml`.   Ebenfalls [konfigurierbar](configuration.html). Wird als Dateiname ein Strich (`-`) angegeben, liest der Publisher die XML-Daten aus der Standard-Eingabe (STDIN).
`--cutmarks` | Zeigt die Schnittmarken an. Einstellbar im [Layout](../commands-de/options.html).
`--dummy`| Führt nur das Regelwerk aus. Als Dateninhalt wird `<data />` angenommen. Dient zum schnellen Testen von Regelwerken
`-x`, `--extra-dir`| Bindet zusätzliche Verzeichnisse in den Publisherlauf ein. In diesen  Verzeichnissen werden alle Daten gesucht: Bilddaten, Regelwerke,  Datendateien und Schriftdateien. Dieses Argument kann mehrfach  angegeben werden und per [Konfigurationsdatei](configuration.html)  mit Werten vorbelegt werden.
`--filter=FILTER`| Führt die angegebene XPROC-Datei aus.
`--grid`| Zeichnet das Raster. Mit `--no-grid` wird es ausgeschaltet. Konfigurierbar auch im [Layout](../commands-de/options.html).
`--layout=NAME`| Gibt den Namen des Layoutregelwerks an. Voreinstellung ist `layout.xml`. Ebenfalls [konfigurierbar](configuration.html).
`--[no-]local`| Das aktuelle Verzeichnis wird (nicht) rekursiv dem Suchpfad hinzugefügt. Voreingestellt ist, dass das aktuelle Verzeichnis und  seine Unterverzeichnisse beachtet werden.
`--jobname=NAME`| Bestimmt den Ausgabenamen. Voreinstellung ist `publisher.pdf`.
`--mainlanguage=NAME`| Bestimmt die Hauptsprache des Dokuments für die Silbentrennung. Mögliche Werte sind: `af`, `as`, `bg`, `ca`, `cs`, `cy`, `da`, `de`,`el`, `en`, `en_GB`, `en_US`, `eo`, `es`, `et`, `eu`, `fi`, `fr`,`ga`, `gl`, `gu`, `hi`, `hr`, `hu`, `hy`, `ia`, `id`, `is`, `it`,`ku`, `kn`, `la`, `lo`, `lt`, `ml`, `lv`, `ml`, `mn`, `mr`, `nb`,`nl`, `nn`, `or`, `pa`, `pl`, `pt`, `ro`, `ru`, `sa`, `sk`, `sl`,`sr`, `sv`, `ta`, `te`, `tk`, `tr`, `uk` und `zh`. Siehe [Codeliste der Sprachen](http://www.loc.gov/standards/iso639-2/php/code_list.php).
`--outputdir=VERZEICHNIS`| Die resultierende PDF-Datei und Protokolldatei wird in das angegebene Verzeichnis kopiert. Das Verzeichnis wird erstellt, falls es noch nicht existiert.
`--profile`   | Erzeugt Profiling-Informationen für den internen Gebrauch.
`--quiet`     | Unterdrückt alle Ausgaben des Publishers.
`--runs = NUM`| Überschreibt die Anzahl der Durchläufe des Publishers.
`--startpage = NUM`| Die Seitennummer der ersten Seite.
`--show-gridallocation`| Markiert die belegten Rasterzellen mit einer gelblichen Farbe. Doppelt belegte Zellen werden mit rot gekennzeichnet.
`--systemfonts`| Lädt zusätzlich Systemschriftarten. Funktioniert nicht unter Windows XP.
`--timeout=SEC`| Beendet den Lauf nach SEC Sekunden mit Statuscode 1.
`-v`, `--var=value`| Übergibt zusätzliche Variablen an den Publisher-Lauf. Diese können wie üblich mit `auswahl="$variable"` benutzt werden.
`--verbose`| Gibt mehr Informationen aus, also notwendig.
`--wd=DIR`| Wechselt in das angegebene Verzeichnis. Verhält sich genau so, als ob man vorher mit cd in dieses Verzeichnis gewechselt hat.
`--xml`| Die Ausgaben mancher Kommandos werden als (Pseudo-)XML dargestellt, um sie in das Layoutregelwerk zu übernehmen.

Befehle
-------

Parameter | Beschreibung
----------|-------------
`list-fonts`|  Listet alle Schriftdateien auf, die in den Publisher-Verzeichnissen gefunden werden. Zusammen mit `--xml` erlaubt dieses Kommando die Ausgabe per Copy&Paste in das Layoutregelwerk zu übernehmen.
`compare`|  Überprüft rekursiv ein Verzeichnis auf Layout-Anderungen. Siehe den [Abschnitt über Qualitätssicherung](qualityassurance.html).
`clean`|  Entfernt temporäre Dateien aus dem Publisher-Lauf. Behält die PDF Datei.
`doc`|  Öffnet die Onlinehilfe.
`run`|  Startet den Publisher Lauf.
`server` | Startet im [Server-Modus](servermode.html).
`watch`|  Startet den internen Hotfolder

### Beispiel für die Hotfolder Konfiguration
    [hotfolder]
    hotfolder = /home/speedata/hotfolder
    events = layout\.xml:run(runpublisher);data\.xml:run(runpublisher)

 Parameter | Beschreibung
 ----------|-------------
`hotfolder`|  Verzeichnis, das überwacht werden soll.
`events`|  Einträge (mit Semikolon getrennt) in der Form `Muster:Befehl`. Das `Muster` ist ein Regulärer Ausdruck. Wenn dieser auf die Datei *passt*, dann wird das Programm unter `Befehl` ausgeführt. Derzeit können nur externe Programme ausgeführt werden. Diese werden in den Klammern angegeben. Die Programme erhalten als erstes Argument den Pfad zur gefundenen Datei. Der Hotfolder wartet, bis das Programm beendet wurde und löscht anschließend die Datei.

