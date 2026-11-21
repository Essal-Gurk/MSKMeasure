# IsiX MSK Measurements
Community Beta · v0.5 · Apple Silicon

IsiX MSK Measurements is an independent plugin for the IsiX DICOM Viewer. It shows how to measure musculoskeletal distances, angles, and indices. The methods include anatomical diagrams, labeled landmarks, guidance on image acquisition, and links to the relevant literature.
What's in the beta
- 76 measurement methods across 18 areas, including patellar height, TT–TG distance, weight-bearing hindfoot alignment, and full-leg alignment.
- Step-by-step diagrams and filters for body region, imaging modality, and age group.
- Distance and angle entry. Depending on the method, the plugin calculates an index or compares sides and displays a reference or a brief interpretation.
- User interface and measurement catalog available in ten languages.
Intended use and regulatory status of the beta
This version is intended for technical evaluation by the IsiX community and for demonstrating measurement workflows. Test installation, usability, diagrams, and calculations outside patient care using synthetic image series and fictitious measurements.

The beta is not intended for clinical reporting, diagnosis, follow-up assessment, treatment planning, or decisions about individual patients. Use its results only for testing. Keep measurements, brief interpretations, and copied result text from the beta out of clinical reports and patient records.

No conformity with Regulation (EU) 2017/745 on medical devices (MDR) is claimed for this beta. The regulatory status of each version depends on its intended purpose and specific functionality. See the EU MDR, particularly Article 2, points (1) and (12) and the MDCG guidance on qualification and classification of software.
Requirements and installation
- A Mac with Apple Silicon running macOS 15 or later.
- The GitHub edition of IsiX. The v0.5 build was built for IsiX 6.0.3 using IsiXPluginKit 6.0.3. The Mac App Store edition of IsiX does not load external plugins.
1. Open Releases in this repository and download the Apple Silicon plugin ZIP under Assets.
2. Extract the ZIP and use the IsiX Plugin Manager to install the included IsiXMSKMessungen.isixplugin bundle.
3. Restart IsiX, open a synthetic test series, and select MSK Messungen (v0.5) from the plugin menu. The menu label varies with the language setting.
To uninstall, quit IsiX and remove the bundle from ~/Library/Application Support/IsiX/Plugins/ if you installed it there.
Beta feedback
Open an Issue to report a bug or suggest an improvement. Include the plugin version, IsiX version, macOS version, measurement method and imaging modality, steps to reproduce the issue, and what you observed and expected.

Issues are public. Use fictitious measurements and synthetic test data. Keep patient images, DICOM files from clinical practice, reports, and logs containing identifying information out of public issues.
Terms of use
The release package contains the terms of use for the corresponding beta build and any third-party notices.
