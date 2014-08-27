title: Benutzung des Publishers
---
Benutzung des Publishers
========================

Der Publisher ist ein Programm ohne graphische Benutzerschnittstelle.
Das bedeutet, dass es über die Kommandozeile gestartet wird oder im
Hintergrund eines Serverprozesses läuft.

Um den Publisher auf der Kommadozeile zu starten, muss ein
Terminalfenster geöffnet werden. Auf Mac OS X befindet sich das Programm
»Terminal« im Verzeichnis Programme/Dienstprogramme, unter Windows ist
die Kommandozeile über die Suchfunktion hinter dem Start-Knopf zu
erreichen (cmd.exe) und unter Linux gibt es meist einen Knopf oder
Menüeintrag »Terminalfenster öffen«.

{{ img . "terminal.png" }}

Das Kommando, mit dem der Publisher gestartet wird, lautet `sp`. Die
Beschreibung des Kommandos lesen Sie im [Abschnitt über die
Kommandozeile](commandline.html).

Der Publisher erwartet die Daten in der Datei `data.xml` und die
Layoutbeschreibung in der Datei `layout.xml` im aktuellen Verzeichnis
und in dessen Unterverzeichnissen. Der Suchpfad kann über die
[Kommandozeile](commandline.html) oder über die
[Konfigurationsdatei](configuration.html) geändert werden.

