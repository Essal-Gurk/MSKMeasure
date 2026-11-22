import Foundation

enum Modality: String, Codable, CaseIterable, Identifiable {
    case MR, CT, XR

    var id: String { rawValue }

    init?(dicom: String?) {
        switch dicom?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "MR": self = .MR
        case "CT": self = .CT
        case "CR", "DX": self = .XR
        default: return nil
        }
    }
}

enum AgeGroup: String, Decodable, CaseIterable, Identifiable {
    case all, adult, pediatric
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .all: "allAges"
        case .adult: "adultMethods"
        case .pediatric: "pediatricMethods"
        }
    }
}

struct Measurement: Decodable, Identifiable {
    struct Field: Decodable, Identifiable {
        let id: String
        let label: String
        let unit: String
        let minimum: Double
        let maximum: Double
    }

    enum Formula: String, Decodable { case direct, ratio, percent, depth, difference, relativeDifference }

    struct Rule: Decodable {
        let low: Double?
        let high: Double?
        let lowText: String?
        let highText: String?
        let lowerInclusive: Bool
        let upperInclusive: Bool
        let intermediate: String?

        func interpretation(of result: Double, within: String) -> String {
            // Small tolerance keeps exact cutoffs stable after division.
            let tolerance = 1e-9
            if let low, result < low - tolerance || (lowerInclusive && abs(result - low) <= tolerance) {
                return lowText ?? within
            }
            if let high, result > high + tolerance || (upperInclusive && abs(result - high) <= tolerance) {
                return highText ?? within
            }
            return intermediate ?? within
        }
    }

    struct Profile: Decodable, Identifiable {
        let modality: Modality
        let setup: String
        let reference: String
        let rules: Rule?
        let within: String
        let pediatricReference: Bool?
        let descriptiveAssessment: String?
        let minimumReferenceAge: Int?

        var id: Modality { modality }

        func referenceLabel(age: Int?, localization: MSKLocalization) -> String {
            if pediatricReference == true { return localization.ui("pediatricReference") }
            if minimumReferenceAge == 0 { return localization.ui("reference") }
            return localization.ui(age.map { $0 < 18 } == true ? "adultReference" : "reference")
        }

        func assessment(of value: Double, age: Int?, localization: MSKLocalization) -> String {
            if pediatricReference == true {
                guard let age else { return localization.ui("ageRequired") }
                if age >= 18 { return localization.ui("outOfAge") }
            }
            guard let rules else {
                return descriptiveAssessment.map(localization.text) ?? localization.ui("descriptive")
            }
            guard let age else { return localization.ui("ageRequired") }
            guard age >= (minimumReferenceAge ?? 18) else { return localization.ui("pediatric") }
            return localization.text(rules.interpretation(of: value, within: within))
        }
    }

    struct Source: Decodable, Identifiable {
        let label: String
        let url: URL
        var id: URL { url }
    }

    let id: String
    let title: String
    let ageGroup: AgeGroup?
    let region: String
    let otherRegions: [String]?
    let group: String
    let aliases: String
    let diagram: AnatomyDiagram?
    let fields: [Field]
    let formula: Formula
    let technique: String
    let meaning: String
    let profiles: [Profile]
    let sources: [Source]

    var resultUnit: String {
        switch formula {
        case .direct, .difference: fields.first?.unit ?? ""
        case .ratio: ""
        case .percent, .relativeDifference: "%"
        case .depth: "mm"
        }
    }

    var resultPrecision: Int { formula == .ratio ? 3 : 2 }

    func isAvailable(region: String?, modality: Modality?, ageGroup: AgeGroup = .all) -> Bool {
        let matchesRegion = region.map { self.region == $0 || otherRegions?.contains($0) == true } ?? true
        let matchesModality = modality.map { selected in profiles.contains { $0.modality == selected } } ?? true
        let category = self.ageGroup ?? .all
        let matchesAge = ageGroup == .all || category == .all || category == ageGroup
        return matchesRegion && matchesModality && matchesAge
    }

    func matches(_ query: String, localization: MSKLocalization? = nil) -> Bool {
        let regions = [region] + (otherRegions ?? [])
        let regionTerms = regions.map { $0 == "Knie" ? "Knie Kniegelenk Kniegelenke knee" : $0 }
            .joined(separator: " ")
        let localized = localization.map { translation in
            ([title, group] + regions).map(translation.text).joined(separator: " ")
        } ?? ""
        let haystack = Self.normalized("\(title) \(regionTerms) \(group) \(aliases) \(localized)")
        let genericTerms = Set(Self.normalized("alle messung messungen messmethode messmethoden " +
            (localization?.ui("searchTerms") ?? "")).split(separator: " "))
        return Self.normalized(query).split(separator: " ").filter { !genericTerms.contains($0) }
            .allSatisfy { haystack.contains($0) }
    }

    static func normalized(_ input: String) -> String {
        input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
            .replacingOccurrences(of: "ß", with: "ss")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func parse(_ input: String) -> Double? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "٫", with: ".")
            .replacingOccurrences(of: "．", with: ".")
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "＋", with: "+")
            .map { character in
                character.isNumber && character.unicodeScalars.count == 1 &&
                    character.unicodeScalars.first?.properties.numericType == .decimal
                    ? character.wholeNumberValue.map(String.init) ?? String(character) : String(character)
            }.joined()
        guard value.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
              let number = Double(value), number.isFinite else { return nil }
        return number
    }

    enum InputError: Equatable {
        case field(String, Double, Double, String), invalidA, invalidB, overlap, depth

        func message(_ localization: MSKLocalization) -> String {
            switch self {
            case .field(let id, let low, let high, let unit):
                localization.ui("fieldError", id, localization.number(low), localization.number(high), unit)
            case .invalidA: localization.ui("invalidA")
            case .invalidB: localization.ui("invalidB")
            case .overlap: localization.ui("overlapError")
            case .depth: localization.ui("depthError")
            }
        }
    }

    enum Result: Equatable {
        case incomplete, invalid(InputError), value(Double)
    }

    func calculate(_ input: [String: String]) -> Result {
        var values: [String: Double] = [:]
        for field in fields {
            let raw = input[field.id, default: ""]
            guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            guard let value = Self.parse(raw), (field.minimum...field.maximum).contains(value) else {
                return .invalid(.field(field.id, field.minimum, field.maximum, field.unit))
            }
            values[field.id] = value
        }
        guard values.count == fields.count, let a = values["A"] else { return .incomplete }
        switch formula {
        case .direct: return .value(a)
        case .difference:
            guard let b = values["B"] else { return .incomplete }
            return .value(a - b)
        case .relativeDifference:
            guard let b = values["B"], b > 0 else { return .invalid(.invalidB) }
            return .value((a - b) / b * 100)
        case .ratio, .percent:
            guard let b = values["B"], b > 0 else { return .invalid(.invalidB) }
            if formula == .percent {
                guard a <= b || id == "slip" else { return .invalid(.overlap) }
                return .value(a / b * 100)
            }
            guard a > 0 || id == "bpi" else { return .invalid(.invalidA) }
            return .value(a / b)
        case .depth:
            guard let b = values["B"], let c = values["C"], c <= min(a, b), c > 0 else {
                return .invalid(.depth)
            }
            return .value((a + b) / 2 - c)
        }
    }
}

struct CatalogSection: Identifiable {
    let id: String
    let title: String
    let region: String
    let measurements: [Measurement]

    static func matching(_ catalog: [Measurement], query: String, region: String?, modality: Modality?,
                         localization: MSKLocalization? = nil, ageGroup: AgeGroup = .all) -> [Self] {
        var sections: [Self] = []
        var addedHeight = false
        let available = catalog.filter { $0.isAvailable(region: region, modality: modality, ageGroup: ageGroup) }
        for method in available {
            if method.group == "Patellahöhe" {
                guard !addedHeight else { continue }
                addedHeight = true
                let height = available.filter { $0.group == method.group }
                guard height.contains(where: { $0.matches(query, localization: localization) }) else { continue }
                sections.append(Self(id: "patellar-height", title: method.group, region: region ?? method.region, measurements: height))
            } else if method.matches(query, localization: localization) {
                sections.append(Self(id: method.id, title: method.title, region: region ?? method.region, measurements: [method]))
            }
        }
        return sections
    }
}

struct ViewerSuggestion: Equatable {
    let region: String
    let modality: Modality

    init?(descriptions: [String?], dicomModality: String?) {
        guard let modality = Modality(dicom: dicomModality) else { return nil }
        let normalized = descriptions.compactMap { $0 }.map(Measurement.normalized)
        let combined = normalized.joined(separator: " ")
        let words = Set(combined.split(separator: " "))
        let regions: [(String, Set<Substring>)] = [
            ("Knie", ["knie", "kniegelenk", "kniegelenks", "knee", "patella", "tka", "genou", "rodilla", "joelho", "ginocchio", "diz", "الركبة"]),
            ("OSG", ["osg", "sprunggelenk", "sprunggelenks", "ankle", "cheville", "tobillo", "tornozelo", "caviglia", "الكاحل"]),
            ("Fuß", ["fuss", "mittelfuss", "vorfuss", "foot", "pied", "pie", "pe", "piede", "ayak", "القدم"]),
            ("Hüfte", ["hufte", "huftgelenk", "huftgelenks", "hip", "hips", "hanche", "cadera", "anca", "quadril", "kalca", "الورك"]),
            ("Schulter", ["schulter", "schultergelenk", "schultergelenks", "shoulder", "epaule", "hombro", "ombro", "spalla", "omuz", "الكتف"]),
            ("Ellenbogen", ["ellenbogen", "ellbogen", "elbow", "coude", "codo", "cotovelo", "gomito", "dirsek", "المرفق"]),
            ("Handgelenk", ["handgelenk", "handgelenks", "handwurzel", "wrist", "poignet", "muneca", "punho", "polso", "المعصم"]),
            ("Hand", ["hand", "mittelhand", "finger", "daumen", "thumb", "digits", "main", "mano", "mao", "parmak", "اليد"]),
            ("Rückfuß und USG", ["ruckfuss", "usg", "hindfoot", "subtalar", "saltzman"]),
            ("Unterarm", ["unterarm", "forearm", "antebrazo", "avant", "avambraccio", "onkol"]),
            ("Kopf und kraniozervikaler Übergang", ["kopf", "schadel", "cvj", "craniocervical", "kraniozervikal", "head"]),
            ("HWS", ["hws", "cervical", "zervikal", "cervicale"]),
            ("BWS", ["bws", "thoracic", "thorakal", "dorsal"]),
            ("LWS", ["lws", "lumbar", "lumbal", "lombaire", "lombar"]),
            ("ISG", ["isg", "sij", "sakroiliakal", "sacroiliac", "sacroiliaques"]),
            ("Becken", ["becken", "pelvis", "pelve", "bassin", "bacino"])
        ]
        if modality == .XR && (words.contains(where: { $0.hasPrefix("ganzbein") })
            || combined.contains("long leg") || combined.contains("full length leg") || words.contains("scanogram")) {
            self.region = "Ganzbeinaufnahmen"
        } else if modality != .XR &&
                    (!words.isDisjoint(with: ["rotationsmessung", "torsion", "torsionsmessung", "rotationsprofil"])
                     || (words.contains("rotation") && regions.prefix(4).filter { !words.isDisjoint(with: $0.1) }.count > 1)
                     || combined.contains("rotations ct") || combined.contains("rotations mrt")) &&
                    (regions.prefix(4).contains { !words.isDisjoint(with: $0.1) }
                     || words.contains("bein") || words.contains("beine") || combined.contains("lower limb")) {
            self.region = "Rotationsaufnahmen"
        } else {
            let matches = regions.filter { !words.isDisjoint(with: $0.1) }
            guard matches.count == 1, let match = matches.first else { return nil }
            self.region = match.0
        }
        self.modality = modality
    }
}

enum AnatomyDiagram: String, Decodable, CaseIterable {
    case isi, cdi, bpi, pti, tttg, sulcus, lti, depth, tilt, merchant, extrusion, slope, hka, mpta, mldfa, mad, jlca
    case hindMoment, radBow, radSite, ulnaBow
}
