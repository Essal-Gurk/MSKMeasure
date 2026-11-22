import SwiftUI

// Coordinate pairs use a 240 × 180 drawing area.
struct MeasurementDiagram: View {
    let diagram: AnatomyDiagram
    let localization: MSKLocalization
    var step: Int = 3

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 240, size.height / 180)
            var drawing = context
            drawing.translateBy(x: (size.width - 240 * scale) / 2, y: (size.height - 180 * scale) / 2)
            drawing.scaleBy(x: scale, y: scale)
            switch diagram {
            case .isi, .cdi, .bpi, .pti: drawHeight(drawing)
            case .tttg, .sulcus, .lti, .depth, .tilt, .merchant: drawAxial(drawing)
            case .extrusion: drawExtrusion(drawing)
            case .slope: drawSlope(drawing)
            case .hka, .mpta, .mldfa, .mad, .jlca: drawAxis(drawing)
            case .hindMoment: drawHindfoot(drawing)
            case .radBow, .radSite: drawRadialBow(drawing)
            case .ulnaBow: drawUlnarBow(drawing)
            }
        }
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(localization.ui("diagramLabel"))
    }

    private typealias Point = (CGFloat, CGFloat)
    private let lineA = Color.cyan
    private let lineB = Color.orange
    private let lineC = Color.pink

    private func drawHindfoot(_ ctx: GraphicsContext) {
        bone(ctx, [(105,15),(126,15),(127,75),(133,90),(129,100),(101,100),(98,90),(104,75)])
        bone(ctx, [(107,105),(130,103),(143,118),(157,143),(155,157),(140,161),(125,146),(114,125)])
        line(ctx, [(116,15),(116,166)], color: lineB, dashed: true)
        line(ctx, [(68,161),(188,161)], color: .secondary)
        segment(ctx, (116,161), (148,161), label: "A", at: (131,145), color: lineA)
    }

    private func drawRadialBow(_ ctx: GraphicsContext) {
        let proximal: Point = (145,30)
        let distal: Point = (145,153)
        let bow: Point = (87,104)
        let foot: Point = (145,104)
        bone(ctx, [(129,20),(145,17),(153,26),(145,30),(129,48),(114,68),
                   (100,88),(87,104),(103,127),(123,145),(145,153),(153,165),
                   (126,164),(108,150),(87,129),(73,106),(87,83),(102,61),(119,39)])
        line(ctx, [proximal,distal], color: lineB)
        if diagram == .radBow {
            segment(ctx, bow, foot, label: "A", at: (116,93), color: lineA)
        } else {
            line(ctx, [bow,foot], color: .secondary, dashed: true)
            segment(ctx, proximal, foot, label: "A", at: (159,65), color: lineA)
        }
        segment(ctx, (179,30), (179,153), label: "B", at: (195,95), color: lineB)
        line(ctx, [proximal,(185,30)], color: .secondary, dashed: true)
        line(ctx, [distal,(185,153)], color: .secondary, dashed: true)
    }

    private func drawUlnarBow(_ ctx: GraphicsContext) {
        bone(ctx, [(129,20),(145,15),(149,25),(133,35),(119,54),(107,88),
                   (113,114),(126,145),(139,155),(134,166),(121,161),
                   (110,137),(97,109),(94,88),(102,59),(115,35)])
        line(ctx, [(129,20),(129,158)], color: lineB)
        segment(ctx, (129,88), (94,88), label: "A", at: (111,73), color: lineA)
    }

    private func point(_ xy: Point) -> CGPoint { CGPoint(x: xy.0, y: xy.1) }

    private func path(_ points: [Point], closed: Bool = false) -> Path {
        Path { shape in
            guard let first = points.first else { return }
            shape.move(to: point(first))
            for xy in points.dropFirst() { shape.addLine(to: point(xy)) }
            if closed { shape.closeSubpath() }
        }
    }

    private func bone(_ ctx: GraphicsContext, _ points: [Point]) {
        let shape = path(points, closed: true)
        ctx.fill(shape, with: .color(.secondary.opacity(0.20)))
        ctx.stroke(shape, with: .color(.secondary.opacity(0.85)), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
    }

    private func line(_ ctx: GraphicsContext, _ points: [Point], color: Color, dashed: Bool = false) {
        let measurement = color == lineA || color == lineB || color == lineC
        guard step >= (measurement ? 3 : 2) else { return }
        ctx.stroke(path(points), with: .color(color),
                   style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round, dash: dashed ? [6, 4] : []))
    }

    private func text(_ ctx: GraphicsContext, _ label: String, _ location: Point) {
        guard step >= 3 || !["A", "B", "C", "5 cm", "15 cm"].contains(label) else { return }
        ctx.draw(Text(label).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.primary), at: point(location))
    }

    private func segment(_ ctx: GraphicsContext, _ start: Point, _ end: Point, label: String, at location: Point, color: Color) {
        guard step >= 3 else { return }
        line(ctx, [start, end], color: color)
        for endPoint in [start, end] {
            ctx.fill(Path(ellipseIn: CGRect(x: endPoint.0 - 3, y: endPoint.1 - 3, width: 6, height: 6)), with: .color(color))
        }
        text(ctx, label, location)
    }

    private func arc(_ ctx: GraphicsContext, center: Point, radius: CGFloat, start: Double, end: Double) {
        let points = (0...20).map { index -> Point in
            let radians = (start + (end - start) * Double(index) / 20) * .pi / 180
            return (center.0 + radius * cos(radians), center.1 + radius * sin(radians))
        }
        line(ctx, points, color: lineB)
    }

    private func drawHeight(_ ctx: GraphicsContext) {
        bone(ctx, [(130,14),(163,14),(162,42),(176,61),(187,81),(181,98),(168,106),
                   (147,109),(125,101),(115,88),(111,68),(118,49)])
        bone(ctx, [(113,122),(181,122),(184,138),(167,150),(158,166),(100,166),(92,154),(99,144),(106,141)])
        bone(ctx, [(72,40),(83,42),(88,50),(84,65),(76,82),(65,95),(59,89),(58,74),(63,52)])
        line(ctx, [(65,95),(99,144)], color: .secondary, dashed: true)
        switch diagram {
        case .isi:
            segment(ctx, (65,95), (99,144), label: "A", at: (66,126), color: lineA)
            segment(ctx, (75,41), (65,95), label: "B", at: (51,62), color: lineB)
        case .cdi:
            segment(ctx, (74,85), (113,122), label: "A", at: (81,111), color: lineA)
            segment(ctx, (74,85), (88,50), label: "B", at: (98,68), color: lineB)
        case .bpi:
            line(ctx, [(55,122),(185,122)], color: .secondary, dashed: true)
            segment(ctx, (74,85), (74,122), label: "A", at: (59,107), color: lineA)
            segment(ctx, (74,85), (88,50), label: "B", at: (100,69), color: lineB)
        case .pti:
            line(ctx, [(118,49),(111,68),(115,88)], color: .secondary)
            segment(ctx, (79,74), (74,85), label: "A", at: (63,80), color: lineA)
            segment(ctx, (93,51), (79,86), label: "B", at: (102,63), color: lineB)
            line(ctx, [(79,74),(112,74)], color: .secondary, dashed: true)
            line(ctx, [(74,85),(115,85)], color: .secondary, dashed: true)
        default: break
        }
        text(ctx, localization.ui("ventral"), (38,158))
    }

    private func drawAxial(_ ctx: GraphicsContext) {
        let axialBone: [Point] = diagram == .lti ?
            [(48,73),(76,88),(113,94),(149,87),(193,77),(204,100),(204,127),(192,146),(169,153),
             (149,150),(124,136),(96,149),(73,152),(52,143),(39,124),(38,95)] :
            [(48,73),(75,83),(113,105),(149,81),(193,61),(204,92),(204,125),(192,145),(169,153),
             (149,150),(124,136),(96,149),(73,152),(52,143),(39,124),(38,95)]
        bone(ctx, axialBone)
        if diagram != .sulcus && diagram != .merchant {
            line(ctx, [(25,153),(215,153)], color: .secondary, dashed: true)
        }
        switch diagram {
        case .tttg:
            let tuberosity: Point = (162,43)
            line(ctx, [(129,51),(148,48),tuberosity,(179,51),(198,54)], color: .secondary, dashed: true)
            line(ctx, [(113,43),(113,160)], color: lineB, dashed: true)
            line(ctx, [tuberosity,(162,160)], color: lineB, dashed: true)
            segment(ctx, (113,119), (162,119), label: "A", at: (138,106), color: lineA)
        case .sulcus:
            line(ctx, [(48,73),(113,105),(193,61)], color: lineA)
            arc(ctx, center: (113,105), radius: 25, start: 206, end: 331)
            text(ctx, "A", (113,66))
        case .lti:
            line(ctx, [(113,96),(199,77)], color: lineA)
            line(ctx, [(113,96),(201,96)], color: .secondary, dashed: true)
            arc(ctx, center: (113,96), radius: 73, start: 348, end: 360)
            text(ctx, "A", (202,87))
        case .depth:
            segment(ctx, (48,73), (48,153), label: "A", at: (31,112), color: lineA)
            segment(ctx, (193,61), (193,153), label: "B", at: (211,104), color: lineB)
            segment(ctx, (113,105), (113,153), label: "C", at: (126,130), color: lineC)
        case .tilt:
            bone(ctx, [(82,34),(105,20),(141,22),(177,51),(147,54),(123,62),(105,55)])
            line(ctx, [(82,34),(177,51)], color: lineA)
            line(ctx, [(82,34),(200,34)], color: .secondary, dashed: true)
            arc(ctx, center: (82,34), radius: 91, start: 0, end: 10)
            text(ctx, "A", (196,52))
        case .merchant:
            bone(ctx, [(97,35),(123,21),(155,23),(182,40),(158,41),(144,62),(125,50)])
            line(ctx, [(48,73),(113,105),(193,61)], color: .secondary)
            line(ctx, [(113,105),(111,37)], color: lineB, dashed: true)
            line(ctx, [(113,105),(144,62)], color: lineA)
            arc(ctx, center: (113,105), radius: 31, start: 268, end: 306)
            text(ctx, "A", (132,70))
        default: break
        }
        text(ctx, localization.ui("medial"), (44,165))
        text(ctx, localization.ui("lateral"), (197,165))
    }

    private func drawExtrusion(_ ctx: GraphicsContext) {
        bone(ctx, [(74,20),(170,19),(185,35),(182,67),(165,82),(137,84),(114,77),(87,70),(72,55)])
        bone(ctx, [(84,99),(191,99),(201,114),(182,158),(105,158),(90,133)])
        let meniscus = path([(58,78),(70,77),(101,91),(61,95)], closed: true)
        ctx.fill(meniscus, with: .color(.secondary.opacity(0.8)))
        line(ctx, [(58,76),(58,121)], color: .secondary, dashed: true)
        line(ctx, [(84,99),(84,121)], color: .secondary, dashed: true)
        segment(ctx, (58,115), (84,115), label: "A", at: (71,131), color: lineA)
        text(ctx, localization.ui("medial"), (39,150))
    }

    private func drawSlope(_ ctx: GraphicsContext) {
        bone(ctx, [(76,41),(167,55),(162,71),(147,92),(143,165),(106,165),(102,98),(94,78),(72,58)])
        line(ctx, [(125,64),(125,167)], color: .secondary, dashed: true)
        line(ctx, [(68,45),(199,45)], color: .secondary, dashed: true)
        line(ctx, [(75,42),(192,60)], color: lineA)
        arc(ctx, center: (95,45), radius: 70, start: 0, end: 9)
        text(ctx, "A", (186,37))
        for y: CGFloat in [107,151] {
            ctx.fill(Path(ellipseIn: CGRect(x: 121, y: y - 4, width: 8, height: 8)), with: .color(lineB))
        }
        text(ctx, "5 cm", (174,107))
        text(ctx, "15 cm", (174,151))
        text(ctx, localization.ui("ventral"), (39,56))
    }

    private func drawAxis(_ ctx: GraphicsContext) {
        let hip: Point = (104,22)
        let knee: Point = (122,91)
        let tibia: Point = (122,97)
        let ankle: Point = (130,156)
        bone(ctx, [(96,15),(110,13),(129,24),(126,39),(123,68),(139,83),(138,90),
                   (109,92),(105,86),(114,69),(116,35),(102,30),(93,25)])
        bone(ctx, [(103,97),(143,95),(144,104),(136,116),(138,153),(144,158),(142,162),
                   (119,164),(115,159),(124,150),(120,116),(111,108)])
        switch diagram {
        case .hka:
            line(ctx, [hip,knee], color: lineA)
            line(ctx, [knee,(144,174)], color: .secondary, dashed: true)
            line(ctx, [tibia,ankle], color: lineB)
            arc(ctx, center: knee, radius: 54, start: 75, end: 82)
            text(ctx, "A", (151,145))
        case .mpta:
            line(ctx, [(82,99),(158,94)], color: lineA)
            line(ctx, [tibia,ankle], color: lineA)
            arc(ctx, center: tibia, radius: 26, start: 83, end: 177)
            text(ctx, "A", (99,130))
        case .mldfa:
            line(ctx, [(83,94),(158,88)], color: lineA)
            line(ctx, [hip,knee], color: lineA)
            arc(ctx, center: knee, radius: 26, start: 255, end: 356)
            text(ctx, "A", (148,65))
        case .mad:
            let center: Point = (129,94)
            let dx = ankle.0 - hip.0
            let dy = ankle.1 - hip.1
            let offset = ((center.0 - hip.0) * dx + (center.1 - hip.1) * dy) / (dx * dx + dy * dy)
            let foot: Point = (hip.0 + dx * offset, hip.1 + dy * offset)
            line(ctx, [hip,ankle], color: lineB)
            segment(ctx, foot, center, label: "A", at: (143,111), color: lineA)
        case .jlca:
            line(ctx, [(64,95.5),(160,87.5)], color: lineA)
            line(ctx, [(64,95.5),(160,103.5)], color: lineB)
            arc(ctx, center: (64,95.5), radius: 81, start: -4.76, end: 4.76)
            text(ctx, "A", (166,95.5))
        default: break
        }
        text(ctx, localization.ui("medial"), (41,143))
        text(ctx, localization.ui("lateral"), (199,143))
    }
}
