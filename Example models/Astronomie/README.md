# Beispielmodell Astronomie für den IM-standard
## Original Modell
Das Modell zeigt eine vollständiges Informationsmodell für einige wenige Objekte zur Astronomie.
Es ist ein Beispiel, bis in welche Detailtiefe ein Informationsmodell (d.h. die reine fachliche Beschreibung) gehen kann.

Das Modell wurde im Modellierungswerkzeug dataspot erstellt. Hier werden diverse Darstellungsformen präsentiert. Sie dienen der Kommunikation mit Menschen und mit Maschinen bzw. zwischen Maschinen.

Das Astronomie-Modell in standardisierter json-darstellung erlaubt die digitale Verwendung aller Informationen die im Modell stehen.

Der IM-Standard, für den dieses Beispiel erstellt wurde, ist im json \
**astronomie-information-model.json**\
zu finden. Es ist validiert mit dem im-standard-schema.json

Ebenfalls dem Standard entspricht die Darstellung als sql-Datenbank. 
- **astronomie-sqlite.db**\
	Diese sqlite database enthält die volle Beschreibung des Informationsmodells Astronomie. 
	
Diese beiden Standard-darstellungen sind automatisch aus den Originaldaten aus dem Modellierungswerkzeug (dataspot) heraus generiert.

## Communication Artefacts
Für die Kommunikation unter Menschen, bzw. mit der Maschine bzw. unter Maschinen, können weitere Darstellungsformen des Modells gewählt werden.
Je nach Verwendungszweck, IT-Know-How-Level, Interesse soll die Darstellung gewählt werden, die am besten geeignet ist.


Wichtiges Prinzip: *Es werden Informationen anders dargestellt, gefiltert, vereinfacht. Es dürfen dabei keine fachlichen Aussagen (Namen, Bedeutung, Beziehungen) verändert werden.*

### Diagramme 
Diagramme dienen der Visualisierung. Sie sind immer Ausschnitte aus dem ganzen Modell mit dem Zweck, kommunikationsfreundliche Artefakte zu erstellen.

- Astronomie-design.pdf   \
	ein manuell erstelltes Diagramm, das eine Übersicht lieferen soll. Die Darstellungsform ist von foryouandyourcustomeers in Anlehnung an ein ERD entwickelt worden.
	
- Astronomie-design Alternative.pdf   \
	Eine alternative Darstellungsform des 1. Diagramms (Supertyp)
	
- Astronomie-design mit Bildern.pdf   \
	Das Modell ergänzt um Beispiele und Bilder zu den Entitäten. Es soll zeigen, dass für die Kommunikation in einer Umgebung mehrere Darstellungsformen gewählt werden können.

Aus dem Modellierungswerkzeug (dataspot) konnten direkt die folgenden Diagramme exportiert werden:
- Astronomie-ds-fastalles.pdf
	Eine Auswahl von Elementen
	
- Astronomie-ds-favoriten.pdf    
	Nur Elemente die als wichtig markiert waren
- Astronomie-full-ERF.png\
	erweitertes Modell mit allen Elementen.

- Astronomie IM Grafik.pdf
	Bilder erzeugt aus der Informationsmodell json-Datei. Mit einer KI (NotebookLm), der unterschiedliche Schwerpunkte gegeben wurden.

## Berichte als PDF
Das verwendete Werkzeug (dataspot) generiert Berichte je Modelltyp. Das ganze Informationsmodell (mit Entitäten, Attributen, Beziehungen, Referenzdaten (LOVs) und Wertebereichen) wurden zu einem einzigen PDF zusammeengefügt:

- Astronomie Informationsmodell Komplett.pdf

## Listen als Excel
Excels dienen der Bearbeitung und Betrachtung durch Menschen, bzw. zum Datenaustausch.

Das Info-Excel dient als Nachschlagedokument für Menschen, die sich für Elemente und ihre Details interessieren.

Alle Excels sind aus dem original Modelexport generiert. 

- Astronomie Informationsmodell.xlsx
	Der Modelexport ist ein Export aus dem Modellierungstool (dataspot, manuelle zusammenfassung aus 3 Excels.). Er dient dazu Massenupdate vorzunehmen und zurück ins Werkzeug zu importieren.

- Astronomie-model-info.xlsx\
	Kommunikationsfreundliches Excel als Nachschlagedokument für Menschen, die etwas über die Elemente wissen wollen.

- Astronomie-model-sample.xlsx ALPHA\ 
	Excel mit Beispieldaten (aus den IM-Beschreibungen) als Strukturbeispiel für eine EXCEL / CSV Datenschnittstelle
	ALPHA, nur wenige Beispiele generiert.
	
## json

- astronomie-information-model-simple.json
    Die einfache Version (simple) enthält weniger Objekte. Es ist ein Übersichtsdiagramm mit den wichtigsten Elementen und Merkmalen. Obwohl es nicht vollständig ist, entspricht es ebenfalls dem Standard.  

- astronomie-information-model-schema.json ALPHA\
	Beispiel eines json-schema Datei, die ein json beschreibt, das Daten für Astronomie-Objekte aufnehmen kann. 
	ALPHA, erst einige wenige Elemente werden generiert
	
- astronomie-information-model-sample.json ALPHA\
	Beispiel von realen Daten die durch die json-schema Datei definiert werden.\
	Beispielwerte aus Modellbeschreibung verwendet.
	ALPHA, erst einige wenige Elemente werden generiert

 