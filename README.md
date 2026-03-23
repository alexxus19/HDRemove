# HDRemove
A tool to convert images to smaller formats and remove the annoying HDR tag from modern phones.

everything from here on is vibe coded:

Kleine macOS-App zum Neu-Schreiben von Bildern als SDR-Dateien. Die App akzeptiert mehrere Dateien per Drag and Drop, skaliert optional die Kantenlaenge und exportiert in ein waehlbares Zielformat.

Zusatzfunktionen:
- Klick auf die Drag-and-Drop-Flaeche oeffnet einen Dateiauswahldialog.
- Bilder aus der Fotos-App werden auch dann uebernommen, wenn sie nicht als normale Datei-URL kommen.
- Jedes Listenelement hat ein X zum Entfernen.
- Erfolgreich exportierte Bilder werden automatisch aus der Liste entfernt.
- Das Interface verwendet ein retro-inspiriertes, muted Farbschema mit typewriter-artiger Schrift (monospaced).
- Die App erhaelt beim Bundle-Build ein eigenes Icon (Bild, das durch einen Aktenvernichter geht).

Exporthinweise:
- Standardformat beim Start ist JPEG.
- WebP ist als Exportformat verfuegbar.
- Der Qualitaetsregler greift fuer JPEG, HEIC und WebP.
- Bei Exportformat "Original" ist der Qualitaetsregler aktiv, sobald mindestens eine Datei mit qualitaetsfaehigem Zielformat (z. B. JPEG/HEIC/WebP) in der Liste liegt.

## Was die App mit HDR-Bildern macht

Die Verarbeitung dekodiert das Originalbild, rendert es in einen 8-Bit-sRGB-Framebuffer und schreibt es anschliessend neu. Dadurch bleiben keine HDR-Gain-Maps oder Extended-Range-Metadaten im Export erhalten, sodass macOS das Ergebnis als SDR behandelt und den Bildschirm dafuer nicht in den HDR-Modus schaltet.

## Build in VS Code

1. Empfohlene Erweiterungen installieren.
2. In VS Code den Task `swift: build` ausfuehren.
3. Zum Starten `swift: run` verwenden oder die Launch-Konfiguration `Debug HDRemove` nutzen.

## Vollstaendige .app bauen

1. In VS Code den Task `swift: build app bundle` starten.
2. Die fertige App liegt unter `dist/HDRemove.app`.
3. Starten per Doppelklick im Finder oder im Terminal mit `open dist/HDRemove.app`.

## Wichtiger macOS-Hinweis

Wenn `xcodebuild` meldet, dass nur die Command Line Tools aktiv sind, fehlt entweder die volle Xcode-Installation oder `xcode-select` zeigt noch nicht auf die Xcode-App. Fuer SwiftUI auf macOS ist in der Praxis meist eine volle Xcode-Installation noetig.
