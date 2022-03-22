/*
Datenquelle: https://www.kaggle.com/tmthyjames/nashville-housing-data
Der Originaldatensatz wurde in reduziertem  Umfang verwendet, der Header wurde zur Vereinfachung ins Deutsche übersetzt.


*/

Select *
From DataCleaning.dbo.Datensatz


-- Schritt 1: Anpassen des Verkaufsdatums
-- Datum Konvertieren
Select Verkaufsdatum, CONVERT(Date, Verkaufsdatum)
From DataCleaning.dbo.Datensatz

-- Update Datensatzes
UPDATE DataCleaning.dbo.Datensatz
SET Verkaufsdatum = CONVERT(Date, Verkaufsdatum)

-- Überprüfung, falls das Update nicht funktioniert hat -> Alternative
Select Verkaufsdatum
From DataCleaning.dbo.Datensatz

-- Alternative, erstellen einer neuen Spalte
ALTER TABLE DataCleaning.dbo.Datensatz
ADD Verkaufsdatum_Neu Date;
UPDATE DataCleaning.dbo.Datensatz
SET Verkaufsdatum_Neu = CONVERT(Date, Verkaufsdatum)

--Überprüfung
Select Verkaufsdatum_Neu
From DataCleaning.dbo.Datensatz



-- Schritt 2: Leere Grundstücksadressen ersetzen
-- Abfrage der Datenlage
Select Grundstück_Anschrift
From DataCleaning.dbo.Datensatz

Select *
From DataCleaning.dbo.Datensatz
--WHERE Grundstück_Anschrift is NULL
ORDER BY Grundstück_ID

-- Vergleich von Grundstück_ID = Grundstück_Anschrift via self Join
Select a.Grundstück_ID , a.Grundstück_Anschrift, b.Grundstück_ID , b.Grundstück_Anschrift
From DataCleaning.dbo.Datensatz a
JOIN DataCleaning.dbo.Datensatz b
    on a.Grundstück_ID = b.Grundstück_ID
    AND a.ID <> b.ID
WHERE a.Grundstück_Anschrift is NULL

-- Ersetzen von Null Angaben mit b.Grundstück_Anschrift
Select a.Grundstück_ID , a.Grundstück_Anschrift, b.Grundstück_ID , b.Grundstück_Anschrift, ISNULL(a.Grundstück_Anschrift, b.Grundstück_Anschrift)
From DataCleaning.dbo.Datensatz a
JOIN DataCleaning.dbo.Datensatz b
    on a.Grundstück_ID = b.Grundstück_ID
    AND a.ID <> b.ID
WHERE a.Grundstück_Anschrift is NULL

-- Update durchführen
UPDATE a
SET Grundstück_Anschrift = ISNULL(a.Grundstück_Anschrift, b.Grundstück_Anschrift)
From DataCleaning.dbo.Datensatz a
JOIN DataCleaning.dbo.Datensatz b
    on a.Grundstück_ID = b.Grundstück_ID
    AND a.ID <> b.ID

-- Änderung überprüfen
Select a.Grundstück_ID , a.Grundstück_Anschrift, b.Grundstück_ID , b.Grundstück_Anschrift
From DataCleaning.dbo.Datensatz a
JOIN DataCleaning.dbo.Datensatz b
    on a.Grundstück_ID = b.Grundstück_ID
    AND a.ID <> b.ID

-- Schritt 3: Property Adresse und Stadt in seperate Spalten schreiben
-- Datenlage prüfen
Select Grundstück_Anschrift
From DataCleaning.dbo.Datensatz

-- Adresse und Stadt werden in Grundstück_Anschrift durch ein Komma getrennt.
-- Hier: Einsatz von Substring und char Index
SELECT
SUBSTRING(Grundstück_Anschrift, 1, CHARINDEX(',', Grundstück_Anschrift) -1) as Grundstück_Adresse,
SUBSTRING(Grundstück_Anschrift, CHARINDEX(',', Grundstück_Anschrift) +1, LEN(Grundstück_Anschrift)) as Grundstück_Stadt
From DataCleaning.dbo.Datensatz

-- Neue Spalten erstellen, Änderung schreiben
ALTER TABLE DataCleaning.dbo.Datensatz
ADD Grundstück_Adresse Nvarchar(225);
UPDATE DataCleaning.dbo.Datensatz
SET Grundstück_Adresse = SUBSTRING(Grundstück_Anschrift, 1, CHARINDEX(',', Grundstück_Anschrift) -1)

ALTER TABLE DataCleaning.dbo.Datensatz
ADD Grundstück_Stadt Nvarchar(225);
UPDATE DataCleaning.dbo.Datensatz
SET Grundstück_Stadt = SUBSTRING(Grundstück_Anschrift, CHARINDEX(',', Grundstück_Anschrift) +1, LEN(Grundstück_Anschrift))

--Überprüfung
Select *
From DataCleaning.dbo.Datensatz


-- Schritt 4: Bereinigen von Eigentümer_Anschrift mittels PARSENAME
-- Datenlage prüfen.
Select Eigentümer_Anschrift
From DataCleaning.dbo.Datensatz

-- Eigentümer_Anschrift besteht aus Adresse, Stadt und Staat, welche durch Kommata getrennt werden.
-- Da PARSENAME nur nach Punkten sucht, müssen die Kommata zunächst ersetzt werden.
SELECT
PARSENAME(REPLACE(Eigentümer_Anschrift, ',', '.') ,3) as Eigentümer_Adresse,
PARSENAME(REPLACE(Eigentümer_Anschrift, ',', '.') ,2) as Eigentümer_Stadt,
PARSENAME(REPLACE(Eigentümer_Anschrift, ',', '.') ,1) as Eigentümer_Bundesstaat
From DataCleaning.dbo.Datensatz

-- Neue Spalten erstellen, Änderung schreiben
ALTER TABLE DataCleaning.dbo.Datensatz
ADD Eigentümer_Adresse Nvarchar(225);
UPDATE DataCleaning.dbo.Datensatz
SET Eigentümer_Adresse = PARSENAME(REPLACE(Eigentümer_Anschrift, ',', '.') ,3)

ALTER TABLE DataCleaning.dbo.Datensatz
ADD Eigentümer_Stadt Nvarchar(225);
UPDATE DataCleaning.dbo.Datensatz
SET Eigentümer_Stadt = PARSENAME(REPLACE(Eigentümer_Anschrift, ',', '.') ,2)

ALTER TABLE DataCleaning.dbo.Datensatz
ADD Eigentümer_Bundesstaat Nvarchar(225);
UPDATE DataCleaning.dbo.Datensatz
SET Eigentümer_Bundesstaat = PARSENAME(REPLACE(Eigentümer_Anschrift, ',', '.') ,1)

--Überprüfung
Select *
From DataCleaning.dbo.Datensatz


-- Schritt 5: Bereinigen der Spalte Leerverkauf
-- Datenlage prüfen
Select DISTINCT(Leerverkauf), COUNT(Leerverkauf)
From DataCleaning.dbo.Datensatz
GROUP BY Leerverkauf
ORDER BY 2

-- Y und N zu Yes und No abändern
Select Leerverkauf,
    CASE WHEN Leerverkauf = 'Y' THEN 'Yes'
         WHEN Leerverkauf = 'N' THEN 'No'
         ELSE Leerverkauf
         END   
From DataCleaning.dbo.Datensatz

-- Änderung speichern
UPDATE DataCleaning.dbo.Datensatz
SET Leerverkauf = CASE WHEN Leerverkauf = 'Y' THEN 'Yes'
                        WHEN Leerverkauf = 'N' THEN 'No'
                        ELSE Leerverkauf
                        END   

-- Überprüfung
Select DISTINCT(Leerverkauf), COUNT(Leerverkauf)
From DataCleaning.dbo.Datensatz
GROUP BY Leerverkauf
ORDER BY 2


-- Schritt 6: Duplikate entfernen
-- Duplikate  identifizieren
WITH CTE_ROW AS (
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY Grundstück_ID,
                     Grundstück_Anschrift,
                     Verkaufspreis,
                     Verkaufsdatum,
                     Rechtsgrundlagen 
        ORDER BY ID
    ) row_num
From DataCleaning.dbo.Datensatz
)
SELECT * 
FROM CTE_ROW
WHERE row_num > 1
ORDER BY Grundstück_Anschrift

-- Duplikate  löschen
WITH CTE_ROW AS (
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY Grundstück_ID,
                     Grundstück_Anschrift,
                     Verkaufspreis,
                     Verkaufsdatum,
                     Rechtsgrundlagen 
        ORDER BY ID
    ) row_num
From DataCleaning.dbo.Datensatz
)
DELETE 
FROM CTE_ROW
WHERE row_num >1


-- Schritt 7: Ungenutzet Spalten entfernen
-- Löschen der Spalten Grundstück_Anschrift, Verkaufsdatum, Eigentümer_Anschrift, Steuerbezirk
ALTER TABLE DataCleaning.dbo.Datensatz
DROP COLUMN Grundstück_Anschrift, Verkaufsdatum, Eigentümer_Anschrift, Steuerbezirk

-- Überprüfung
SELECT *
FROM DataCleaning.dbo.Datensatz