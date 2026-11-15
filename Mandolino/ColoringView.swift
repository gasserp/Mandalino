import SwiftUI
import UIKit

enum BrushSize: CaseIterable, Identifiable {
    case small, medium, large
    var id: Self { self }

    var title: String {
        switch self {
        case .small: return L.text("Small")
        case .medium: return L.text("Medium")
        case .large: return L.text("Large")
        }
    }

    var dot: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 14
        case .large: return 22
        }
    }

    func width(for tool: DrawingTool) -> CGFloat {
        let painting = tool == .brush || tool == .eraser
        switch self {
        case .small: return painting ? 10 : 4
        case .medium: return painting ? 18 : 6
        case .large: return painting ? 36 : 12
        }
    }
}

struct ColoringView: View {
    @AppStorage("appLanguage") private var language = "de"
    @AppStorage("glitterStyle") private var glitterRaw = 0
    @AppStorage("myColors") private var myColorsRaw = ""
    @State private var celebrating = false
    @State private var pending = PendingPaint()
    let template: MandalaTemplate?
    @StateObject private var engine: CanvasEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedColor = PaintColor.palette[1]
    @State private var paintOptions = PaintOptions()
    @State private var tool: DrawingTool = .fill
    @State private var lineTool: DrawingTool = .pencil
    @State private var brushSize: BrushSize = .medium
    @State private var showingMagic = false
    @State private var choosingLines = false
    @State private var symmetry = 0
    @State private var choosingMirror = false
    @State private var choosingAllColors = false
    @State private var choosingStartColor = false
    @State private var choosingEndColor = false
    @State private var showingMore = false
    @State private var confirmingClear = false
    @State private var confirmingDelete = false
    @State private var mixing = false
    @State private var bubbleKeys: [String] = []
    @State private var bubbleRevision = 0

    // Everyday colors that stay in the tray, ending with shiny gold and silver; all the others are one
    // tap away under "All colors".
    private static let trayColorIDs = [1, 2, 4, 5, 6, 7, 9, 10, 12, 13, 14, 16, 20, 19, 40, 41]
    private static let myColorSlots = 6
    private static let lineTools: [DrawingTool] = [.pencil, .ruler, .circle, .square,
                                                   .triangle, .star, .lineStar]

    init(template: MandalaTemplate?, documentID: String? = nil) {
        self.template = template
        _engine = StateObject(wrappedValue: CanvasEngine(template: template, documentID: documentID))
    }

    // One glitter choice for every color, kept until she changes it.
    private var glitterStyle: GlitterStyle {
        GlitterStyle(rawValue: UInt8(clamping: glitterRaw)) ?? .none
    }

    private var myColors: [PaintColor] {
        myColorsRaw.split(separator: ";").enumerated().compactMap { index, entry in
            let parts = entry.split(separator: ",").compactMap { UInt8($0) }
            guard parts.count == 3 else { return nil }
            return PaintColor(id: 200 + index, name: "Mixed color", red: parts[0], green: parts[1], blue: parts[2])
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            VStack(spacing: 12) {
                header
                if landscape {
                    HStack(spacing: 16) {
                        VStack(spacing: 16) {
                            toolGrid(columns: 2, tileWidth: 86)
                            sizePicker
                            historyButtons
                        }
                        .padding(12)
                        .frame(width: 210)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24))
                        canvas.frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(spacing: 12) {
                            modeTile(width: nil)
                            drawer(columns: 3)
                        }
                        .padding(12)
                        .frame(width: 210)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24))
                    }
                } else {
                    canvas.frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            toolGrid(columns: 5, tileWidth: 72)
                            sizePicker
                            Spacer(minLength: 0)
                            modeTile(width: 76)
                            historyButtons
                        }
                        drawer(columns: 12)
                    }
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24))
                }
            }
            .padding(16)
            .background(Theme.cream)
        }
        .onAppear {
            flash([engine.hint, "Pinch to zoom. Move around with two fingers."])
            engine.updateProgress()
        }
        .onChange(of: engine.progress) { old, new in
            guard let new else { return }
            // Only the moment she finishes, not when she opens a page that was already done.
            if let old, !old.finished, new.finished { celebrate() }
        }
        .overlay {
            if celebrating && !UIAccessibility.isReduceMotionEnabled { Confetti() }
        }
        .onChange(of: engine.hint) { _, hint in flash([hint]) }
        .onChange(of: tool) { _, tool in flash([help(for: tool)]) }
        .onChange(of: symmetry) { _, symmetry in
            if symmetry > 1 { flash(["Everything you draw and fill now repeats around the middle."]) }
        }
        .task(id: bubbleRevision) {
            guard bubbleRevision > 0 else { return }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.4)) { bubbleKeys = [] }
        }
        .onDisappear { engine.save() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { engine.save() }
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
            let mixer = ColorMixer { color in
                select(color)
                remember(color)
                mixing = false
            }
            // A page-sized sheet keeps the bowl and every color in view without scrolling.
            if #available(iOS 18.0, *) {
                mixer.presentationSizing(.page)
            } else {
                mixer
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            headerButton("Pages", symbol: "chevron.left", id: "pages") {
                engine.save()
                if engine.errorMessage == nil { dismiss() }
            }
            Text(template?.localizedTitle ?? L.text("My own magic"))
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            if let progress = engine.progress, progress.total > 0 {
                Label("\(progress.done) / \(progress.total)", systemImage: progress.finished ? "star.fill" : "star")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(progress.finished ? Color.orange : Theme.teal)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(.white, in: Capsule())
                    .accessibilityLabel("\(L.text("Colored spaces")): \(progress.done) / \(progress.total)")
                    .accessibilityIdentifier("progress")
            }
            Spacer(minLength: 8)
            headerButton("Share", symbol: "square.and.arrow.up", id: "share") {
                engine.save()
                ShareSheet.present(engine.image)
            }
            headerButton("More", symbol: "ellipsis", id: "more") {
                confirmingClear = false
                confirmingDelete = false
                showingMore = true
            }
            .popover(isPresented: $showingMore) { moreMenu }
        }
    }

    private func headerButton(_ title: String, symbol: String, id: String,
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

    // Rarely used, so kept out of reach of an accidental tap.
    private var moreMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            if confirmingClear {
                Text(L.text("Start this page again?"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Text(L.text("You can bring it back with Undo."))
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                HStack(spacing: 10) {
                    Button(L.text("Keep drawing")) { confirmingClear = false }
                        .buttonStyle(.bordered)
                    Button(L.text("Clear this drawing"), role: .destructive) {
                        engine.reset()
                        showingMore = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            } else if confirmingDelete {
                Text(L.text("Delete this drawing?"))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Text(L.text("It disappears from your drawings and can't be brought back."))
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button(L.text("Keep drawing")) { confirmingDelete = false }
                        .buttonStyle(.bordered)
                    Button(L.text("Delete"), role: .destructive) {
                        engine.delete()
                        showingMore = false
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("confirm-delete")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            } else {
                menuRow(language == "de" ? "English" : "Deutsch", symbol: "globe", id: "editor-language") {
                    language = language == "de" ? "en" : "de"
                    showingMore = false
                }
                menuRow(L.text("Clear"), symbol: "arrow.counterclockwise", id: "clear") { confirmingClear = true }
                // Only her own drawings can be deleted; coloring pages are always there.
                if template == nil {
                    menuRow(L.text("Delete this drawing"), symbol: "trash", id: "delete-drawing") {
                        confirmingDelete = true
                    }
                }
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(20)
        .frame(width: 320, alignment: .leading)
    }

    private func menuRow(_ title: String, symbol: String, id: String,
                         perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Label(title, systemImage: symbol)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .background(Theme.cream, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityIdentifier(id)
    }

    // MARK: Canvas

    private var canvas: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            DrawingSurface(engine: engine, tool: tool, color: selectedColor,
                           glitterStyle: glitterStyle, paintOptions: paintOptions,
                           lineWidth: brushSize.width(for: tool), symmetry: symmetry, pending: pending)
                .accessibilityIdentifier("drawing-canvas")
                .frame(width: side, height: side)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16).stroke(Theme.ink.opacity(0.12), lineWidth: 2)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .top) { hintBubble }
                .shadow(color: Theme.ink.opacity(0.07), radius: 16, y: 6)
                // Pinned to the top when it fills the width, so switching drawers never moves the picture.
                .position(x: geometry.size.width / 2,
                          y: geometry.size.width <= geometry.size.height ? side / 2 : geometry.size.height / 2)
        }
    }

    // A short tip over the picture that fades away, instead of permanent small print.
    @ViewBuilder private var hintBubble: some View {
        if !bubbleKeys.isEmpty {
            Text(bubbleKeys.map { L.text($0) }.joined(separator: "\n"))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.ink.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
                .padding(.top, 14)
                .padding(.horizontal, 14)
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityIdentifier("drawing-hint")
        }
    }

    private func flash(_ keys: [String]) {
        withAnimation(.easeOut(duration: 0.2)) { bubbleKeys = keys }
        bubbleRevision += 1
    }

    private func help(for tool: DrawingTool) -> String {
        switch tool {
        case .fill: return "Tap a closed space to fill it."
        case .brush: return "Draw freely with your selected color and glitter."
        case .pencil: return "Drag on the paper to draw a line."
        case .ruler: return "Drag from one point to another for a straight line."
        case .circle, .square, .triangle, .star, .lineStar: return "Drag on the paper to draw a shape."
        case .eraser: return "Tap to erase a space. Drag to rub out drawn lines and paint."
        }
    }

    // MARK: Tools

    private func toolGrid(columns: Int, tileWidth: CGFloat) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileWidth), spacing: 8), count: columns), spacing: 8) {
            toolTile(.fill)
            toolTile(.brush)
            linesTile
            toolTile(.eraser)
            mirrorTile
        }
    }

    // Mirror drawing is a mode, not a tool: it repeats whatever the current tool does around the center.
    private var mirrorTile: some View {
        tile(title: symmetry > 1 ? "\(L.text("Mirror")) \(symmetry)" : L.text("Mirror"), symbol: "snowflake",
             selected: symmetry > 1, id: "tool-mirror") { choosingMirror = true }
            .popover(isPresented: $choosingMirror) {
                HStack(spacing: 12) {
                    ForEach([0, 6, 8, 12], id: \.self) { count in
                        Button {
                            symmetry = count
                            choosingMirror = false
                        } label: {
                            VStack(spacing: 6) {
                                if count == 0 {
                                    Image(systemName: "nosign").font(.system(size: 30, weight: .medium))
                                } else {
                                    mirrorPreview(count).frame(width: 36, height: 36)
                                }
                                Text(count == 0 ? L.text("Off") : "\(count)")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .frame(width: 96, height: 96)
                            .foregroundStyle(symmetry == count ? .white : Theme.teal)
                            .background(symmetry == count ? Theme.teal : Theme.cream,
                                        in: RoundedRectangle(cornerRadius: 18))
                        }
                        .accessibilityLabel(count == 0 ? L.text("Off") : "\(L.text("Mirror")) \(count)")
                        .accessibilityAddTraits(symmetry == count ? .isSelected : [])
                        .accessibilityIdentifier("mirror-\(count)")
                    }
                }
                .padding(16)
            }
    }

    // The mirror lines for a count, as they appear on the paper.
    private func mirrorPreview(_ count: Int) -> some View {
        GeometryReader { geometry in
            Path { path in
                let radius = geometry.size.width / 2
                for line in 0..<count {
                    let angle = CGFloat(line) * .pi / CGFloat(count)
                    path.move(to: CGPoint(x: radius - cos(angle) * radius, y: radius - sin(angle) * radius))
                    path.addLine(to: CGPoint(x: radius + cos(angle) * radius, y: radius + sin(angle) * radius))
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    private func toolTile(_ item: DrawingTool) -> some View {
        tile(title: item.title, symbol: item.symbol, selected: tool == item,
             showsColor: item == .fill || item == .brush,
             id: item == .eraser ? "eraser" : "tool-\(item.rawValue)") { tool = item }
    }

    // Pencil and shapes all draw black outlines, so they share one tile.
    private var linesTile: some View {
        tile(title: L.text("Lines"), symbol: lineTool.symbol, selected: Self.lineTools.contains(tool),
             id: "tool-lines") { choosingLines = true }
            .popover(isPresented: $choosingLines) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(96), spacing: 12), count: 4), spacing: 12) {
                    ForEach(Self.lineTools) { item in
                        Button {
                            lineTool = item
                            tool = item
                            choosingLines = false
                        } label: {
                            VStack(spacing: 6) {
                                ToolIcon(symbol: item.symbol, size: 30)
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(width: 96, height: 96)
                            .foregroundStyle(tool == item ? .white : Theme.teal)
                            .background(tool == item ? Theme.teal : Theme.cream, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .accessibilityLabel(item.title)
                        .accessibilityAddTraits(tool == item ? .isSelected : [])
                        .accessibilityIdentifier("tool-\(item.rawValue)")
                    }
                }
                .padding(16)
            }
    }

    private func tile(title: String, symbol: String, selected: Bool, showsColor: Bool = false,
                      id: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 4) {
                ToolIcon(symbol: symbol, size: 24)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 68)
            .foregroundStyle(selected ? .white : Theme.teal)
            .background(selected ? Theme.teal : Theme.cream, in: RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                if showsColor {
                    // Shows the paint as it will look, so an active pattern or glitter is visible here too.
                    Image(uiImage: CanvasEngine.swatch(color: selectedColor, glitter: glitterStyle, options: paintOptions))
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .overlay { Circle().stroke(.white, lineWidth: 2) }
                        .padding(5)
                }
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    private var sizePicker: some View {
        HStack(spacing: 2) {
            ForEach(BrushSize.allCases) { size in
                Button { brushSize = size } label: {
                    Circle().fill(brushSize == size ? Theme.teal : Theme.ink.opacity(0.3))
                        .frame(width: size.dot, height: size.dot)
                        .frame(width: 34, height: 56)
                }
                .accessibilityLabel("\(L.text("Size")): \(size.title)")
                .accessibilityAddTraits(brushSize == size ? .isSelected : [])
                .accessibilityIdentifier("size-\(size)")
            }
        }
        .padding(.horizontal, 6)
        .background(Theme.cream, in: Capsule())
        .opacity(tool == .fill ? 0.4 : 1)
    }

    private var historyButtons: some View {
        HStack(spacing: 8) {
            Button { engine.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 26, weight: .bold))
                    .frame(width: 68, height: 68)
                    .foregroundStyle(.white)
                    .background(Theme.teal, in: Circle())
            }
            .disabled(engine.undoCount == 0)
            .opacity(engine.undoCount == 0 ? 0.35 : 1)
            .accessibilityLabel(L.text("Undo"))
            .accessibilityIdentifier("undo")
            Button { engine.redo() } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Theme.teal)
                    .background(Theme.cream, in: Circle())
            }
            .disabled(engine.redoCount == 0)
            .opacity(engine.redoCount == 0 ? 0.35 : 1)
            .accessibilityLabel(L.text("Redo"))
            .accessibilityIdentifier("redo")
        }
    }

    // Switches the drawer between the color box and the glitter and pattern choices.
    private func modeTile(width: CGFloat?) -> some View {
        Button { showingMagic.toggle() } label: {
            VStack(spacing: 4) {
                if showingMagic {
                    Image(systemName: "paintpalette.fill").font(.system(size: 24))
                } else {
                    Image(uiImage: CanvasEngine.swatch(color: selectedColor, glitter: glitterStyle, options: paintOptions))
                        .resizable()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "sparkles").font(.system(size: 13, weight: .bold)).offset(x: 8, y: -6)
                        }
                }
                Text(L.text(showingMagic ? "Colors" : "Magic"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .frame(width: width, height: 68)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .foregroundStyle(Theme.violet)
            .background(Theme.lilac, in: RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityIdentifier(showingMagic ? "show-colors" : "show-magic")
    }

    // Both drawers stay laid out, one hidden, so the tray keeps its height when switching. Otherwise the
    // shorter Magic drawer let the tray drop and the Colors button was no longer under her finger.
    private func drawer(columns: Int) -> some View {
        ZStack(alignment: .top) {
            colorGrid(columns: columns).shown(!showingMagic)
            magicPanel(sideBySide: columns > 3).shown(showingMagic)
        }
    }

    // MARK: Colors

    private func colorGrid(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(Self.trayColorIDs, id: \.self) { id in
                let color = PaintColor.palette[id]
                swatchButton(color, label: L.text(color.name), id: "color-\(id)")
            }
            ForEach(0..<Self.myColorSlots, id: \.self) { index in
                if index < myColors.count {
                    let color = myColors[index]
                    swatchButton(color, label: L.text("My colors"), id: "my-color-\(index)")
                        .contextMenu {
                            Button(role: .destructive) { forget(color) } label: {
                                Label(L.text("Remove color"), systemImage: "trash")
                            }
                            .accessibilityIdentifier("remove-my-color")
                        }
                } else {
                    Button { mixing = true } label: {
                        Circle()
                            .strokeBorder(Theme.ink.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .aspectRatio(1, contentMode: .fit)
                            .padding(3)
                    }
                    .accessibilityLabel(L.text("Mix colors"))
                    .accessibilityIdentifier("my-color-empty-\(index)")
                }
            }
            Button { mixing = true } label: {
                Circle().fill(Theme.cream)
                    .overlay { Image(systemName: "plus").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.teal) }
                    .aspectRatio(1, contentMode: .fit)
                    .padding(3)
            }
            .accessibilityLabel(L.text("Mix colors"))
            .accessibilityIdentifier("mix-colors")
            allColorsButton
        }
    }

    // Shows the chosen color when it came from the full box, so she can see what she picked.
    private var allColorsButton: some View {
        let picked = !Self.trayColorIDs.contains { same(PaintColor.palette[$0], selectedColor) }
            && !myColors.contains { same($0, selectedColor) }
        return Button { choosingAllColors = true } label: {
            Circle().fill(picked ? Color(uiColor: selectedColor.uiColor) : Theme.cream)
                .overlay {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(picked ? contrast(for: selectedColor) : Theme.teal)
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(3)
                .overlay { Circle().stroke(picked ? Theme.ink : .clear, lineWidth: 3) }
        }
        .accessibilityLabel(L.text("All colors"))
        .accessibilityIdentifier("all-colors")
        .popover(isPresented: $choosingAllColors) {
            paletteGrid(idPrefix: "all-color-") { color in
                select(color)
                choosingAllColors = false
            }
        }
    }

    private func swatchButton(_ color: PaintColor, label: String, id: String) -> some View {
        let selected = same(color, selectedColor)
        return Button { select(color) } label: {
            ColorDot(color: color)
                .overlay { Circle().stroke(Theme.ink.opacity(0.15), lineWidth: 1) }
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(contrast(for: color))
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(3)
                .overlay { Circle().stroke(selected ? Theme.ink : .clear, lineWidth: 3) }
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    private func paletteGrid(idPrefix: String, select: @escaping (PaintColor) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(52), spacing: 10), count: 8), spacing: 10) {
            ForEach(PaintColor.palette) { color in
                Button { select(color) } label: {
                    ColorDot(color: color)
                        .frame(width: 52, height: 52)
                        .overlay { Circle().stroke(Theme.ink.opacity(0.2)) }
                }
                .accessibilityLabel(L.text(color.name))
                .accessibilityIdentifier("\(idPrefix)\(color.id)")
            }
        }
        .padding(16)
    }

    // MARK: Magic drawer

    private func magicPanel(sideBySide: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if sideBySide {
                HStack(alignment: .top, spacing: 16) {
                    glitterChoices(columns: 6)
                    patternChoices(columns: 6)
                }
            } else {
                glitterChoices(columns: 3)
                patternChoices(columns: 3)
            }
            // Always laid out, hidden for solid paint, so choosing a pattern never changes the tray's height.
            Group {
                if sideBySide {
                    HStack(spacing: 8) { endpoints; directions }
                } else {
                    endpoints
                    directions
                }
            }
            .shown(paintOptions.effect != .solid)
        }
    }

    // Each choice previews the real texture in her current color instead of naming it.
    private func glitterChoices(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(GlitterStyle.allCases) { finish in
                magicChoice(title: finish.title,
                            image: magicSwatch(color: selectedColor, glitter: finish, options: paintOptions),
                            shape: AnyShape(Circle()), selected: glitterStyle == finish,
                            id: "glitter-\(finish.rawValue)") { glitterRaw = Int(finish.rawValue) }
            }
        }
    }

    private func patternChoices(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(PaintEffect.allCases) { effect in
                let options = PaintOptions(effect: effect, secondColor: paintOptions.secondColor,
                                           direction: paintOptions.direction)
                magicChoice(title: effect.title,
                            image: magicSwatch(color: selectedColor, glitter: glitterStyle, options: options),
                            shape: AnyShape(RoundedRectangle(cornerRadius: 12)), selected: paintOptions.effect == effect,
                            id: "effect-\(effect.rawValue)") { paintOptions.effect = effect }
            }
        }
    }

    private static let blankSwatch = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    // The twelve previews are only drawn while the Magic drawer is open. Drawing them for the hidden
    // drawer on every color change slowed the tray's update, and a quick tap on the page right after
    // picking a color could still paint with the previous one.
    private func magicSwatch(color: PaintColor, glitter: GlitterStyle, options: PaintOptions) -> UIImage {
        showingMagic ? CanvasEngine.swatch(color: color, glitter: glitter, options: options) : Self.blankSwatch
    }

    private func magicChoice(title: String, image: UIImage, shape: AnyShape, selected: Bool, id: String,
                             perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 3) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(shape)
                    .padding(3)
                    .overlay { shape.stroke(selected ? Theme.ink : Theme.ink.opacity(0.12), lineWidth: selected ? 3 : 1) }
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(Theme.ink.opacity(0.75))
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }

    private var endpoints: some View {
        HStack(spacing: 8) {
            endpoint("From", color: selectedColor, id: "gradient-from") { choosingStartColor = true }
                .popover(isPresented: $choosingStartColor) {
                    paletteGrid(idPrefix: "endpoint-color-") { color in
                        select(color, keepPattern: true)
                        choosingStartColor = false
                    }
                }
            endpoint("To", color: paintOptions.secondColor, id: "gradient-to") { choosingEndColor = true }
                .popover(isPresented: $choosingEndColor) {
                    paletteGrid(idPrefix: "endpoint-color-") { color in
                        paintOptions.secondColor = color
                        choosingEndColor = false
                    }
                }
        }
    }

    private var directions: some View {
        HStack(spacing: 8) {
            ForEach(GradientDirection.allCases) { direction in
                let selected = paintOptions.direction == direction
                Button { paintOptions.direction = direction } label: {
                    Image(systemName: symbol(for: direction))
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 48, height: 44)
                        .foregroundStyle(selected ? .white : Theme.teal)
                        .background(selected ? Theme.teal : Theme.cream, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel(direction.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("direction-\(direction.rawValue)")
            }
        }
        .shown(paintOptions.effect == .gradient)
    }

    private func endpoint(_ title: String, color: PaintColor, id: String,
                          perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 6) {
                Circle().fill(Color(uiColor: color.uiColor)).frame(width: 24, height: 24)
                    .overlay { Circle().stroke(Theme.ink.opacity(0.2)) }
                Text(L.text(title)).font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 80, minHeight: 44)
            .foregroundStyle(Theme.ink)
            .background(Theme.cream, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("\(L.text(title)): \(L.text(color.name))")
        .accessibilityIdentifier(id)
    }

    // MARK: Helpers

    private func symbol(for direction: GradientDirection) -> String {
        switch direction {
        case .horizontal: return "arrow.right"
        case .vertical: return "arrow.down"
        case .diagonal: return "arrow.down.right"
        }
    }

    private func same(_ a: PaintColor, _ b: PaintColor) -> Bool {
        a.red == b.red && a.green == b.green && a.blue == b.blue
    }

    private func contrast(for color: PaintColor) -> Color {
        Int(color.red) + Int(color.green) + Int(color.blue) > 560 ? Theme.ink : .white
    }

    // Picking a color from the color drawer means plain paint again: a pattern chosen earlier in Magic
    // is easy to forget once the drawer is closed, and she kept painting dots without noticing.
    // Only From inside Magic keeps the pattern. Glitter stays as set, as decided earlier.
    private func select(_ color: PaintColor, keepPattern: Bool = false) {
        selectedColor = color
        if !keepPattern { paintOptions.effect = .solid }
        if tool != .brush { tool = .fill }
        pending.set(color: color, solid: !keepPattern, tool: tool)
    }

    private func celebrate() {
        flash(["You colored every space!"])
        celebrating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { celebrating = false }
    }

    // A long press on one of her colors removes it, and makes room for a new mix.
    private func forget(_ color: PaintColor) {
        let entry = "\(color.red),\(color.green),\(color.blue)"
        myColorsRaw = myColorsRaw.split(separator: ";").map(String.init).filter { $0 != entry }.joined(separator: ";")
    }

    // Newest first; the oldest of six drops off.
    private func remember(_ color: PaintColor) {
        let entry = "\(color.red),\(color.green),\(color.blue)"
        let others = myColorsRaw.split(separator: ";").map(String.init).filter { $0 != entry }
        myColorsRaw = ([entry] + others).prefix(Self.myColorSlots).joined(separator: ";")
    }
}

extension View {
    /// Keeps the view's space in the layout but hides it from sight, touch, and VoiceOver when not visible.
    /// Opacity alone left hidden buttons findable, so taps meant for them landed on the view underneath.
    @ViewBuilder func shown(_ visible: Bool) -> some View {
        if visible { self } else { hidden() }
    }
}

/// A round color sample; shiny gold and silver show their metal sheen.
struct ColorDot: View {
    let color: PaintColor

    var body: some View {
        if color.isMetallic {
            Image(uiImage: CanvasEngine.swatch(color: color, glitter: .none, options: PaintOptions()))
                .resizable()
                .clipShape(Circle())
        } else {
            Circle().fill(Color(uiColor: color.uiColor))
        }
    }
}

/// A tool's icon: an SF Symbol, or the line star, which has no symbol and is drawn here.
struct ToolIcon: View {
    static let pentagram = "mandolino.pentagram"
    let symbol: String
    let size: CGFloat

    var body: some View {
        if symbol == Self.pentagram {
            Path { path in
                let outer = CanvasEngine.starPoints(in: CGRect(x: 0, y: 0, width: size, height: size)).outer
                path.addLines([0, 2, 4, 1, 3].map { outer[$0] })
                path.closeSubpath()
            }
            .stroke(style: StrokeStyle(lineWidth: max(2, size / 12), lineJoin: .round))
            .frame(width: size, height: size)
        } else {
            Image(systemName: symbol).font(.system(size: size, weight: .semibold))
        }
    }
}

/// The color she just picked, until SwiftUI passes it to the canvas on its next update. A tap on the
/// page that lands before that update (a quick color-then-tap) still paints with the new color.
final class PendingPaint {
    private(set) var color: PaintColor?
    private(set) var solid = false
    private(set) var tool: DrawingTool?

    func set(color: PaintColor, solid: Bool, tool: DrawingTool) {
        self.color = color
        self.solid = solid
        self.tool = tool
    }

    func clear() {
        color = nil
        solid = false
        tool = nil
    }
}

struct DrawingSurface: UIViewRepresentable {
    let engine: CanvasEngine
    let tool: DrawingTool
    let color: PaintColor
    let glitterStyle: GlitterStyle
    let paintOptions: PaintOptions
    let lineWidth: CGFloat
    let symmetry: Int
    let pending: PendingPaint

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
        view.symmetry = symmetry
        // The canvas now has everything she picked, so nothing is pending any more.
        view.pending = pending
        pending.clear()
        view.accessibilityLabel = L.text("Drawing canvas")
        view.accessibilityHint = L.text("Pinch to zoom. Move around with two fingers.")
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
    var engine: CanvasEngine? {
        didSet {
            guard engine !== oldValue else { return }
            engine?.onRender = { [weak self] in self?.showEngineImage() }
            showEngineImage()
        }
    }
    var tool: DrawingTool = .fill
    var color = PaintColor.palette[0]
    var glitterStyle: GlitterStyle = .none
    var paintOptions = PaintOptions()
    var lineWidth: CGFloat = 6
    var pending: PendingPaint?
    private var currentColor: PaintColor { pending?.color ?? color }
    private var currentTool: DrawingTool { pending?.tool ?? tool }
    private var currentOptions: PaintOptions {
        var options = paintOptions
        if pending?.solid == true { options.effect = .solid }
        return options
    }
    var symmetry = 0 {
        didSet { if symmetry != oldValue { updateGuides() } }
    }
    private let guideLayer = CAShapeLayer()
    private let revealLayer = CALayer()
    private var revealToken = 0
    private var start: CGPoint?
    private var previous: CGPoint?
    private var sparklePoints: [CGPoint] = []
    private let sparkleLayer = CALayer()
    private var sparkleSize = CGSize.zero
    private var erasingStroke = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        guideLayer.fillColor = nil
        guideLayer.strokeColor = UIColor(Theme.teal).withAlphaComponent(0.4).cgColor
        guideLayer.lineWidth = 1.5
        guideLayer.lineDashPattern = [6, 6]
        revealLayer.isHidden = true
        layer.addSublayer(revealLayer)
        layer.addSublayer(guideLayer)
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
        guideLayer.frame = bounds
        revealLayer.frame = bounds
        rebuildSparkles()
        updateGuides()
    }

    // Faint mirror lines through the center while mirror drawing is on; they are not part of the picture.
    private func updateGuides() {
        guard symmetry > 1 else {
            guideLayer.path = nil
            return
        }
        let center = CGPoint(x: bounds.midX, y: bounds.midY), radius = bounds.width / 2
        let path = UIBezierPath()
        for line in 0..<symmetry {
            let angle = CGFloat(line) * .pi / CGFloat(symmetry)
            path.move(to: CGPoint(x: center.x - cos(angle) * radius, y: center.y - sin(angle) * radius))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
        }
        guideLayer.path = path.cgPath
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

    // Handing the bitmap to the layer lets the GPU scale it, instead of redrawing it on the CPU every frame.
    private func showEngineImage() {
        guard let engine else { return }
        stopReveal()
        layer.contents = engine.image.cgImage
        updateSparkles(engine.sparklePoints)
    }

    // The new color spreads out from her finger instead of appearing all at once: the old picture
    // stays underneath while the new one shows through a growing circle.
    private func reveal(from point: CGPoint, over previous: Any?) {
        guard let engine, let previous, !UIAccessibility.isReduceMotionEnabled else { return }
        revealToken += 1
        let token = revealToken
        let center = CGPoint(x: point.x * bounds.width, y: point.y * bounds.height)
        let radius = hypot(max(center.x, bounds.width - center.x), max(center.y, bounds.height - center.y))
        func circle(_ r: CGFloat) -> CGPath {
            UIBezierPath(arcCenter: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
        }
        let mask = CAShapeLayer()
        mask.path = circle(radius)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.contents = previous
        revealLayer.contents = engine.image.cgImage
        revealLayer.mask = mask
        revealLayer.isHidden = false
        CATransaction.commit()
        let spread = CABasicAnimation(keyPath: "path")
        spread.fromValue = circle(1)
        spread.toValue = mask.path
        spread.duration = 0.35
        spread.timingFunction = CAMediaTimingFunction(name: .easeOut)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self, self.revealToken == token, let engine = self.engine else { return }
            self.stopReveal()
            self.layer.contents = engine.image.cgImage
        }
        mask.add(spread, forKey: "spread")
        CATransaction.commit()
    }

    private func stopReveal() {
        revealToken += 1
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        revealLayer.isHidden = true
        revealLayer.mask = nil
        revealLayer.contents = nil
        CATransaction.commit()
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
        if !currentTool.isPaintTool { engine?.beginStroke() }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start, let previous, currentTool != .fill else { return }
        if currentTool == .eraser && !erasingStroke {
            engine?.beginStroke()
            erasingStroke = true
        }
        for sample in event?.coalescedTouches(for: touch) ?? [touch] {
            let p = normalized(sample)
            engine?.draw(from: currentTool == .pencil || currentTool == .brush || currentTool == .eraser ? self.previous ?? previous : start,
                         to: p, tool: currentTool, width: lineWidth, color: currentColor, glitterStyle: glitterStyle,
                         options: currentOptions, symmetry: symmetry, render: false)
            self.previous = p
        }
        engine?.renderStroke()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start else { return }
        let p = normalized(touch)
        if currentTool == .eraser {
            if erasingStroke {
                engine?.draw(from: previous ?? start, to: p, tool: .eraser, width: lineWidth,
                             symmetry: symmetry, render: false)
                engine?.endStroke()
            } else {
                engine?.erase(at: p, width: lineWidth, symmetry: symmetry)
            }
        } else if currentTool == .fill {
            if hypot(p.x - start.x, p.y - start.y) < 0.04 {
                let before = layer.contents
                if engine?.fill(at: p, color: currentColor, glitterStyle: glitterStyle, options: currentOptions,
                                symmetry: symmetry) == true {
                    reveal(from: p, over: before)
                }
            }
        } else {
            engine?.draw(from: currentTool == .pencil || currentTool == .brush ? previous ?? start : start,
                         to: p, tool: currentTool, width: lineWidth, color: currentColor, glitterStyle: glitterStyle,
                         options: currentOptions, symmetry: symmetry, render: false)
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

/// Confetti falling over the page once, when she has colored every space.
struct Confetti: View {
    private struct Piece {
        let x: CGFloat, drift: CGFloat, delay: Double, spin: Double, size: CGFloat, color: Color
    }

    @State private var falling = false
    @State private var pieces: [Piece] = (0..<80).map { _ in
        Piece(x: .random(in: 0...1), drift: .random(in: -60...60), delay: .random(in: 0...0.8),
              spin: .random(in: 180...720), size: .random(in: 10...18),
              color: Color(uiColor: PaintColor.palette.randomElement()!.uiColor))
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(pieces.indices, id: \.self) { i in
                let piece = pieces[i]
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.55)
                    .rotationEffect(.degrees(falling ? piece.spin : 0))
                    .position(x: piece.x * geometry.size.width + (falling ? piece.drift : 0),
                              y: falling ? geometry.size.height + 40 : -40)
                    .animation(.easeIn(duration: 2.4).delay(piece.delay), value: falling)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { falling = true }
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
