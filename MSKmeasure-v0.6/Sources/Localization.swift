import Foundation

enum MSKLanguage: String, CaseIterable, Identifiable {
    case de, en, fr, es, pt, it, tr, ar, zh, ja

    var id: String { rawValue }
    static let preferenceKey = "org.isixmskmessungen.plugin.language"
    static let automatic = "system"

    var title: String {
        switch self {
        case .de: "Deutsch"
        case .en: "English"
        case .fr: "Français"
        case .es: "Español"
        case .pt: "Português"
        case .it: "Italiano"
        case .tr: "Türkçe"
        case .ar: "العربية"
        case .zh: "简体中文"
        case .ja: "日本語"
        }
    }

    var locale: Locale { Locale(identifier: self == .zh ? "zh-Hans" : rawValue) }

    static func resolve(_ preference: String, preferredLanguages: [String] = Locale.preferredLanguages) -> Self {
        if let override = Self(rawValue: preference) { return override }
        for identifier in preferredLanguages {
            let language = Locale.Language(identifier: identifier)
            guard let code = language.languageCode?.identifier, let supported = Self(rawValue: code) else { continue }
            if supported == .zh && language.maximalIdentifier.contains("Hant") { continue }
            return supported
        }
        return .en
    }
}

struct TranslationTable: Decodable {
    let ui: [String: [String: String]]
    let catalog: [String: [String: String]]

    func language(_ language: MSKLanguage) -> MSKLocalization {
        MSKLocalization(language: language, interface: ui[language.rawValue] ?? [:],
                        catalog: catalog[language.rawValue] ?? [:])
    }
}

struct MSKLocalization {
    let language: MSKLanguage
    let interface: [String: String]
    let catalog: [String: String]

    func ui(_ key: String, _ arguments: String...) -> String {
        var text = interface[key] ?? key
        for (index, value) in arguments.enumerated() {
            text = text.replacingOccurrences(of: "{\(index)}", with: value)
        }
        return text
    }

    func text(_ source: String) -> String { catalog[source] ?? source }

    func number(_ value: Double, precision: Int = 2) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...precision)).locale(language.locale))
    }

    func formattedValue(_ value: Double, for method: Measurement, profile: Measurement.Profile) -> String {
        let precision = displayPrecision(value, startingAt: method.resultPrecision, rule: profile.rules)
        let formatted = number(value, precision: precision)
        switch method.resultUnit {
        case "", "°": return formatted + method.resultUnit
        case "%":
            return (value / 100).formatted(.percent.grouping(.never)
                .precision(.fractionLength(0...precision)).locale(language.locale))
        default: return formatted + " " + method.resultUnit
        }
    }

    private func displayPrecision(_ value: Double, startingAt baseline: Int, rule: Measurement.Rule?) -> Int {
        guard let rule else { return baseline }
        let assessment = rule.interpretation(of: value, within: "")
        for precision in baseline...12 {
            let scale = pow(10, Double(precision))
            let rounded = (value * scale).rounded(.toNearestOrEven) / scale
            if rule.interpretation(of: rounded, within: "") == assessment { return precision }
        }
        return 12
    }

    func resultText(method: Measurement, profile: Measurement.Profile, value: Double, age: Int?) -> String {
        let label = profile.referenceLabel(age: age, localization: self)
        let reference = text(profile.reference)
        let referenceSentence = reference.hasSuffix(".") || reference.hasSuffix("。") ? String(reference.dropLast()) : reference
        let assessment = profile.assessment(of: value, age: age, localization: self)
        return ui("report", text(method.title), modalityTitle(profile.modality),
                  formattedValue(value, for: method, profile: profile), label, referenceSentence, assessment)
    }

    func modalityTitle(_ modality: Modality) -> String {
        ui(modality.rawValue)
    }
}
