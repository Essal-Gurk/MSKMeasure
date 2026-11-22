import AppKit
import SwiftUI

struct MeasurementBrowser: View {
    let catalog: [Measurement]
    let suggestion: ViewerSuggestion?
    let studyAge: Int?
    let translations: TranslationTable
    let atlas: DiagramAtlas
    let onLanguageChange: (MSKLocalization) -> Void

    @AppStorage(MSKLanguage.preferenceKey) private var languagePreference = MSKLanguage.automatic
    private var localization: MSKLocalization { translations.language(MSKLanguage.resolve(languagePreference)) }

    @State private var query = ""
    @State private var modality: Modality?
    @State private var region: String?
    @State private var ageGroup: AgeGroup = .all
    @State private var selectedID: String? = "patellar-height"
    @State private var showSuggestion = false
    @State private var ageText = ""
    @State private var didAppear = false
    @State private var entries: [String: [Modality: [String: String]]] = [:]

    private var regions: [String] {
        Array(Set(catalog.map(\.region))).sorted {
            localization.text($0).localizedStandardCompare(localization.text($1)) == .orderedAscending
        }
    }

    private var sections: [CatalogSection] {
        CatalogSection.matching(catalog, query: query, region: region, modality: modality, localization: localization, ageGroup: ageGroup)
    }

    private var age: Int? {
        guard let value = Measurement.parse(ageText), (0...120).contains(value), value.rounded() == value else { return nil }
        return Int(value)
    }

    var body: some View {
        VStack(spacing: 0) {
            filters
            Divider()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    sidebar
                    Divider()
                    Text(localization.ui("count", localization.number(Double(sections.reduce(0) { $0 + $1.measurements.count }))))
                        .font(.caption).foregroundStyle(.secondary).padding(12)
                }
                .frame(width: 233)
                .background(.quaternary.opacity(0.35))
                Divider()
                detail
                    .frame(minWidth: 510, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.background)
        .environment(\.locale, localization.language.locale)
        .environment(\.layoutDirection, localization.language == .ar ? .rightToLeft : .leftToRight)
        .onChange(of: localization.language, initial: true) { _, _ in onLanguageChange(localization) }
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            ageText = studyAge.map(String.init) ?? ""
            showSuggestion = suggestion != nil
        }
        .onChange(of: sections.map(\.id)) { _, ids in
            if !ids.contains(selectedID ?? "") { selectedID = ids.first }
        }
        .alert(localization.ui("suggestionTitle"), isPresented: $showSuggestion, presenting: suggestion) { match in
            Button(localization.ui("showMatch", localization.text(match.region), localization.modalityTitle(match.modality))) {
                region = match.region
                modality = match.modality
            }.help(localization.ui("modalityHelp"))
            Button(localization.ui("allMethods"), role: .cancel) {}.help(localization.ui("allMethods"))
        } message: { match in
            Text(localization.ui("suggestionBody", localization.text(match.region), localization.modalityTitle(match.modality)))
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 15) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(localization.ui("search"), text: $query)
                        .textFieldStyle(.plain)
                        .accessibilityLabel(localization.ui("search"))
                        .help(localization.ui("searchHelp"))
                    if !query.isEmpty {
                        Button(localization.ui("clearSearch"), systemImage: "xmark.circle.fill") { query = "" }
                            .labelStyle(.iconOnly).buttonStyle(.borderless).help(localization.ui("clearSearch"))
                    }
                }
                .padding(8)
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 7))
                Picker(localization.ui("language"), selection: $languagePreference) {
                    Text(localization.ui("systemLanguage")).tag(MSKLanguage.automatic)
                    ForEach(MSKLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue).help(localization.ui("languageHelp"))
                    }
                }.fixedSize().help(localization.ui("languageHelp"))
            }
            HStack(spacing: 15) {
                Picker(localization.ui("region"), selection: $region) {
                    Text(localization.ui("all")).tag(nil as String?)
                    ForEach(regions, id: \.self) { item in
                        Text(localization.text(item)).tag(Optional(item)).help(localization.text(item))
                    }
                }.fixedSize().help(localization.ui("regionHelp"))
                Picker(localization.ui("modality"), selection: $modality) {
                    Text(localization.ui("all")).tag(nil as Modality?)
                    ForEach(Modality.allCases) { item in
                        Text(localization.modalityTitle(item)).tag(Optional(item)).help(localization.ui("modalityHelp"))
                    }
                }.fixedSize().help(localization.ui("modalityHelp"))
            }
            HStack(spacing: 15) {
                Picker(localization.ui("ageFilter"), selection: $ageGroup) {
                    ForEach(AgeGroup.allCases) { group in
                        Text(localization.ui(group.titleKey)).tag(group).help(localization.ui("ageFilterHelp"))
                    }
                }.fixedSize().help(localization.ui("ageFilterHelp"))
                HStack(spacing: 6) {
                    Text(localization.ui("age"))
                    TextField(localization.ui("years"), text: $ageText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 51)
                        .accessibilityLabel(localization.ui("ageLabel"))
                        .help(localization.ui("ageHelp"))
                }
            }
        }
        .padding(13)
        .background(.bar)
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                let grouped = Dictionary(grouping: sections, by: \.region)
                let regionOrder = NSOrderedSet(array: sections.map(\.region)).array.compactMap { $0 as? String }
                ForEach(regionOrder, id: \.self) { item in
                    Text(localization.text(item))
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        .padding(.horizontal, 9).padding(.top, 5)
                    ForEach(grouped[item, default: []]) { section in
                        sectionButton(section)
                    }
                }
            }
            .padding(9)
        }
    }

    private func sectionButton(_ section: CatalogSection) -> some View {
        let selected = section.id == selectedID
        return Button {
            selectedID = section.id
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(localization.text(section.title)).font(.subheadline.weight(selected ? .semibold : .medium))
                Text(modalityLabel(for: section)).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(selected ? Color.accentColor.opacity(0.17) : .clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(section.measurements.map { localization.text($0.technique) }.joined(separator: "\n"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var detail: some View {
        Group {
            if let section = sections.first(where: { $0.id == selectedID }) ?? sections.first {
                SectionDetail(section: section, selectedModality: modality, age: age, localization: localization, atlas: atlas, entries: $entries)
                    .id(section.id)
            } else {
                ContentUnavailableView(localization.ui("noMethods"), systemImage: "magnifyingglass",
                                       description: Text(localization.ui("noMethodsHelp")))
            }
        }
    }

    private func modalityLabel(for section: CatalogSection) -> String {
        let available = Set(section.measurements.flatMap { $0.profiles.map(\.modality) })
        return Modality.allCases.filter { available.contains($0) && (modality == nil || $0 == modality) }
            .map(localization.modalityTitle).joined(separator: " · ")
    }
}

private struct SectionDetail: View {
    let section: CatalogSection
    let selectedModality: Modality?
    let age: Int?
    let localization: MSKLocalization
    let atlas: DiagramAtlas
    @Binding var entries: [String: [Modality: [String: String]]]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                if section.id == "patellar-height" {
                    Text(localization.text(section.title)).font(.title.bold())
                }
                ForEach(section.measurements) { method in
                    MeasurementCard(method: method, age: age, initialModality: selectedModality,
                                    localization: localization, atlas: atlas,
                                    entries: Binding(get: { entries[method.id, default: [:]] },
                                                     set: { entries[method.id] = $0 }))
                }
            }
            .padding(20)
        }
    }
}

private struct MeasurementCard: View {
    let method: Measurement
    let age: Int?
    let initialModality: Modality?
    let localization: MSKLocalization
    let atlas: DiagramAtlas
    @State private var chosenModality: Modality?
    @State private var copiedText: String?
    @Binding var entries: [Modality: [String: String]]

    private var numbers: [String: String] { entries[profile.modality, default: [:]] }

    private var profile: Measurement.Profile {
        let preferred = initialModality ?? chosenModality
        return method.profiles.first { $0.modality == preferred } ?? method.profiles[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text(localization.text(method.title)).font(.title3.weight(.semibold))
                Spacer()
                if initialModality == nil && method.profiles.count > 1 {
                    Picker(localization.ui("measurementModality"), selection: Binding(get: { profile.modality }, set: { chosenModality = $0 })) {
                        ForEach(method.profiles) { item in Text(localization.modalityTitle(item.modality)).tag(item.modality) }
                    }.labelsHidden().fixedSize().accessibilityLabel(localization.ui("measurementModality")).help(localization.ui("modalityHelp"))
                } else {
                    Text(localization.modalityTitle(profile.modality)).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if let scene = atlas.scene(for: method, modality: profile.modality) {
                DiagramWalkthrough(atlas: atlas, scene: scene, method: method, profile: profile,
                                   localization: localization)
                    .id(method.id + profile.modality.rawValue)
            }
            Text(localization.text(profile.setup)).font(.subheadline.weight(.medium))
            Text(localization.text(method.technique)).font(.subheadline).foregroundStyle(.secondary)
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                ForEach(method.fields) { field in
                    GridRow {
                        Text(localization.text(field.label)).font(.subheadline)
                        TextField(localization.ui("value"), text: Binding(get: { numbers[field.id, default: ""] },
                                                      set: { entries[profile.modality, default: [:]][field.id] = $0 }))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 76)
                            .accessibilityLabel(localization.text(field.label))
                            .help(localization.ui("fieldHelp", localization.text(field.label), localization.number(field.minimum), localization.number(field.maximum), field.unit, localization.text(method.technique)))
                        Text(field.unit).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            result
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { sourceLinks }
                VStack(alignment: .leading, spacing: 6) { sourceLinks }
            }
            .font(.caption)
        }
        .padding(15)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.quaternary, lineWidth: 1))
    }

    private var sourceLinks: some View {
        ForEach(method.sources) { link in Link(localization.text(link.label), destination: link.url).help(localization.text(link.label) + " · " + link.url.absoluteString) }
    }

    private var reference: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profile.referenceLabel(age: age, localization: localization))
                .font(.caption.weight(.semibold))
            Text(localization.text(profile.reference)).font(.subheadline)
        }
    }

    private var result: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch method.calculate(numbers) {
            case .incomplete:
                reference
                Text(localization.ui("enterValues")).font(.subheadline).foregroundStyle(.secondary)
            case .invalid(let error):
                reference
                Label(error.message(localization), systemImage: "exclamationmark.circle").font(.subheadline).foregroundStyle(.red)
            case .value(let value):
                let report = localization.resultText(method: method, profile: profile, value: value, age: age)
                Text(localization.formattedValue(value, for: method, profile: profile))
                    .font(.title2.monospacedDigit().weight(.semibold))
                Text(report)
                    .font(.subheadline.weight(.medium))
                    .textSelection(.enabled)
                Button(copiedText == report ? localization.ui("copied") : localization.ui("copy"),
                       systemImage: copiedText == report ? "checkmark" : "doc.on.doc") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    copiedText = pasteboard.setString(report, forType: .string) ? report : nil
                }
                .help(localization.ui("copyHelp"))
                .onChange(of: report) { _, _ in copiedText = nil }
                let meaning = localization.text(method.meaning)
                if !report.contains(meaning) {
                    Text(meaning).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 7))
    }
}
