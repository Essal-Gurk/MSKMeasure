# MSKmeasure for IsiX · v0.6

v0.6 includes 76 measurement methods across 18 anatomical regions. The plugin was built with IsiXPluginKit API v1 / Kit 1.0.0 for Apple Silicon running macOS 15 or later. The SDK directory uses the host version number 6.0.5; the API and kit versions recorded in `Docs/SDK.json` identify the SDK used.

## New in v0.6

- The product name, module, entry-point class and bundle are now MSKmeasure. The existing bundle identifier and saved language preference are preserved.
- Mouse-over help for filters, search, language selection, method selection, input fields and their permitted ranges, measurement profiles, sources, copying results and schematic controls.
- Clarified PTI interpretation, the MCS borderline range and the Tönnis reference range; all changes are available in ten languages.
- Extended checks covering all formulas, input limits, exact reference thresholds and translation placeholders.
- Review scope and limitations are documented in `Docs/REVIEW-v0.6.md` (German).

## Installation

1. Extract the ZIP file and quit IsiX.
2. In Terminal, open the extracted directory and run `./install.sh`. The script installs the bundle in `~/Library/Application Support/IsiX/Plugins/`. Alternatively, copy `Prebuilt/MSKmeasure.isixplugin` to that directory using Finder. **Go to Folder** (⌘⇧G) opens the destination path.
3. Start IsiX, open an image series and select **MSKmeasure (v0.6)** from the plugin menu. The menu title uses the language selected when IsiX starts.

To prevent duplicate registration, the installation script moves an existing `IsiXMSKMessungen.isixplugin` bundle with the matching bundle identifier to `../MSKmeasure-Backups/`. When installing manually, move the old bundle out of the Plugins directory first.

## Language and result text

**Language → System language** uses the first supported language in the macOS preferred-language list. English is the fallback. A manual selection takes effect immediately in the plugin window and is saved. The IsiX menu entry adopts the selected language the next time IsiX starts.

The interface, measurement catalogue and result text are available in German, English, French, Spanish, Portuguese, Italian, Turkish, Arabic, Simplified Chinese and Japanese. The Arabic interface uses a right-to-left layout.

**Copy result text** copies the displayed measurement method, modality, value, reference and brief assessment to the clipboard. Interpretation uses the selected measurement profile. If the method uses an adult reference and no age is available, the plugin requests the patient's age. For patients under 18, an age-related interpretation notice is displayed.

## Age filters

Selecting **All ages**, **Adults** or **Children and adolescents** filters the entire catalogue. Methods applicable across age groups remain available in both target groups. Specifically paediatric methods, such as the Baumann angle, ulnar bow sign, acetabular index and Reimers migration percentage, appear under the paediatric filter.

The age-group filter and the patient's age serve different purposes. The filter controls which methods are displayed. The patient's age controls interpretation against the stored reference. Adult thresholds are identified accordingly when assessing children. Open growth plates and skeletal maturity must be considered for paediatric methods. The coronal Cobb angle uses its general reference in children as well.

Finger and thumb measurements are currently included under Hand. Separate subsections can be introduced as more joint-specific methods are added.

## Schematics and measurement steps

All 76 measurement methods have a built-in anatomical schematic with numbered landmarks. The completed measurement drawing is displayed immediately. **Previous**, **Next** and **Play** navigate through four steps: anatomy and acquisition, landmarks, reference lines and the completed measurement. Automatic playback reveals the steps at 2.6-second intervals. **Enlarge** opens a larger view.

Landmark legends and explanations are available in all ten languages. Medical image orientation is preserved in the Arabic interface. Crossfades are disabled when the macOS Reduce Motion setting is enabled.

The schematics are not to scale and do not change measurement values or references. A, B and C correspond to the input fields. Rotational methods show separate slice levels and parallel transfer of the axes. For TT–TG, the CT schematic uses the tibial tuberosity, while the MRI schematic uses the patellar tendon insertion. Measurements are still performed on the patient's images in IsiX.

## Using the plugin

- The plugin suggests anatomical-region and modality filters from the series and study descriptions. Use the filters and search to refine ambiguous descriptions.
- The list is organised by anatomical region. Search recognises names, regions and synonyms such as `TT-TG`, `Lisfranc`, `Reikerås` and `Insel Salvini`. HKA, MPTA and mLDFA are primarily listed under **Full-length leg radiographs** and can also be accessed through **Knee**. The three rotational measurements are additionally accessible through their respective joint regions.
- Each entry provides landmarks, acquisition instructions and an anatomical schematic that can be built up step by step. Source links lead to method descriptions and reference literature.
- Perform the measurement in IsiX and enter distances or angles into the fields. For indices, trochlear depth and calculated side-to-side comparisons, the plugin calculates the result from the component measurements. Both decimal commas and decimal points are accepted.
- Four patellar-height indices are grouped under **Patellar height** in the same window. A modality filter shows the indices available for that modality. Without a modality filter, the measurement profile can be selected directly on the card.
- The plugin calculates the patient's age on the examination date from the date of birth and examination date, if both are available in IsiX. Age can also be entered manually. Children’s measurements are displayed without automatic adult classification. Protocol-dependent methods without a stored threshold produce descriptive output.
- Entries are retained when switching measurement cards and are associated with the respective method and modality. Opening the plugin from a different study starts a new session. Entries are held in memory.

## Measurement catalogue

| Region | Methods in v0.6 |
|---|---|
| Knee | Patellar height using ISI, CDI, BPI and PTI; TT–TG distance; trochlear sulcus angle; lateral trochlear inclination; trochlear depth; patellar tilt; Merchant congruence angle; medial meniscal extrusion; medial posterior tibial slope |
| Ankle | Medial tibiotalar clear space; distal tibiofibular clear space; varus talar tilt |
| Midfoot and foot | Hallux valgus angle; first–second intermetatarsal angle; Meary angle; calcaneal pitch; talonavicular uncoverage; C1–M2 Lisfranc distance |
| Hip | Lateral centre-edge angle; Tönnis angle; alpha angle; femoral neck-shaft (CCD) angle |
| Shoulder | Acromiohumeral distance; critical shoulder angle; side-to-side coracoclavicular comparison; glenoid version using the Friedman method |
| Elbow | Baumann angle with an open growth plate; humeroulnar carrying angle |
| Wrist | Scapholunate gap and angle; ulnar variance; volar tilt; radial inclination |
| Hand | Fifth metacarpal head-neck angulation; displacement of the thumb MCP ulnar collateral ligament |
| Full-length leg radiographs | HKA; MPTA; mLDFA; mechanical axis deviation; joint-line convergence angle; anatomical leg-length difference |
| Rotational studies | Femoral version using the Reikerås method; tibiofemoral rotation angle; bimalleolar tibial torsion |

The cards contain the relevant references and links to professional sources. Consensus on acquisition technique and a literature-based orientation threshold have different evidential weight. The three rotational methods report the angle, sign convention and protocol context. Interpretation depends on the method used and, where applicable, a side-to-side comparison. The alpha angle describes cam morphology. A diagnosis of femoroacetabular impingement syndrome requires corresponding clinical findings.

### References for the established knee and full-length leg measurements

| Measurement | Modality in v0.6 | Reference or convention |
|---|---|---|
| Insall–Salvati | CR/DX, MRI | Radiography: 0.80–1.20. MRI: 0.74–1.50 according to Shabshin et al. |
| Caton–Deschamps | CR/DX, MRI, CT | Radiography: 0.60–1.20. MRI and CT: descriptive assessment with literature references. |
| Blackburne–Peel | CR/DX | 0.50–1.00 on a lateral radiograph. |
| Patellotrochlear index | MRI | Historical thresholds: <12.5% for patella alta and >50% for patella baja in standardised extension. |
| TT–TG | MRI, CT | MRI: >15 mm according to McNassor et al. CT: 15–20 mm borderline; >20 mm increased. |
| Trochlear sulcus angle | CR/DX, MRI, CT | Tangential radiography: >145°. MRI in extension: >160° according to McNassor et al. CT: descriptive assessment. |
| Lateral trochlear inclination | MRI | <11° using the specified protocol. |
| Axial trochlear depth | MRI | ≤3 mm according to Pfirrmann et al. |
| Patellar tilt | MRI, CT | CT: >20° as an orientation threshold. MRI: descriptive assessment. |
| Merchant congruence angle | CR/DX | >+16° in the Merchant projection. |
| Medial meniscal extrusion | MRI | ≥3 mm on non-weight-bearing coronal MRI as an orientation threshold. |
| Medial posterior tibial slope | CR/DX | 6–12° using a proximal tibial axis defined by midpoints 5 and 15 cm below the joint line. |
| Mechanical hip–knee–ankle alignment (HKA) | CR/DX | 0° ±3°, expressed as deviation from 180° on a standing AP full-length leg radiograph. Varus is negative. |
| Mechanical medial proximal tibial angle | CR/DX | 85–90° according to the HSS reference table. |
| Mechanical lateral distal femoral angle | CR/DX | 85–90° according to the HSS reference table. |

References apply to the technique described on the respective card. Patellofemoral measurements may be affected by knee flexion, quadriceps activation, bony versus cartilaginous landmarks and slice selection. [Overview of methods](https://pmc.ncbi.nlm.nih.gov/articles/PMC10012577/) · [Guide to knee measurements](https://pmc.ncbi.nlm.nih.gov/articles/PMC13139256/)

## Regulatory notice — Germany and the European Union

**Regulation (EU) 2017/745 on medical devices (MDR)** applies in Germany. Software may qualify as a medical device depending on its intended purpose; the definition in Article 2 and the software classification provisions in Annex VIII, particularly Rule 11, are relevant.

MSKmeasure calculates patient-specific indices and displays reference-based assessments. These functions require a documented regulatory assessment before medical-device deployment. This README does not establish a device classification, conformity assessment or CE marking. No EU declaration of conformity or evidence of MDR conformity is supplied with this release. Technical tests and literature checks do not establish clinical validation or regulatory conformity.

**Do not deploy this release for patient diagnosis or treatment decisions until the applicable regulatory requirements have been assessed and fulfilled.** The medical-device status and risk class must be determined for the defined intended purpose and use context. Any applicable conformity assessment, clinical evaluation, risk management and other manufacturer obligations must be addressed before placing the software on the market or putting it into service.

A disclaimer, professional supervision, free distribution or source-code availability does not by itself establish an MDR exemption. Describing software as educational or research software must be consistent with its actual intended purpose and claims. A README notice cannot resolve that assessment.

Official references:

- [Regulation (EU) 2017/745 — EUR-Lex, with access to the current consolidated version](https://eur-lex.europa.eu/eli/reg/2017/745/oj/eng)
- [MDCG 2019-11 Rev.1, June 2025 — qualification and classification of medical device software](https://health.ec.europa.eu/system/files/2025-06/mdcg_2019_11_en.pdf). This guidance is not legally binding.

This section provides regulatory information; it is not a legal opinion or a conformity assessment.

## Further development

Drawings are stored as vector data in `Resources/Schematics.json`; rendering and playback are implemented in `Sources/DiagramWalkthrough.swift`. New methods must include a schematic and fully translated landmarks. Validation checks coverage of every modality profile.

The catalogue is stored in `Resources/KneeMeasurements.json`, `Resources/ExtremityMeasurements.json` and `Resources/AxialMeasurements.json`. Each method specifies its primary region, additional region filters, age group and modality profiles. Fracture classifications and injury grading belong in a separate plugin.

All ten languages are required for future versions. Add new or revised interface text, measurement descriptions and result assessments to `Resources/Localization.json` for every language. German source strings serve as keys for additional text in the German measurement catalogue.

With Xcode installed, run `./build.sh /path/to/IsiXPluginKit-SDK` or `./build.sh /path/to/SDK.zip` to build the ad-hoc-signed bundle. Without an argument, the script uses `MSKMEASURE_SDK` or `~/Downloads/IsiXPluginKit-SDK-6.0.5`. It checks API v1, Kit 1.0.0 and the SDK binary checksum. The framework is provided by the IsiX host and is not embedded. SDK and template: [IsiXPluginTemplate](https://github.com/ThalesMMS/IsiXPluginTemplate).

`./test.sh` checks calculations, input and reference limits, search, viewer detection, schematic coverage, translations and result formatting. A successful build does not test execution inside IsiX. Final testing with real patient images and the specific host version remains necessary, subject to the regulatory requirements above.
