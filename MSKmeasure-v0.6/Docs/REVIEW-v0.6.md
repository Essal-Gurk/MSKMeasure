# MSKmeasure v0.6 – Plausibilitätsprüfung

Stand: 22.11.2026. Umfang: 76 Messmethoden, 18 Regionen, 10 Sprachen.

## Prüfumfang

Alle Katalogeinträge wurden auf Landmarkendefinition, Messrichtung, Einheit, Formel, zulässige Eingabebereiche, Modalitätsprofile und altersbezogene Bewertungslogik durchgesehen. Formeln, unzulässige Eingaben, Nenner null, Überlappung > Gesamtlänge, Trochleatiefengeometrie und exakte Klassifikationsgrenzen werden automatisiert geprüft. Der Alterssuchfilter ersetzt keine altersbezogene Referenz.

Die Recherche vor diesem Build kontrollierte gezielt modalitätsabhängige Patellamessungen, Hüftwinkel, Neutral- gegenüber Stressaufnahmen am OSG, Unterarmkrümmung, distale Radiusparameter, SL-Messungen, CSA, SRS/SDSG-Wirbelsäulenmessungen und AACPDM-Migrationsanteil. Die Quellen jedes Katalogeintrags bleiben zugänglich. Nicht jede Originalarbeit wurde vollständig erneut gelesen; einzelne Volltextzugriffe wurden durch Zugriffsschutz blockiert. Dies ist eine technische und literaturgestützte Plausibilitätsprüfung, keine unabhängige klinische Validierung aller Verfahren.

## Korrekturen

- PTI: verminderte Überlappung entspricht einem Hinweis auf Patella alta, vermehrte Überlappung auf Patella baja. Die bisherige unklare Indexrichtung in den Ausgabetexten wurde korrigiert. Formel und Grenzwerte bleiben methodenbezogen.
- MCS: in der neutralen Mortise-Aufnahme bei 4–5 mm Grenzbereich ausgeben. >5 mm bleibt auffällig. Die Beschreibung trennt Stress- und Neutralaufnahme; sie bewertet den tiefen Deltabandstatus nicht allein anhand eines Abstands.
- Tönnis-Winkel: 0–10° als Orientierungsbereich; negative Werte erhalten einen Überüberdachungshinweis. Der ebenfalls publizierte Bereich −10–10° wird ausdrücklich genannt. Ein Winkel diagnostiziert kein klinisches FAI-Syndrom.

## Wesentliche Einordnungen

- TT–TG: CT- und MRT-Referenzen bleiben getrennt; pädiatrische Werte nicht mit Erwachsenen-Grenzen klassifizieren.
- CCD: 125–145° ist die hinterlegte quellenspezifische Konvention, keine universelle altersunabhängige Norm.
- SRS–Schwab: positive SVA ab 40 mm, PT ab 20°, PI–LL ab 10° als Orientierungsgrenzen der adulten Deformitätsbeurteilung; keine individuellen Operationsziele.
- ADI: Erwachsenen-Röntgenregel nicht auf Kinder oder CT übertragen. Kinderhinweis statt Erwachsenenklassifikation.
- Radiuskrümmung: die 7,21 % bzw. ca. 60 % stammen aus einer Kindernormstudie; bei Erwachsenen Seitenvergleich.
- Reimers: AACPDM-Verweis >30 % gilt für die Hüftüberwachung bei Zerebralparese; keine generelle Norm für alle Kinder.
- Bei fehlender belastbarer protokollunabhängiger Schwelle bleibt die Ausgabe deskriptiv. Körperhaltung, Belastung, Projektion, Alter und offene Fugen anhand der Messkarte prüfen.
- Schemata sind Orientierungshilfen; Messwerte werden ausschließlich aus den Patientenbildern manuell eingegeben.

## Kontrollierte Quellen (Auswahl)

- [McNassor et al., patellofemorale Messverfahren](https://doi.org/10.1177/26350254251375085)
- [Shabshin et al., MRT-Patellahöhe](https://pubmed.ncbi.nlm.nih.gov/15221214/)
- [Mannava et al., Hüftröntgen](https://pmc.ncbi.nlm.nih.gov/articles/PMC5794674/)
- [Abweichende Tönnis-Konvention](https://pmc.ncbi.nlm.nih.gov/articles/PMC4972716/)
- [MCS unter Stress](https://pubmed.ncbi.nlm.nih.gov/31695262/)
- [Firl und Wünsch, Radiuskrümmung](https://pubmed.ncbi.nlm.nih.gov/15446536/)
- [Distale Radiusparameter](https://pmc.ncbi.nlm.nih.gov/articles/PMC9038308/)
- [SL-Abstand und Projektionsabhängigkeit](https://pubmed.ncbi.nlm.nih.gov/26034436/)
- [Moor et al., CSA](https://pubmed.ncbi.nlm.nih.gov/23814246/)
- [SDSG-Handbuch](https://www.srs.org/Files/Research/Manuals-and-Publications/sdsg-radiographic-measuremnt-manual.pdf)
- [SRS–Schwab](https://pmc.ncbi.nlm.nih.gov/articles/PMC6259802/)
- [AACPDM](https://www.aacpdm.org/publications/care-pathways/hip-surveillance-in-cerebral-palsy)

## Vollständiger technischer Katalogabgleich

Formel und Modalitäten entsprechen den tatsächlich gebündelten JSON-Daten. „Deskriptiv“ bedeutet, dass keine automatische Schwellenklassifikation erfolgt.

| ID | Methode | Formel | Profile |
|---|---|---|---|
| isi | Insall–Salvati-Index | ratio | XR: Schwellenregel; MR: Schwellenregel |
| cdi | Caton–Deschamps-Index | ratio | XR: Schwellenregel; MR: deskriptiv; CT: deskriptiv |
| bpi | Blackburne–Peel-Index | ratio | XR: Schwellenregel |
| pti | Patellotrochleärer Index | percent | MR: Schwellenregel |
| tttg | TT–TG-Abstand | direct | CT: Schwellenregel; MR: Schwellenregel |
| sulcus | Trochleawinkel | direct | XR: Schwellenregel; MR: Schwellenregel; CT: deskriptiv |
| lti | Laterale Trochleainklination | direct | MR: Schwellenregel |
| depth | Axiale Trochleatiefe | depth | MR: Schwellenregel |
| tilt | Patellatilt | direct | CT: Schwellenregel; MR: deskriptiv |
| merchant | Kongruenzwinkel nach Merchant | direct | XR: Schwellenregel |
| extrusion | Mediale Meniskusextrusion | direct | MR: Schwellenregel |
| slope | Medialer posteriorer Tibiaslope | direct | XR: Schwellenregel |
| hka | Mechanische Beinachse (HKA) | direct | XR: Schwellenregel |
| mpta | Mechanischer medialer proximaler Tibiawinkel | direct | XR: Schwellenregel |
| mldfa | Mechanischer lateraler distaler Femurwinkel | direct | XR: Schwellenregel |
| mcs | Medialer tibiotalarer Gelenkspalt (MCS) | direct | XR: Schwellenregel |
| tfcs | Distaler tibiofibularer Abstand (TFCS) | direct | XR: Schwellenregel |
| talarTilt | Talar Tilt in Varusrichtung | direct | XR: Schwellenregel |
| hva | Hallux-valgus-Winkel (HVA) | direct | XR: Schwellenregel |
| ima | Intermetatarsalwinkel I–II (IMA) | direct | XR: Schwellenregel |
| meary | Meary-Winkel | direct | XR: Schwellenregel |
| pitch | Kalkaneusneigung (Calcaneal Pitch) | direct | XR: Schwellenregel |
| tnu | Talonavikuläre Nichtüberdachung | percent | XR: Schwellenregel |
| lisfranc | Lisfranc-Abstand (C1–M2) | direct | XR: Schwellenregel |
| lcea | Lateraler CE-Winkel nach Wiberg (LCEA) | direct | XR: Schwellenregel |
| tonnis | Tönnis-Winkel (Sourcil-Neigung) | direct | XR: Schwellenregel |
| alpha | Alpha-Winkel der Hüfte | direct | XR: Schwellenregel; MR: Schwellenregel |
| ccd | Caput-Collum-Diaphysen-Winkel (CCD) | direct | XR: Schwellenregel |
| ahd | Akromiohumeraler Abstand (AHD) | direct | XR: Schwellenregel |
| csa | Kritischer Schulterwinkel (CSA) | direct | XR: Schwellenregel |
| cc | Korakoklavikulärer Seitenvergleich | relativeDifference | XR: deskriptiv |
| glenoid | Glenoidversion nach Friedman | direct | CT: deskriptiv |
| baumann | Baumann-Winkel | direct | XR: deskriptiv |
| carrying | Humeroulnarer Tragewinkel | direct | XR: deskriptiv |
| slgap | Skapholunärer Abstand (SL) | direct | XR: Schwellenregel |
| slangle | Skapholunärer Winkel (SL) | direct | XR: Schwellenregel |
| ulnavar | Ulnavarianz | direct | XR: deskriptiv |
| volar | Palmare Neigung des distalen Radius | direct | XR: Schwellenregel |
| radial | Radiale Inklination | direct | XR: Schwellenregel |
| mc5 | Kopf-Hals-Angulation des Metakarpale V | direct | XR: deskriptiv |
| thumbUCL | Daumen-MCP: Dislokation des ulnaren Kollateralbands | direct | MR: Schwellenregel |
| mad | Mechanische Achsabweichung (MAD) | direct | XR: deskriptiv |
| jlca | Gelenklinien-Konvergenzwinkel (JLCA) | direct | XR: Schwellenregel |
| lld | Anatomische Beinlängendifferenz | difference | XR: deskriptiv |
| femVersion | Femurversion nach Reikerås | direct | CT: deskriptiv; MR: deskriptiv |
| kneeRotation | Tibiofemoraler Rotationswinkel | direct | CT: deskriptiv; MR: deskriptiv |
| tibTorsion | Tibiatorsion (bimalleoläre Methode) | direct | CT: deskriptiv; MR: deskriptiv |
| hindMoment | Rückfuß-Hebelarm nach Saltzman | direct | XR: deskriptiv |
| hindAngle | Belasteter Rückfuß-Achswinkel | direct | XR: deskriptiv |
| talocalc | Lateraler Talokalkaneuswinkel | direct | XR: deskriptiv |
| radBow | Relative Radiuskrümmung | percent | XR: deskriptiv |
| radSite | Lage der maximalen Radiuskrümmung | percent | XR: deskriptiv |
| forearmAPAngle | Unterarm-Achsabweichung a.p. | direct | XR: deskriptiv |
| forearmLatAngle | Unterarm-Achsabweichung seitlich | direct | XR: deskriptiv |
| ulnaBow | Ulnar Bow Sign | direct | XR: deskriptiv |
| chamberlain | Densstand zur Chamberlain-Linie | direct | CT: Schwellenregel; MR: Schwellenregel |
| mcrae | Densstand zur McRae-Linie | direct | CT: Schwellenregel; MR: Schwellenregel |
| adi | Vorderer Atlantodentalabstand (ADI) | direct | XR: Schwellenregel |
| padi | Hinterer Atlantodentalabstand (PADI) | direct | XR: Schwellenregel |
| cervLordosis | Zervikale Lordose C2–C7 | direct | XR: deskriptiv |
| cervSVA | Zervikale sagittale Vertikalachse C2–C7 | direct | XR: Schwellenregel |
| thorKyphosis | Thorakale Kyphose T5–T12 | direct | XR: deskriptiv |
| cobb | Koronarer Cobb-Winkel | direct | XR: Schwellenregel; CT: deskriptiv; MR: deskriptiv |
| lumbarLordosis | Lumbale Lordose L1–S1 | direct | XR: deskriptiv |
| slip | Wirbelgleiten in Prozent | percent | XR: deskriptiv; CT: deskriptiv; MR: deskriptiv |
| sva | Globale sagittale Vertikalachse C7–S1 | direct | XR: Schwellenregel |
| pi | Pelvic Incidence (PI) | direct | XR: deskriptiv |
| pt | Pelvic Tilt (PT) | direct | XR: Schwellenregel |
| ss | Sacral Slope (SS) | direct | XR: deskriptiv |
| pill | PI–LL-Differenz | difference | XR: Schwellenregel |
| sijWidth | ISG-Gelenkspaltweite | direct | CT: deskriptiv |
| acea | Vorderer CE-Winkel (ACEA) | direct | XR: deskriptiv |
| extrusionIndex | Femurkopf-Extrusionsindex | percent | XR: Schwellenregel |
| sharp | Pfannendachwinkel nach Sharp | direct | XR: deskriptiv |
| acetIndex | Pädiatrischer Acetabulumindex | direct | XR: deskriptiv |
| reimers | Reimers-Migrationsprozent | percent | XR: deskriptiv |
