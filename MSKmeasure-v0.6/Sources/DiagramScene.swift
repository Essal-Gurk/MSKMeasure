import Foundation

struct DiagramAtlas: Decodable {
    struct Shape: Decodable {
        let points: [[Double]]
        let closed: Bool
        let tissue: String
    }

    struct Landmark: Decodable, Identifiable {
        let id: Int
        let point: [Double]
        let label: String
    }

    struct Stroke: Decodable {
        let points: [[Double]]
        let label: String?
        let labelPoint: [Double]?
    }

    struct Scene: Decodable, Identifiable {
        let id: String
        let template: String
        let view: String
        let landmarks: [Landmark]
        let references: [Stroke]
        let measurements: [Stroke]
        let modality: Modality?
        let note: String?
    }

    let anatomy: [String: [Shape]]
    let scenes: [Scene]

    func scene(for method: Measurement, modality: Modality) -> Scene? {
        scenes.first { $0.id == method.id && $0.modality == modality }
            ?? scenes.first { $0.id == method.id && $0.modality == nil }
    }

    func validate(catalog: [Measurement], translations: TranslationTable) throws {
        func valid(_ point: [Double]) -> Bool {
            point.count == 2 && point.allSatisfy { $0.isFinite } &&
                (0...240).contains(point[0]) && (0...180).contains(point[1])
        }

        for method in catalog {
            for profile in method.profiles {
                guard let scene = scene(for: method, modality: profile.modality),
                      let shapes = anatomy[scene.template],
                      method.diagram != nil || !shapes.isEmpty,
                      !scene.landmarks.isEmpty,
                      method.diagram != nil || !scene.measurements.isEmpty,
                      Set(scene.landmarks.map(\.id)).count == scene.landmarks.count else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let shapesValid = shapes.allSatisfy { $0.points.count >= 2 && $0.points.allSatisfy(valid) }
                let pointsValid = scene.landmarks.allSatisfy { valid($0.point) }
                let linesValid = (scene.references + scene.measurements).allSatisfy {
                    $0.points.count >= 2 && $0.points.allSatisfy(valid) &&
                        ($0.labelPoint.map(valid) ?? true)
                }
                guard shapesValid && pointsValid && linesValid else { throw CocoaError(.fileReadCorruptFile) }
                for language in MSKLanguage.allCases {
                    let localization = translations.language(language)
                    for text in [scene.view] + scene.landmarks.map(\.label) + [scene.note].compactMap({ $0 }) {
                        guard language == .de || localization.catalog[text] != nil else {
                            throw CocoaError(.fileReadCorruptFile)
                        }
                    }
                }
            }
        }
        let keys = scenes.map { $0.id + ":" + ($0.modality?.rawValue ?? "*") }
        guard Set(keys).count == keys.count,
              scenes.allSatisfy({ scene in catalog.contains { $0.id == scene.id } }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
}
