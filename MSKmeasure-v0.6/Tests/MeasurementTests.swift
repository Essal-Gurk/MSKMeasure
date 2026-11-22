import Foundation

@main
enum MeasurementTests {
    static func main() throws {
        let decoder = JSONDecoder()
        let kneeCatalog = try decoder.decode([Measurement].self,
                                             from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let extremities = try decoder.decode([Measurement].self,
                                             from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3])))
        let axial = try decoder.decode([Measurement].self,
                                        from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[4])))
        let catalog = kneeCatalog + extremities + axial
        precondition(axial.count == 29 && catalog.count == 76)
        let translations = try JSONDecoder().decode(TranslationTable.self,
                                                    from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
        let atlas = try decoder.decode(DiagramAtlas.self,
                                       from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[5])))
        try atlas.validate(catalog: catalog, translations: translations)
        for method in catalog {
            for profile in method.profiles {
                let scene = atlas.scene(for: method, modality: profile.modality)
                precondition(scene != nil && scene!.landmarks.count >= 2)
                for stroke in scene!.measurements {
                    if let label = stroke.label {
                        precondition(method.fields.contains { $0.id == label })
                    }
                }
            }
        }
        let tttgMR = catalog.first { $0.id == "tttg" }!
        precondition(atlas.scene(for: tttgMR, modality: .MR)?.modality == .MR)
        precondition(atlas.scene(for: tttgMR, modality: .CT)?.modality == .CT)
        let german = translations.language(.de)
        precondition(kneeCatalog.count == 15 && extremities.count == 32)
        precondition(Set(catalog.map(\.id)).count == catalog.count)
        precondition(Set(catalog.compactMap(\.diagram)) == Set(AnatomyDiagram.allCases))
        for method in catalog {
            precondition(!method.sources.isEmpty && !method.profiles.isEmpty)
            precondition(Set(method.profiles.map(\.modality)).count == method.profiles.count)
            for profile in method.profiles {
                if let rule = profile.rules, let low = rule.low, let high = rule.high {
                    precondition(low <= high)
                }
            }
        }

        func method(_ id: String) -> Measurement { catalog.first { $0.id == id }! }
        func interpretation(_ id: String, _ modality: Modality, _ value: Double, age: Int? = 30) -> String {
            method(id).profiles.first { $0.modality == modality }!.assessment(of: value, age: age, localization: german)
        }

        precondition(method("isi").calculate(["A": "60,0", "B": "50"]) == .value(1.2))
        precondition(method("cdi").calculate(["A": "40", "B": "40"]) == .value(1))
        precondition(method("bpi").calculate(["A": "0", "B": "40"]) == .value(0))
        precondition(method("pti").calculate(["A": "5", "B": "40"]) == .value(12.5))
        precondition(method("depth").calculate(["A": "22", "B": "24", "C": "20"]) == .value(3))
        precondition(method("merchant").calculate(["A": "−6"]) == .value(-6))
        precondition(method("hka").calculate(["A": "−4.5"]) == .value(-4.5))
        precondition(method("tttg").calculate(["A": "-4"]) == .value(-4))
        precondition(method("isi").calculate(["A":"40"]) == .incomplete)
        for input in ["NaN", "1e4", "inf", "1,2.3", "1 000", "1001"] {
            guard case .invalid = method("isi").calculate(["A": input]) else { fatalError("Invalid input accepted") }
        }
        guard case .invalid = method("isi").calculate(["A": "40", "B": "0"]),
              case .invalid = method("pti").calculate(["A": "41", "B": "40"]),
              case .invalid = method("depth").calculate(["A": "22", "B": "24", "C": "23"]) else {
            fatalError("Invalid geometry accepted")
        }

        precondition(interpretation("isi", .XR, 1.2).contains("Im Bereich"))
        precondition(interpretation("isi", .XR, 1.21).contains("Patella alta"))
        precondition(interpretation("tttg", .CT, 14.9).contains("Unterhalb"))
        precondition(interpretation("tttg", .CT, 15).contains("Grenzbereich"))
        precondition(interpretation("tttg", .CT, 18).contains("Grenzbereich"))
        precondition(interpretation("tttg", .MR, 18).localizedCaseInsensitiveContains("erhöht"))
        precondition(interpretation("tttg", .CT, 20).contains("Grenzbereich"))
        precondition(interpretation("tttg", .CT, 20.01).localizedCaseInsensitiveContains("erhöht"))
        precondition(interpretation("tttg", .MR, 15).contains("Am oder unter"))
        precondition(interpretation("tttg", .MR, 20, age: 15).contains("Pädiatrischer"))
        precondition(interpretation("tttg", .MR, 20, age: nil).contains("Alter"))
        precondition(interpretation("extrusion", .MR, 3).contains("Vermehrte"))
        precondition(interpretation("depth", .MR, 3).contains("Abgeflacht"))
        precondition(interpretation("sulcus", .CT, 160).contains("Deskriptiver"))
        precondition(interpretation("hka", .XR, -4).contains("Varus"))
        precondition(interpretation("hka", .XR, 4).contains("Valgus"))

        let all = CatalogSection.matching(kneeCatalog, query: "Alle Messungen Kniegelenk", region: nil, modality: nil)
        precondition(all.first?.measurements.count == 4 && all.count == 12)
        let xr = CatalogSection.matching(catalog, query: "", region: "Knie", modality: .XR)
        precondition(xr.flatMap(\.measurements).count == 9)
        precondition(!xr.flatMap(\.measurements).contains { $0.id == "tttg" })
        let typo = CatalogSection.matching(catalog, query: "Insel Salvini", region: nil, modality: nil)
        precondition(typo.count == 1 && typo.first?.measurements.count == 4)
        precondition(CatalogSection.matching(catalog, query: "TT-TG", region: nil, modality: nil).map(\.id) == ["tttg"])

        precondition(ViewerSuggestion(descriptions: ["MRT Kniegelenks links", "PD FS sag"], dicomModality: "MR")?.modality == .MR)
        precondition(ViewerSuggestion(descriptions: ["Ganzbeinaufnahme", nil], dicomModality: "DX")?.region == "Ganzbeinaufnahmen")
        precondition(ViewerSuggestion(descriptions: ["Schulter", "PD FS sag"], dicomModality: "MR")?.region == "Schulter")
        precondition(ViewerSuggestion(descriptions: ["Knie"], dicomModality: "US") == nil)
        precondition(ViewerSuggestion(descriptions: ["Rotations-CT Hüfte Knie OSG"], dicomModality: "CT")?.region == "Rotationsaufnahmen")
        precondition(ViewerSuggestion(descriptions: ["MRT Rotationsmessung OSG"], dicomModality: "MR")?.region == "Rotationsaufnahmen")
        precondition(ViewerSuggestion(descriptions: ["MRT Handgelenk"], dicomModality: "MR")?.region == "Handgelenk")
        precondition(ViewerSuggestion(descriptions: ["Röntgen Mittelfuß"], dicomModality: "CR")?.region == "Fuß")
        precondition(ViewerSuggestion(descriptions: ["Knie und OSG"], dicomModality: "MR") == nil)

        let regions = ["Knie", "OSG", "Fuß", "Hüfte", "Schulter", "Ellenbogen", "Handgelenk", "Hand",
                       "Ganzbeinaufnahmen", "Rotationsaufnahmen"]
        precondition(Set(kneeCatalog.map(\.region) + extremities.filter { $0.id != "thumbUCL" }.map(\.region)) == Set(regions))
        precondition(Set(catalog.map(\.region)).count == 18)
        let alignment = CatalogSection.matching(catalog, query: "", region: "Ganzbeinaufnahmen", modality: .XR)
        precondition(Set(alignment.map(\.id)) == ["hka", "mpta", "mldfa", "mad", "jlca", "lld"])
        for modality in [Modality.CT, .MR] {
            let torsion = CatalogSection.matching(catalog, query: "", region: "Rotationsaufnahmen", modality: modality)
            precondition(Set(torsion.map(\.id)) == ["femVersion", "kneeRotation", "tibTorsion"])
        }
        precondition(CatalogSection.matching(catalog, query: "Reikerås", region: "Hüfte", modality: .MR).map(\.id) == ["femVersion"])
        precondition(method("tnu").calculate(["A":"0","B":"40"]) == .value(0))
        precondition(method("tnu").calculate(["A":"15","B":"40"]) == .value(37.5))
        precondition(method("cc").calculate(["A":"15","B":"10"]) == .value(50))
        precondition(method("lld").calculate(["A":"850","B":"862"]) == .value(-12))
        precondition(method("tibTorsion").calculate(["A":"-12"]) == .value(-12))
        precondition(interpretation("mcs", .XR, 5.01).contains("Instabilität"))
        precondition(interpretation("tfcs", .XR, 6).contains("Syndesmoseninsuffizienz"))
        precondition(interpretation("lisfranc", .XR, 2).contains("Innerhalb"))
        precondition(interpretation("lisfranc", .XR, 2.01).contains("Instabilität"))
        precondition(interpretation("meary", .XR, 5).contains("abgeflacht"))
        precondition(interpretation("meary", .XR, -5).contains("vermehrt"))
        precondition(interpretation("alpha", .MR, 60).contains("Cam-Morphologie"))
        precondition(interpretation("alpha", .XR, 59.9).contains("Innerhalb"))
        precondition(Measurement.parse("١٨٫٥") == 18.5)
        precondition(Measurement.parse("１８．５") == 18.5)
        precondition(MSKLanguage.resolve("system", preferredLanguages: ["fr-CA", "de-DE"]) == .fr)
        precondition(MSKLanguage.resolve("system", preferredLanguages: ["zh-CN"]) == .zh)
        precondition(MSKLanguage.resolve("system", preferredLanguages: ["zh-Hant-TW", "ja-JP"]) == .ja)
        precondition(MSKLanguage.resolve("system", preferredLanguages: ["nl-NL"]) == .en)
        precondition(MSKLanguage.resolve("tr", preferredLanguages: ["de-DE"]) == .tr)

        let tttg = method("tttg")
        let mr = tttg.profiles.first { $0.modality == .MR }!
        let ct = tttg.profiles.first { $0.modality == .CT }!
        let uiKeys = Set(german.interface.keys)
        precondition(uiKeys.count >= 40)
        for language in MSKLanguage.allCases {
            let localization = translations.language(language)
            precondition(Set(localization.interface.keys) == uiKeys)
            for measure in catalog {
                let profileStrings = measure.profiles.flatMap { profile in
                    [profile.setup, profile.reference, profile.within, profile.rules?.lowText,
                     profile.rules?.highText, profile.rules?.intermediate, profile.descriptiveAssessment].compactMap { $0 }
                }
                let strings = [measure.title, measure.region, measure.group, measure.technique, measure.meaning]
                    + measure.fields.map(\.label) + measure.sources.map(\.label) + profileStrings
                    + (measure.otherRegions ?? [])
                if language != .de {
                    precondition(strings.allSatisfy { localization.catalog[$0]?.isEmpty == false },
                                 "Missing catalog translation for \(language)")
                }
                precondition(measure.matches(localization.text(measure.title), localization: localization))
            }
            let report = localization.resultText(method: tttg, profile: mr, value: 18.5, age: 35)
            precondition(report.contains(localization.formattedValue(18.5, for: tttg, profile: mr)))
            precondition(report.contains(localization.modalityTitle(.MR)))
            precondition(report.contains(localization.ui("reference")))
            precondition(report.contains(mr.assessment(of: 18.5, age: 35, localization: localization)))
            precondition(!report.contains("{"))
            let pediatric = localization.resultText(method: tttg, profile: mr, value: 18.5, age: 15)
            precondition(pediatric.contains(localization.ui("adultReference")) &&
                         pediatric.contains(localization.ui("pediatric")))
            precondition(localization.resultText(method: tttg, profile: ct, value: 18.5, age: 35)
                .contains(ct.assessment(of: 18.5, age: 35, localization: localization)))
            let baumann = method("baumann")
            let reportBaumann = localization.resultText(method: baumann, profile: baumann.profiles[0], value: 72, age: 8)
            precondition(reportBaumann.contains(localization.ui("pediatricReference")))
            precondition(reportBaumann.contains(localization.text(baumann.meaning)))
            let lld = method("lld")
            let reportLLD = localization.resultText(method: lld, profile: lld.profiles[0], value: -12, age: 30)
            precondition(reportLLD.contains(localization.formattedValue(-12, for: lld, profile: lld.profiles[0])))
            precondition(reportLLD.contains(localization.text(lld.meaning)))
        }
        guard case .value(let radialBow) = method("radBow").calculate(["A":"18","B":"250"]) else { fatalError() }
        precondition(abs(radialBow - 7.2) < 1e-10)
        precondition(method("radSite").calculate(["A":"150","B":"250"]) == .value(60))
        precondition(method("pill").calculate(["A":"55","B":"40"]) == .value(15))
        precondition(method("reimers").calculate(["A":"15","B":"40"]) == .value(37.5))
        precondition(method("slip").calculate(["A":"10","B":"40"]) == .value(25))
        precondition(method("slip").calculate(["A":"50","B":"40"]) == .value(125))
        precondition(interpretation("cobb", .XR, 10, age: 12).contains("Koronare"))
        precondition(!interpretation("cobb", .CT, 10, age: 12).contains("Referenzgrenze"))
        precondition(interpretation("cobb", .XR, 9, age: 12).contains("Innerhalb"))
        precondition(interpretation("sva", .XR, 40, age: 35).contains("Schwelle") ||
                     interpretation("sva", .XR, 40, age: 35).contains("Referenz"))
        precondition(interpretation("padi", .XR, 13, age: 35).contains("verminderter"))
        precondition(ViewerSuggestion(descriptions: ["Rückfuß Saltzman"], dicomModality: "CR")?.region == "Rückfuß und USG")
        precondition(ViewerSuggestion(descriptions: ["Unterarm"], dicomModality: "DX")?.region == "Unterarm")
        precondition(ViewerSuggestion(descriptions: ["MRT LWS"], dicomModality: "MR")?.region == "LWS")
        precondition(ViewerSuggestion(descriptions: ["MRT ISG"], dicomModality: "MR")?.region == "ISG")
        for language in MSKLanguage.allCases {
            let strings = translations.language(language)
            for measure in axial {
                for profile in measure.profiles {
                    let report = strings.resultText(method: measure, profile: profile, value: 12, age: 12)
                    precondition(!report.contains("{") && report.contains(strings.text(measure.title)))
                    if profile.minimumReferenceAge == 0 {
                        precondition(!report.contains(strings.ui("adultReference")))
                    }
                }
            }
        }
        precondition(method("radBow").calculate(["A":"0","B":"200"]) == .value(0))
        guard case .invalid = method("radBow").calculate(["A":"10","B":"0"]) else { fatalError() }
        precondition(method("hindMoment").calculate(["A":"−6"]) == .value(-6))
        precondition(method("mcrae").calculate(["A":"−4"]) == .value(-4))
        precondition(method("ulnaBow").isAvailable(region: nil, modality: .XR, ageGroup: .pediatric))
        precondition(!method("ulnaBow").isAvailable(region: nil, modality: .XR, ageGroup: .adult))
        precondition(!method("pt").isAvailable(region: nil, modality: .XR, ageGroup: .pediatric))
        precondition(method("isi").isAvailable(region: nil, modality: .MR, ageGroup: .pediatric))
        precondition(!method("baumann").isAvailable(region: "Ellenbogen", modality: .XR, ageGroup: .adult))
        let pediatricHip = CatalogSection.matching(catalog, query: "", region: "Hüfte", modality: .XR,
                                                    localization: german, ageGroup: .pediatric)
        precondition(pediatricHip.contains { $0.id == "acetIndex" })
        precondition(pediatricHip.contains { $0.id == "reimers" })
        precondition(!pediatricHip.contains { $0.id == "acea" })
        precondition(interpretation("baumann", .XR, 72, age: 35) == german.ui("outOfAge"))
        precondition(interpretation("adi", .XR, 4, age: 7) == german.ui("pediatric"))
        precondition(interpretation("adi", .XR, 4, age: 35).contains("Instabilität"))
        precondition(interpretation("chamberlain", .CT, 5, age: 35).contains("Innerhalb"))
        precondition(interpretation("chamberlain", .CT, 5.1, age: 35).contains("Invagination"))
        for (description, region) in [
            ("Saltzman Rückfuß", "Rückfuß und USG"), ("Unterarm a.p.", "Unterarm"),
            ("MRT HWS", "HWS"), ("BWS seitlich", "BWS"), ("LWS a.p.", "LWS"),
            ("CT ISG", "ISG"), ("Becken a.p.", "Becken"), ("MRT Kopf", "Kopf und kraniozervikaler Übergang"),
            ("Daumen MRT", "Hand")
        ] {
            precondition(ViewerSuggestion(descriptions: [description], dicomModality: "MR")?.region == region)
        }
        // Exercise every formula and field, not only representative catalog entries.
        for measure in catalog {
            var input: [String: String] = [:]
            for field in measure.fields {
                input[field.id] = String(max(field.minimum, min(field.maximum, field.id == "A" ? 10 : field.id == "B" ? 20 : 5)))
            }
            if measure.id == "lld" { input = ["A": "510", "B": "520"] }
            let expected: Double = switch measure.formula {
            case .direct: 10
            case .ratio: 0.5
            case .percent: 50
            case .depth: 10
            case .difference: -10
            case .relativeDifference: -50
            }
            // Some direct methods have a deliberately narrower valid input range.
            if measure.formula != .direct || measure.fields[0].minimum <= 10 && measure.fields[0].maximum >= 10 {
                precondition(measure.calculate(input) == .value(expected), measure.id)
            }
            for field in measure.fields {
                var invalid = input
                invalid[field.id] = String(field.maximum + 1)
                guard case .invalid = measure.calculate(invalid) else { fatalError(measure.id) }
                invalid[field.id] = String(field.minimum - 1)
                guard case .invalid = measure.calculate(invalid) else { fatalError(measure.id) }
                invalid[field.id] = ""
                precondition(measure.calculate(invalid) == .incomplete, measure.id)
            }
            for profile in measure.profiles {
                if let rule = profile.rules {
                    if let low = rule.low {
                        let at = rule.interpretation(of: low, within: profile.within)
                        precondition(at == (rule.lowerInclusive ? rule.lowText ?? profile.within : rule.intermediate ?? profile.within), measure.id)
                    }
                    if let high = rule.high {
                        let at = rule.interpretation(of: high, within: profile.within)
                        precondition(at == (rule.upperInclusive ? rule.highText ?? profile.within : rule.intermediate ?? profile.within), measure.id)
                    }
                }
            }
        }
        precondition(interpretation("pti", .MR, 10).contains("Verminderter Überlappungsindex"))
        precondition(interpretation("pti", .MR, 60).contains("Vermehrter Überlappungsindex"))
        precondition(interpretation("mcs", .XR, 4.5).contains("Grenzbereich"))
        precondition(interpretation("tonnis", .XR, -1).contains("Überüberdachung"))
        for language in MSKLanguage.allCases {
            let strings = translations.language(language)
            precondition(strings.ui("pluginTitle", "0.6") == "MSKmeasure (v0.6)")
            let help = strings.ui("fieldHelp", "A", "0", "100", "mm", "Technique")
            precondition(!help.contains("{") && !help.contains("%1") && help.contains("Technique"))
            for key in german.interface.keys {
                precondition(strings.interface[key]?.isEmpty == false)
                let sourceTokens = (0...9).map { german.interface[key]!.components(separatedBy: "{\($0)}").count }
                let targetTokens = (0...9).map { strings.interface[key]!.components(separatedBy: "{\($0)}").count }
                precondition(sourceTokens == targetTokens, "Placeholder mismatch: \(language) \(key)")
            }
        }
        print("76 Messmethoden, 18 Regionen, 10 Sprachen · Altersfilter, Berechnungen, Grenzfälle und Ergebnistext geprüft.")
    }
}
