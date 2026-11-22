#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build
xcrun swiftc -module-cache-path "$PWD/.build/ModuleCache" -o .build/MeasurementTests \
    Sources/Measurement.swift Sources/Localization.swift Sources/DiagramScene.swift Tests/MeasurementTests.swift
.build/MeasurementTests Resources/KneeMeasurements.json Resources/Localization.json Resources/ExtremityMeasurements.json Resources/AxialMeasurements.json Resources/Schematics.json
