import SwiftUI
import UIKit

struct ColoringView: View {
    @AppStorage("appLanguage") private var language = "de"
    let template: MandalaTemplate?
    @StateObject private var engine: CanvasEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedColor = PaintColor.palette[0]
    @State private var glitterStyle: GlitterStyle = .none
    @State private var paintOptions = PaintOptions()
    @State private var choosingStartColor = false
    @State private var choosingEndColor = false
    @State private var tool: DrawingTool = .fill
    @State private var thickLines = false
    @State private var confirmReset = false
    @State private var mixing = false

    init(template: MandalaTemplate?) {
        self.template = template
        _engine = StateObject(wrappedValue: CanvasEngine(template: template))
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            VStack(spacing: 14) {
                header
                if landscape {
                    HStack(alignment: .top, spacing: 20) {
                        canvas.frame(maxWidth: .infinity, maxHeight: .infinity)
                        ScrollView { controls }
                            .accessibilityIdentifier("painting-controls")
                            .frame(width: 245)
                    }
                } else {
                    canvas.frame(maxWidth: .infinity, maxHeight: .infinity)
                    ScrollView {
                        HStack(alignment: .top, spacing: 20) {
                            drawingTools.frame(width: 245)
                            colorControls
                        }
                    }
                    .accessibilityIdentifier("painting-controls")
                    .frame(height: 450)
                }
                VStack(spacing: 3) {
                    Text(L.text(engine.hint))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .accessibilityIdentifier("drawing-hint")
                    Text(L.text("Pinch to zoom. Move around with two fingers."))
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .padding(20)
            .background(Theme.cream)
        }
        .onDisappear { engine.save() }
        .onAppear { restoreFinish(for: selectedColor) }
        .onChange(of: glitterStyle) { _, finish in
            UserDefaults.standard.set(Int(finish.rawValue), forKey: finishKey(for: selectedColor))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { engine.save() }
        }
        .confirmationDialog(L.text("Start this page again?"), isPresented: $confirmReset, titleVisibility: .visible) {
            Button(L.text("Clear this drawing"), role: .destructive) { engine.reset() }
            Button(L.text("Keep drawing"), role: .cancel) {}
        } message: {
            Text(L.text("You can bring it back with Undo."))
        }
        .alert(L.text("Drawing needs attention"), isPresented: Binding(
            get: { engine.errorMessage != nil },
            set: { if !$0 { engine.errorMessage = nil } }
        )) {
            Button("OK") { engine.errorMessage = nil }
        } message: {
            Text(engine.errorMessage ?? "")
        }
        .sheet(isPresented: $mixing) {
            ColorMixer { color in
                select(color)
                mixing = false
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            action("Pages", symbol: "chevron.left", id: "pages") {
                engine.save()
                if engine.errorMessage == nil { dismiss() }
            }
            Text(template?.localizedTitle ?? L.text("My own magic"))
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer(minLength: 8)
            action("Undo", symbol: "arrow.uturn.backward", id: "undo") { engine.undo() }
                .disabled(engine.undoCount == 0)
            action("Redo", symbol: "arrow.uturn.forward", id: "redo") { engine.redo() }
                .disabled(engine.redoCount == 0)
            action("Share", symbol: "square.and.arrow.up", id: "share") {
                engine.save()
                ShareSheet.present(engine.image)
            }
            action("Clear", symbol: "arrow.counterclockwise", id: "clear") { confirmReset = true }
            action(language == "de" ? "English" : "Deutsch", symbol: "globe", id: "editor-language") {
                language = language == "de" ? "en" : "de"
            }
        }
    }

    private func action(_ title: String, symbol: String, id: String,
                        perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
        }
        .accessibilityLabel(L.text(title))
        .accessibilityIdentifier(id)
    }

    private var canvas: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            DrawingSurface(engine: engine, tool: tool, color: selectedColor,
                           glitterStyle: glitterStyle, paintOptions: paintOptions,
                           lineWidth: tool == .brush || tool == .eraser ?
                           (thickLines ? 36 : 18) : (thickLines ? 12 : 6))
                .frame(width: side, height: side)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16).stroke(Theme.ink.opacity(0.12), lineWidth: 2)
                        .allowsHitTesting(false)
                }
                .shadow(color: Theme.ink.opacity(0.07), radius: 16, y: 6)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .accessibilityIdentifier("drawing-canvas")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            drawingTools
            colorControls
        }
    }

    private var drawingTools: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text(L.text("Create & color"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(DrawingTool.allCases) { item in
                        Button {
                            tool = item
                            if item == .eraser { engine.hint = "Tap to erase a space. Drag to rub out drawn lines and paint." }
                        } label: {
                            Image(systemName: item.symbol)
                                .font(.system(size: 20, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(tool == item ? .white : Theme.teal)
                                .background(tool == item ? Theme.teal : Color.white,
                                            in: RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel(item.title)
                        .accessibilityAddTraits(tool == item ? .isSelected : [])
                        .accessibilityIdentifier(item == .eraser ? "eraser" : "tool-\(item.rawValue)")
                    }
                    Button { mixing = true } label: {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20, weight: .medium))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(L.text("Mix colors"))
                    .accessibilityIdentifier("mix-colors")
                }
                Toggle(L.text("Thick lines"), isOn: $thickLines)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .accessibilityIdentifier("thick-lines")
                Text(L.text(tool == .eraser ? "Tap to erase a space. Drag to rub out drawn lines and paint." :
                                tool.isPaintTool ? "Tap a closed space to fill it." :
                                tool == .brush ? "Draw freely with your selected color and glitter." :
                                tool == .pencil ? "Drag on the paper to draw a line." :
                                "Drag on the paper to draw a shape."))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
        }
        .foregroundStyle(Theme.ink)
        .padding(4)
    }

    private var colorControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            paintEffects
            HStack {
                Text(L.text("Color box"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Spacer()
                Circle().fill(Color(uiColor: selectedColor.uiColor))
                    .frame(width: 24, height: 24)
                    .overlay { Circle().stroke(Theme.ink.opacity(0.2)) }
            }
            ScrollView(.horizontal) {
                Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                    ForEach(0..<2) { row in
                        GridRow {
                            ForEach(PaintColor.palette.filter { $0.id % 2 == row }) { color in
                                Button {
                                    select(color)
                                } label: {
                                    Circle()
                                        .fill(Color(uiColor: color.uiColor))
                                        .frame(width: 40, height: 40)
                                        .overlay { Circle().stroke(Theme.ink.opacity(0.12), lineWidth: 1) }
                                        .overlay {
                                            if selectedColor.id == color.id {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 17, weight: .bold))
                                                    .foregroundStyle(Int(color.red) + Int(color.green) + Int(color.blue) > 560 ?
                                                                     Theme.ink : .white)
                                            }
                                        }
                                        .padding(3)
                                        .overlay { Circle().stroke(selectedColor.id == color.id ? Theme.ink : .clear, lineWidth: 2) }
                                }
                                .accessibilityLabel(L.text(color.name))
                                .accessibilityAddTraits(selectedColor.id == color.id ? .isSelected : [])
                                .accessibilityIdentifier("color-\(color.id)")
                            }
                        }
                    }
                }
            }
            .frame(height: 100)
            .accessibilityIdentifier("color-palette")
            Text("\(L.text(selectedColor.name))\(glitterStyle != .none ? " + \(glitterStyle.title)" : "")")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.65))
        }
        .foregroundStyle(Theme.ink)
        .padding(4)
    }

    private var paintEffects: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.text("Glitter type"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(GlitterStyle.allCases) { finish in
                    choice(finish.title, selected: glitterStyle == finish, id: "glitter-\(finish.rawValue)") {
                        glitterStyle = finish
                    }
                }
            }
            Text(L.text("Paint style"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(PaintEffect.allCases) { effect in
                    choice(effect.title, selected: paintOptions.effect == effect, id: "effect-\(effect.rawValue)") {
                        paintOptions.effect = effect
                    }
                }
            }
            if paintOptions.effect != .solid {
                HStack {
                    endpoint("From", color: selectedColor, id: "gradient-from") { choosingStartColor = true }
                        .popover(isPresented: $choosingStartColor) {
                            endpointPalette { color in
                                select(color)
                                choosingStartColor = false
                            }
                        }
                    endpoint("To", color: paintOptions.secondColor, id: "gradient-to") { choosingEndColor = true }
                        .popover(isPresented: $choosingEndColor) {
                            endpointPalette { color in
                                paintOptions.secondColor = color
                                choosingEndColor = false
                            }
                        }
                }
                if paintOptions.effect == .gradient {
                    Picker(L.text("Direction"), selection: $paintOptions.direction) {
                        ForEach(GradientDirection.allCases) { direction in
                            Text(direction.title).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("gradient-direction")
                }
            }
        }
    }

    private func choice(_ title: String, selected: Bool, id: String,
                        perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(selected ? .white : Theme.teal)
                .background(selected ? Theme.teal : .white, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    private func endpoint(_ title: String, color: PaintColor, id: String,
                          perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 6) {
                Circle().fill(Color(uiColor: color.uiColor)).frame(width: 22, height: 22)
                    .overlay { Circle().stroke(Theme.ink.opacity(0.2)) }
                Text(L.text(title)).font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(.white, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel("\(L.text(title)): \(L.text(color.name))")
        .accessibilityIdentifier(id)
    }

    private func endpointPalette(select: @escaping (PaintColor) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
            ForEach(PaintColor.palette) { color in
                Button { select(color) } label: {
                    Circle().fill(Color(uiColor: color.uiColor)).frame(width: 42, height: 42)
                        .overlay { Circle().stroke(Theme.ink.opacity(0.2)) }
                }
                .accessibilityLabel(L.text(color.name))
                .accessibilityIdentifier("endpoint-color-\(color.id)")
            }
        }
        .padding(16)
        .frame(width: 290)
    }

    private func finishKey(for color: PaintColor) -> String {
        "paint-finish-\(color.red)-\(color.green)-\(color.blue)"
    }

    private func restoreFinish(for color: PaintColor) {
        let value = UserDefaults.standard.integer(forKey: finishKey(for: color))
        glitterStyle = GlitterStyle.allCases.first { Int($0.rawValue) == value } ?? .none
    }

    private func select(_ color: PaintColor) {
        selectedColor = color
        restoreFinish(for: color)
        if tool != .brush { tool = .fill }
    }
}

struct DrawingSurface: UIViewRepresentable {
    @ObservedObject var engine: CanvasEngine
    let tool: DrawingTool
    let color: PaintColor
    let glitterStyle: GlitterStyle
    let paintOptions: PaintOptions
    let lineWidth: CGFloat

    func makeUIView(context: Context) -> ZoomCanvas {
        ZoomCanvas()
    }

    func updateUIView(_ scrollView: ZoomCanvas, context: Context) {
        let view = scrollView.canvas
        view.engine = engine
        view.tool = tool
        view.color = color
        view.glitterStyle = glitterStyle
        view.paintOptions = paintOptions
        view.lineWidth = lineWidth
        view.accessibilityLabel = L.text("Drawing canvas")
        view.accessibilityHint = L.text("Pinch to zoom. Move around with two fingers.")
        if view.image !== engine.image {
            view.image = engine.image
            view.setNeedsDisplay()
        }
        view.updateSparkles(engine.sparklePoints)
    }
}

final class ZoomCanvas: UIScrollView, UIScrollViewDelegate {
    let canvas = TouchCanvas()
    private var viewport = CGSize.zero
    private var pinchScale: CGFloat = 1
    private var pinchCenter = CGPoint.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        panGestureRecognizer.minimumNumberOfTouches = 2
        pinchGestureRecognizer?.isEnabled = false
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(magnify(_:))))
        isMultipleTouchEnabled = true
        canvas.isMultipleTouchEnabled = true
        accessibilityValue = "100"
        canvas.isAccessibilityElement = true
        canvas.accessibilityLabel = L.text("Drawing canvas")
        canvas.accessibilityHint = L.text("Pinch to zoom. Move around with two fingers.")
        canvas.accessibilityTraits = .image
        addSubview(canvas)
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if viewport != bounds.size {
            viewport = bounds.size
            setZoomScale(1, animated: false)
            canvas.frame = CGRect(origin: .zero, size: bounds.size)
            contentSize = bounds.size
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { canvas }

    @objc private func magnify(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            pinchScale = zoomScale
            pinchCenter = gesture.location(in: canvas)
        }
        if gesture.state == .began || gesture.state == .changed || gesture.state == .ended {
            let scale = min(max(pinchScale * gesture.scale, minimumZoomScale), maximumZoomScale)
            let width = bounds.width / scale, height = bounds.height / scale
            zoom(to: CGRect(x: pinchCenter.x - width / 2, y: pinchCenter.y - height / 2,
                            width: width, height: height), animated: false)
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        accessibilityValue = String(format: "%.0f", zoomScale * 100)
    }
}

final class TouchCanvas: UIView {
    var engine: CanvasEngine?
    var image: UIImage?
    var tool: DrawingTool = .fill
    var color = PaintColor.palette[0]
    var glitterStyle: GlitterStyle = .none
    var paintOptions = PaintOptions()
    var lineWidth: CGFloat = 6
    private var start: CGPoint?
    private var previous: CGPoint?
    private var sparklePoints: [CGPoint] = []
    private let sparkleLayer = CALayer()
    private var sparkleSize = CGSize.zero
    private var erasingStroke = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(sparkleLayer)
        sparkleLayer.masksToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }

    func updateSparkles(_ points: [CGPoint]) {
        guard points != sparklePoints else { return }
        sparklePoints = points
        rebuildSparkles()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard sparkleSize != bounds.size else { return }
        sparkleSize = bounds.size
        sparkleLayer.frame = bounds
        rebuildSparkles()
    }

    private func rebuildSparkles() {
        sparkleLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        for (i, point) in sparklePoints.enumerated() {
            let star = CAShapeLayer()
            let radius = CGFloat(3 + i % 4) * bounds.width / 1000
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: -radius))
            for p in [CGPoint(x: radius * 0.2, y: -radius * 0.2),
                      CGPoint(x: radius, y: 0), CGPoint(x: radius * 0.2, y: radius * 0.2),
                      CGPoint(x: 0, y: radius), CGPoint(x: -radius * 0.2, y: radius * 0.2),
                      CGPoint(x: -radius, y: 0), CGPoint(x: -radius * 0.2, y: -radius * 0.2)] {
                path.addLine(to: p)
            }
            path.close()
            star.path = path.cgPath
            star.shadowPath = path.cgPath
            star.position = CGPoint(x: point.x * bounds.width, y: point.y * bounds.height)
            star.fillColor = UIColor.white.cgColor
            star.shadowColor = UIColor.white.cgColor
            star.shadowRadius = radius
            star.shadowOpacity = 0.9
            star.shadowOffset = .zero
            sparkleLayer.addSublayer(star)
            if !UIAccessibility.isReduceMotionEnabled {
                let twinkle = CABasicAnimation(keyPath: "opacity")
                twinkle.fromValue = 0.05
                twinkle.toValue = 1
                twinkle.duration = 0.6 + Double(i % 11) * 0.12
                twinkle.beginTime = CACurrentMediaTime() + Double(i % 17) * 0.07
                twinkle.autoreverses = true
                twinkle.repeatCount = .infinity
                twinkle.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                star.add(twinkle, forKey: "twinkle")
            }
        }
    }

    override func draw(_ rect: CGRect) {
        image?.draw(in: bounds)
    }

    private func normalized(_ touch: UITouch) -> CGPoint {
        let p = touch.location(in: self)
        return CGPoint(x: min(max(p.x / bounds.width, 0), 0.999),
                       y: min(max(p.y / bounds.height, 0), 0.999))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = normalized(touch)
        start = p
        previous = p
        erasingStroke = false
        if !tool.isPaintTool { engine?.beginStroke() }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start, let previous, tool != .fill else { return }
        if tool == .eraser && !erasingStroke {
            engine?.beginStroke()
            erasingStroke = true
        }
        for sample in event?.coalescedTouches(for: touch) ?? [touch] {
            let p = normalized(sample)
            engine?.draw(from: tool == .pencil || tool == .brush || tool == .eraser ? self.previous ?? previous : start,
                         to: p, tool: tool, width: lineWidth, color: color, glitterStyle: glitterStyle,
                         options: paintOptions, render: false)
            self.previous = p
        }
        engine?.renderStroke()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start else { return }
        let p = normalized(touch)
        if tool == .eraser {
            if erasingStroke {
                engine?.draw(from: previous ?? start, to: p, tool: .eraser, width: lineWidth, render: false)
                engine?.endStroke()
            } else {
                engine?.erase(at: p, width: lineWidth)
            }
        } else if tool == .fill {
            if hypot(p.x - start.x, p.y - start.y) < 0.04 {
                engine?.fill(at: p, color: color, glitterStyle: glitterStyle, options: paintOptions)
            }
        } else {
            engine?.draw(from: tool == .pencil || tool == .brush ? previous ?? start : start,
                         to: p, tool: tool, width: lineWidth, color: color, glitterStyle: glitterStyle,
                         options: paintOptions, render: false)
            engine?.endStroke()
        }
        self.start = nil
        previous = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        engine?.endStroke()
        start = nil
        previous = nil
    }
}

enum ShareSheet {
    static func present(_ image: UIImage) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard var top = scene?.keyWindow?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.maxX - 120, y: 60, width: 1, height: 1)
            popover.permittedArrowDirections = .up
        }
        top.present(controller, animated: true)
    }
}
