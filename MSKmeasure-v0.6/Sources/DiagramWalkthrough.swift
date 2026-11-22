import SwiftUI

struct DiagramWalkthrough: View {
    let atlas: DiagramAtlas
    let scene: DiagramAtlas.Scene
    let method: Measurement
    let profile: Measurement.Profile
    let localization: MSKLocalization

    @State private var step = 3
    @State private var playing = false
    @State private var enlarged = false

    private var stepTitle: String { localization.ui("diagramStep\(step)") }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localization.ui("schematic")).font(.subheadline.weight(.semibold))
                Spacer()
                Button(localization.ui("enlarge"), systemImage: "arrow.up.left.and.arrow.down.right") {
                    playing = false
                    enlarged = true
                }
                .labelStyle(.iconOnly).buttonStyle(.borderless)
                .help(localization.ui("enlarge"))
            }
            contents
        }
        .sheet(isPresented: $enlarged) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(localization.text(method.title)).font(.title2.weight(.semibold))
                    Spacer()
                    Button(localization.ui("close")) { enlarged = false }.help(localization.ui("close"))
                }
                ScrollView { contents }
            }
            .padding(22)
            .frame(minWidth: 700, idealWidth: 820, minHeight: 620, idealHeight: 790)
            .environment(\.layoutDirection, localization.language == .ar ? .rightToLeft : .leftToRight)
            .environment(\.locale, localization.language.locale)
        }
        .task(id: playing) {
            guard playing else { return }
            while !Task.isCancelled && step < 3 {
                do { try await Task.sleep(for: .seconds(2.6)) } catch { return }
                guard !Task.isCancelled else { return }
                step += 1
            }
            playing = false
        }
        .onDisappear { playing = false }
    }

    private var contents: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localization.text(scene.view))
                .font(.caption.weight(.medium)).foregroundStyle(.secondary)
            ZStack {
                SchematicCanvas(atlas: atlas, scene: scene, legacy: method.diagram,
                                localization: localization, step: step)
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(localization.text(method.title) + ". " + stepTitle)
            controls
            Text(stepTitle).font(.subheadline.weight(.semibold))
            switch step {
            case 0:
                Text(localization.text(profile.setup)).font(.subheadline)
            case 1:
                landmarkLegend
            case 2:
                Text(localization.text(method.technique)).font(.subheadline)
            default:
                landmarkLegend
                ForEach(method.fields) { field in
                    Text(localization.text(field.label)).font(.caption)
                }
            }
            if let note = scene.note {
                Text(localization.text(note)).font(.caption).foregroundStyle(.secondary)
            }
            Text(localization.ui("schematicCaption")).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 9) { playbackButtons }
            VStack(alignment: .leading, spacing: 8) { playbackButtons }
        }
    }

    @ViewBuilder private var playbackButtons: some View {
        Button(localization.ui("previous"), systemImage: "chevron.left") {
            playing = false
            step -= 1
        }.disabled(step == 0).help(localization.ui("previousHelp"))
        Button(playing ? localization.ui("pause") : localization.ui("play"),
               systemImage: playing ? "pause.fill" : "play.fill") {
            if playing { playing = false }
            else {
                step = 0
                playing = true
            }
        }
        .help(localization.ui("playHelp"))
        Button(localization.ui("next"), systemImage: "chevron.right") {
            playing = false
            step += 1
        }.disabled(step == 3).help(localization.ui("nextHelp"))
        Text("\(step + 1) / 4").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
    }

    private var landmarkLegend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), alignment: .leading)], alignment: .leading, spacing: 5) {
            ForEach(scene.landmarks) { landmark in
                Text("\(landmark.id) · " + localization.text(landmark.label)).font(.caption)
            }
        }
    }
}

struct SchematicCanvas: View {
    let atlas: DiagramAtlas
    let scene: DiagramAtlas.Scene
    let legacy: AnatomyDiagram?
    let localization: MSKLocalization
    let step: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let legacy {
                MeasurementDiagram(diagram: legacy, localization: localization, step: step)
            }
            layer(phase: 0).opacity(legacy == nil ? 1 : 0)
            layer(phase: 1).opacity(step >= 1 ? 1 : 0)
            if legacy == nil {
                layer(phase: 2).opacity(step >= 2 ? 1 : 0)
                layer(phase: 3).opacity(step >= 3 ? 1 : 0)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: step)
        // Image orientation follows the named projection in every interface language.
        .environment(\.layoutDirection, .leftToRight)
    }

    private func layer(phase: Int) -> some View {
        Canvas { context, size in
            let scale = min(size.width / 240, size.height / 180)
            var drawing = context
            drawing.translateBy(x: (size.width - 240 * scale) / 2, y: (size.height - 180 * scale) / 2)
            drawing.scaleBy(x: scale, y: scale)
            switch phase {
            case 0:
                for shape in atlas.anatomy[scene.template, default: []] {
                    let path = makePath(shape.points, closed: shape.closed)
                    if shape.closed {
                        drawing.fill(path, with: .color(shape.tissue == "cartilage" ? .teal.opacity(0.22) : .secondary.opacity(0.14)))
                    }
                    drawing.stroke(path, with: .color(.secondary.opacity(0.85)), lineWidth: 1.2)
                }
            case 1:
                for landmark in scene.landmarks {
                    let location = point(landmark.point)
                    let circle = Path(ellipseIn: CGRect(x: location.x - 5.3, y: location.y - 5.3, width: 10.6, height: 10.6))
                    drawing.fill(circle, with: .color(.primary))
                    drawing.draw(Text(String(landmark.id)).font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(nsColor: .windowBackgroundColor)), at: location)
                }
            case 2:
                for line in scene.references {
                    drawing.stroke(makePath(line.points), with: .color(.orange),
                                   style: StrokeStyle(lineWidth: 1.8, dash: [4, 3]))
                }
            default:
                for line in scene.measurements {
                    let color: Color = line.label == "B" ? .orange : line.label == "C" ? .pink : .cyan
                    drawing.stroke(makePath(line.points), with: .color(color),
                                   style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    if let label = line.label, let location = line.labelPoint {
                        drawing.draw(Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(Color.primary),
                                     at: point(location))
                    }
                }
            }
        }
    }

    private func point(_ values: [Double]) -> CGPoint { CGPoint(x: values[0], y: values[1]) }

    private func makePath(_ points: [[Double]], closed: Bool = false) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: point(first))
            for location in points.dropFirst() {
                path.addLine(to: point(location))
            }
            if closed { path.closeSubpath() }
        }
    }
}
