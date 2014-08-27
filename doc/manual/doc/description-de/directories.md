title: Handbuch Publisher
---
Automatisch erstellte Verzeichnisse
===================================

Der speedata Publisher kann beliebige Verzeichnistypen erstellen. Ob
Inhaltsverzeichnis, Artikelliste oder Stichwortindex – alle Listen
funktionieren nach demselben Prinzip: die notwendigen Daten (z.B.
Seitenzahlen, Artikelnummern) werden in einer eigenen Datenstruktur
gespeichert, auf Festplatte geschrieben und beim nächsten Lauf des
Publishers werden diese Daten eingelesen und stehen sofort zur
Verfügung.

Damit der Publisher mehrfach durchläuft, muss der Parameter `runs` auf
der Kommandozeile bzw. in der Konfigurationsdatei gesetzt werden,
beispielsweise mit `sp --runs=2` (Kommandozeile) bzw. `runs = 2`
(Optionen).

Schritt 1: Sammeln der Informationen
------------------------------------

Die beiden Befehle [Element](../commands-de/element.html) und
[Attribut](../commands-de/attribute.html) dienen zur Strukturierung von
Daten, die während der Verarbeitung gelesen werden. Mit diesen Befehlen
lassen sich neue XML Datensatzdateien erzeugen. Die Datensatzdatei
sollte eine Struktur haben, die sich für die automatische Verarbeitung
mit dem Publisher eignet. Folgende Struktur könnte für eine Artikelliste
sinnvoll sein:

    <Artikelverzeichnis>
      <Artikel nummer="1" seite="10"/>
      <Artikel nummer="2" seite="12"/>
      <Artikel nummer="3" seite="14"/>
    </Artikelverzeichnis>

Um diese Struktur im Layoutregelwerk zu erstellen, muss sie aus den
Befehlen [Element](../commands-de/element.html) und
[Attribut](../commands-de/attribute.html) wie folgt zusammengesetzt
werden:

    <Element name="Artikelverzeichnis">
      <Element name="Artikel">
        <Attribut name="nummer" auswahl="1"/>
        <Attribut name="seite" auswahl="10"/>
      </Element>
      <Element name="Artikel">
        <Attribut name="nummer" auswahl="2"/>
        <Attribut name="seite" auswahl="12"/>
      </Element>
      <Element name="Artikel">
        <Attribut name="nummer" auswahl="3"/>
        <Attribut name="seite" auswahl="14"/>
      </Element>
    </Element>

Anstelle der Befehle [Element](../commands-de/element.html) und
[Attribut](../commands-de/attribute.html) können auch Variablen als
Speicher benutzt werden (siehe Beispiel unten).

Schritt 2: Speichern und Laden der Informationen
------------------------------------------------

Mit dem Befehl
[SpeichereDatensatzdatei](../commands-de/savedataset.html) wird die
Struktur auf Festplatte gespeichert und mit
[LadeDatensatzdatei](../commands-de/loaddataset.html) wird sie wieder
geladen. Existiert die Datei nicht, so wird kein Fehler gemeldet, da es
sich um den ersten Durchlauf handeln könnte, wo die Datei naturgemäß
noch nicht existiert.

Schritt 3: Verarbeiten der Informationen
----------------------------------------

Direkt nach dem Laden wird die XML-Verarbeitung mit dem ersten Element
der gerade geladenen Struktur fortgesetzt, im Beispiel oben würde nach
dem folgenden Befehl im Layoutregelwerk gesucht:

    <Datensatz element="Artikelverzeichnis">
      ...
    </Datensatz>

Das heißt, dass die eigentliche Datenverarbeitung zeitweilig
unterbrochen und mit dem neuen Datensatz aus
[LadeDatensatzdatei](../commands-de/loaddataset.html) fortgeführt wird.

Beispiel
--------

Das folgende Beispiel reichert die »Planetenliste« um ein
Inhaltsverzeichnis an. Die Verarbeitung beginnt beim Wurzelelement
`planeten` (in der Mitte der Datei). Hier wird die Datensatzdatei `toc`
(für: table of contents) geladen. Im ersten Durchlauf wird die Datei
nicht gefunden, daher wird die Datensatzdatei »planeten« normal weiter
verarbeitet. Während des Durchlaufs wird eine Liste erstellt, die
folgende XML-Struktur hat:

    <Inhaltsverzeichnis>
      <Planetenverzeichnis name="Merkur" seite="2" />
      <Planetenverzeichnis name="Venus" seite="3" />
      <Planetenverzeichnis name="Erde" seite="4" />
      <Planetenverzeichnis name="Mars" seite="5" />
      <Planetenverzeichnis name="Jupiter" seite="6" />
      <Planetenverzeichnis name="Saturn" seite="7" />
      <Planetenverzeichnis name="Uranus" seite="8" />
      <Planetenverzeichnis name="Neptun" seite="9" />
    </Inhaltsverzeichnis>

Im Layoutregelwerk muss diese den folgenden Aufbau haben:

    <Element name="Inhaltsverzeichnis">
      <Element name="Planetenverzeichnis">
        <Attribut name="name" auswahl="'Merkur'"/>
        <Attribut name="seite" auswahl="2"/>
      </Element>
      <Element name="Planetenverzeichnis">
        <Attribut name="name" auswahl="'Venus'"/>
        <Attribut name="seite" auswahl="3"/>
      </Element>
      ...
      <Element name="Planetenverzeichnis">
        <Attribut name="name" auswahl="'Uranus'"/>
        <Attribut name="seite" auswahl="9"/>
      </Element>
    </Element>

Natürlich soll die Information in den Attributen dynamisch erzeugt
werden, dafür werden der XPath-Ausdruck `@name` und die XPath-Funktion
`sd:aktuelle-seite()` benutzt.

Im zweiten Durchlauf wird die Datei erfolgreich eingelesen und die
Verarbeitung »springt« zum Datensatz `Inhaltsverzeichnis`, da es das
Wurzelelement der neuen Datei ist. Hier wird im Layoutregelwerk das
Inhaltsverzeichnis erstellt.

    <Datensatz element="Inhaltsverzeichnis">
      <Zuweisung variable="Inhaltsverzeichnis" auswahl="''"/>
      <BearbeiteKnoten auswahl="Planetenverzeichnis"/>
      <ObjektAusgeben spalte="3">
        <Textblock breite="20" schriftart="Überschrift">
          <Absatz><Wert>Inhalt</Wert></Absatz>
        </Textblock>
      </ObjektAusgeben>
      <ObjektAusgeben spalte="3">
        <Textblock breite="20">
          <Wert auswahl="$Inhaltsverzeichnis"/>
        </Textblock>
      </ObjektAusgeben>
    </Datensatz>
     
    <Datensatz element="Planetenverzeichnis">
      <Zuweisung variable="Inhaltsverzeichnis">
        <Wert auswahl="$Inhaltsverzeichnis"/>
        <Absatz>
          <Wert auswahl="@name"/>
          <Wert>, Seite </Wert>
          <Wert auswahl="@seite"/>
        </Absatz>
      </Zuweisung>
    </Datensatz>
     
    <!-- Wurzelelement -->
    <Datensatz element="planeten">
      <Zuweisung variable="spalte" auswahl="2" />
      <LadeDatensatzdatei name="toc"/>
      <Zuweisung variable="Inhalt" auswahl="''"/>
      <NeueSeite/>
      <BearbeiteKnoten auswahl="planet"/>
    </Datensatz>
     
    <Datensatz element="planet">
      <Zuweisung variable="Inhalt">
        <Wert auswahl="$Inhalt"/>
        <Element name="Planetenverzeichnis">
          <Attribut name="name" auswahl=" @name "/>
          <Attribut name="seite" auswahl=" sd:aktuelle-seite()"/>
        </Element>
      </Zuweisung>
     
      <BearbeiteKnoten auswahl="url" />
      ...
      <NeueSeite />
      <SpeichereDatensatzdatei dateiname="toc" elementname="Inhaltsverzeichnis" auswahl="$Inhalt"/>
    </Datensatz>
     
    <Datensatz element="url">
      ...
    </Datensatz>
