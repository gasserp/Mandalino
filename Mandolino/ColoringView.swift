import SwiftUI
import UIKit

struct ColoringView: View {
    @AppStorage("appLanguage") private var language = "de"
    let template: MandalaTemplate?
    @StateObject private var engine: CanvasEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedColor = PaintColor.palette[0]
    @State private var glitter = false
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
                        ScrollView { controls }.frame(width: 245)
                    }
                } else {
                    canvas.frame(maxWidth: .infinity, maxHeight: .infinity)
                    ScrollView {
                        if template == nil {
                            HStack(alignment: .top, spacing: 20) {
                                drawingTools.frame(width: 245)
                                colorControls
                            }
                        } else {
                            colorControls
                        }
                    }
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
                selectedColor = color
                tool = .fill
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
                           glitter: glitter, lineWidth: thickLines ? 12 : 6)
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
            if template == nil { drawingTools }
            colorControls
        }
    }

    private var drawingTools: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text(L.text("Create & color"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                HStack(spacing: 6) {
                    ForEach(DrawingTool.allCases.filter { $0 != .eraser }) { item in
                        Button { tool = item } label: {
                            Image(systemName: item.symbol)
                                .font(.system(size: 20, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(tool == item ? .white : Theme.teal)
                                .background(tool == item ? Theme.teal : Color.white,
                                            in: RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel(item.title)
                        .accessibilityIdentifier("tool-\(item.rawValue)")
                    }
                }
                Toggle(L.text("Thick lines"), isOn: $thickLines)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .accessibilityIdentifier("thick-lines")
                Text(L.text(tool.isPaintTool ? "Tap a closed space to fill it." :
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
            HStack {
                Text(L.text("Color box"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Spacer()
                Circle().fill(Color(uiColor: selectedColor.uiColor))
                    .frame(width: 24, height: 24)
                    .overlay { Circle().stroke(Theme.ink.opacity(0.2)) }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                ForEach(PaintColor.palette) { color in
                    Button {
                        selectedColor = color
                        tool = .fill
                    } label: {
                        Circle()
                            .fill(Color(uiColor: color.uiColor))
                            .frame(height: 40)
                            .overlay { Circle().stroke(Theme.ink.opacity(0.12), lineWidth: 1) }
                            .overlay {
                                if selectedColor.id == color.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(color.id == 19 || color.id == 4 ? Theme.ink : .white)
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
            HStack(spacing: 10) {
                Button {
                    tool = tool == .eraser ? .fill : .eraser
                    if tool == .eraser { engine.hint = "Tap a colored space to erase its color." }
                } label: {
                    Label(L.text("Eraser"), systemImage: "eraser.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(tool == .eraser ? .white : Theme.teal)
                        .background(tool == .eraser ? Theme.teal : .white,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("eraser")
                Button { mixing = true } label: {
                    Label(L.text("Mix colors"), systemImage: "paintpalette.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("mix-colors")
            }
            Toggle(isOn: $glitter) {
                Label(L.text("Sparkle"), systemImage: "sparkles")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .padding(14)
            .background(Theme.peach.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("sparkle")
            Text("\(L.text(selectedColor.name))\(glitter ? " + \(L.text("Glitter"))" : "")")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.65))
        }
        .foregroundStyle(Theme.ink)
        .padding(4)
    }
}

struct DrawingSurface: UIViewRepresentable {
    @ObservedObject var engine: CanvasEngine
    let tool: DrawingTool
    let color: PaintColor
    let glitter: Bool
    let lineWidth: CGFloat

    func makeUIView(context: Context) -> ZoomCanvas {
        ZoomCanvas()
    }

    func updateUIView(_ scrollView: ZoomCanvas, context: Context) {
        let view = scrollView.canvas
        view.engine = engine
        view.tool = tool
        view.color = color
        view.glitter = glitter
        view.lineWidth = lineWidth
        view.accessibilityLabel = L.text("Drawing canvas")
        view.accessibilityHint = L.text("Pinch to zoom. Move around with two fingers.")
        view.image = engine.image
        view.updateSparkles(engine.sparklePoints)
        view.setNeedsDisplay()
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
    var glitter = false
    var lineWidth: CGFloat = 6
    private var start: CGPoint?
    private var previous: CGPoint?
    private var sparklePoints: [CGPoint] = []
    private let sparkleLayer = CALayer()

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
        if !tool.isPaintTool { engine?.beginStroke() }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start, let previous, !tool.isPaintTool else { return }
        for sample in event?.coalescedTouches(for: touch) ?? [touch] {
            let p = normalized(sample)
            engine?.draw(from: tool == .pencil ? self.previous ?? previous : start,
                         to: p, tool: tool, width: lineWidth)
            self.previous = p
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start else { return }
        let p = normalized(touch)
        if tool.isPaintTool {
            if hypot(p.x - start.x, p.y - start.y) < 0.04 {
                engine?.fill(at: p, color: tool == .eraser ? PaintColor.palette[19] : color,
                             glitter: tool == .eraser ? false : glitter)
            }
        } else {
            engine?.draw(from: tool == .pencil ? previous ?? start : start,
                         to: p, tool: tool, width: lineWidth)
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
