import AppKit
import IsiXPluginKit
import SwiftUI

@MainActor
public final class MSKmeasure: IsiXPlugin {
    private var window: NSWindow?
    private var observation: IsiXObservation?
    private var session: ViewerSession?
    private var viewerID: IsiXViewerID?

    public init() {}

    public func activate(with context: IsiXPluginContext) throws {
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: "KneeMeasurements", withExtension: "json"),
              let extremityURL = bundle.url(forResource: "ExtremityMeasurements", withExtension: "json"),
              let axialURL = bundle.url(forResource: "AxialMeasurements", withExtension: "json"),
              let diagramURL = bundle.url(forResource: "Schematics", withExtension: "json"),
              let localizationURL = bundle.url(forResource: "Localization", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let decoder = JSONDecoder()
        let catalog = try decoder.decode([Measurement].self, from: Data(contentsOf: url))
            + decoder.decode([Measurement].self, from: Data(contentsOf: extremityURL))
            + decoder.decode([Measurement].self, from: Data(contentsOf: axialURL))
        let translations = try JSONDecoder().decode(TranslationTable.self, from: Data(contentsOf: localizationURL))
        let atlas = try decoder.decode(DiagramAtlas.self, from: Data(contentsOf: diagramURL))
        try atlas.validate(catalog: catalog, translations: translations)
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let preference = UserDefaults.standard.string(forKey: MSKLanguage.preferenceKey) ?? MSKLanguage.automatic
        let strings = translations.language(MSKLanguage.resolve(preference))
        try context.register(IsiXCommand(id: "open-msk-measurements", title: strings.ui("pluginTitle", version),
                                         placement: .other, requirement: .viewer)) {
            [weak self] invocation in
            self?.open(catalog: catalog, translations: translations, atlas: atlas, version: version,
                       context: context, viewer: invocation.viewer)
        }
        observation = try context.observe([.viewerWillClose]) { [weak self] event in
            guard case .viewerWillClose(let id) = event, let self, id == viewerID else { return }
            viewerID = nil
            session = nil
            // A closed source viewer invalidates the case and its manual entries.
            window?.close()
        }
    }

    public func deactivate() {
        observation?.invalidate()
        observation = nil
        window?.close()
        window = nil
        session = nil
        viewerID = nil
    }

    private func open(catalog: [Measurement], translations: TranslationTable, atlas: DiagramAtlas, version: String,
                      context: IsiXPluginContext, viewer: IsiXViewer?) {
        let current = viewer.flatMap { ViewerSession(context: context, viewer: $0) }
        // Reopening the command for the same visible case preserves manual entries.
        if let window, window.isVisible, viewer?.id == viewerID, current == session {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let panel = window ?? NSPanel(contentRect: NSRect(x: 0, y: 0, width: 960, height: 690),
                                    styleMask: [.titled, .closable, .resizable, .utilityWindow],
                                    backing: .buffered, defer: false)
        let suggestion = current?.suggestion.flatMap { match in
            catalog.contains { $0.isAvailable(region: match.region, modality: match.modality) } ? match : nil
        }
        let root = MeasurementBrowser(catalog: catalog, suggestion: suggestion, studyAge: current?.age,
                                      translations: translations, atlas: atlas) { [weak panel] localization in
            panel?.title = localization.ui("pluginTitle", version)
        }
        panel.contentViewController = NSHostingController(rootView: root)
        panel.minSize = NSSize(width: 760, height: 530)
        panel.isReleasedWhenClosed = false
        if window == nil {
            panel.setContentSize(NSSize(width: 960, height: 690))
            panel.center()
        }
        window = panel
        viewerID = viewer?.id
        session = current
        panel.makeKeyAndOrderFront(nil)
    }
}

private struct ViewerSession: Equatable {
    let studyUID: String?
    let suggestion: ViewerSuggestion?
    let age: Int?

    @MainActor
    init?(context: IsiXPluginContext, viewer: IsiXViewer) {
        guard viewer.isOpen else { return nil }
        let series = try? viewer.series()
        let attributes = try? viewer.attributes()
        studyUID = attributes?.studyInstanceUID ?? series?.studyInstanceUID
        let study = studyUID.flatMap { uid in
            try? context.database().study(withInstanceUID: uid)
        }
        suggestion = ViewerSuggestion(descriptions: [study?.studyDescription, series?.seriesDescription],
                                      dicomModality: series?.modality ?? attributes?.modality)
        if let birth = study?.patientBirthDate, let exam = study?.studyDate, birth <= exam {
            let years = Calendar(identifier: .gregorian).dateComponents([.year], from: birth, to: exam).year
            age = years.flatMap { (0...120).contains($0) ? $0 : nil }
        } else {
            age = nil
        }
    }
}
