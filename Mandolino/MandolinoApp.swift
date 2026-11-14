import SwiftUI

@main
struct MandolinoApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("-UITestEnglish") {
            UserDefaults.standard.set("en", forKey: "appLanguage")
        } else if ProcessInfo.processInfo.arguments.contains("-UITestGerman") {
            UserDefaults.standard.set("de", forKey: "appLanguage")
        }
        Task.detached(priority: .utility) { CanvasEngine.convertLegacyDrawings() }
    }

    var body: some Scene {
        WindowGroup {
            GalleryView()
                .preferredColorScheme(.light)
                .tint(Theme.teal)
        }
    }
}

enum Theme {
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let ink = Color(red: 0.17, green: 0.23, blue: 0.28)
    static let teal = Color(red: 0.08, green: 0.48, blue: 0.46)
    static let lilac = Color(red: 0.94, green: 0.91, blue: 1)
    static let violet = Color(red: 0.42, green: 0.29, blue: 0.72)
}

struct GalleryView: View {
    @AppStorage("appLanguage") private var language = "de"
    @State private var difficulty: Difficulty = .easy
    @State private var selectedPage: Page?
    @State private var openedPageID: String?
    @State private var previewRevisions: [String: Int] = [:]
    @State private var showingSettings = false

    struct Page: Identifiable {
        let template: MandalaTemplate?
        var id: String { template?.id ?? "free-draw" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mandolino")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(L.text("Little spaces. Big imagination."))
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.65))
                    }
                    Spacer()
                    // The language switch and the notes for grown-ups live here, away from accidental taps.
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.teal)
                            .frame(width: 52, height: 52)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .accessibilityLabel(L.text("Settings"))
                    .accessibilityIdentifier("gallery-settings")
                    .popover(isPresented: $showingSettings) { settings }
                }

                Button { open(nil) } label: {
                    HStack(spacing: 20) {
                        ArtworkPreview(template: nil, revision: previewRevisions["free-draw", default: 0])
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.text("Make your own magic"))
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                            Text(L.text("Draw lines & shapes, then fill them with color."))
                                .font(.system(size: 17, design: .rounded))
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill").font(.system(size: 34))
                    }
                    .foregroundStyle(.white)
                    .padding(26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.teal.gradient, in: RoundedRectangle(cornerRadius: 26))
                }
                .accessibilityIdentifier("free-draw")

                Text(L.text("Pick a coloring page"))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 12) {
                    ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, level in
                        difficultyTab(level, stars: index + 1)
                    }
                }

                // One row per design with all its versions, so related pages stay together.
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
                ForEach(MandalaTemplate.all.filter { $0.difficulty == difficulty && $0.variation == 0 }) { design in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(design.localizedTitle)
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(MandalaTemplate.all.filter { $0.designID == design.designID }) { template in
                                Button { open(template) } label: {
                                    TemplateCard(template: template,
                                                 previewRevision: previewRevisions[template.id, default: 0])
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(template.localizedTitle), \(template.difficulty.title)")
                                .accessibilityIdentifier("template-\(template.id)")
                            }
                        }
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 1300)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream)
        .fullScreenCover(item: $selectedPage, onDismiss: {
            // Only the page that was just colored needs a new preview.
            if let openedPageID { previewRevisions[openedPageID, default: 0] += 1 }
        }) { page in
            ColoringView(template: page.template)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.text("Language"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Picker(L.text("Language"), selection: $language) {
                Text("Deutsch").tag("de")
                Text("English").tag("en")
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("language-switcher")
            Divider()
            Label(L.text("Your colors save automatically"), systemImage: "checkmark.circle.fill")
                .fixedSize(horizontal: false, vertical: true)
            Label(L.text("No ads. No accounts. Just you and your imagination."), systemImage: "heart.fill")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 15, weight: .medium, design: .rounded))
        .foregroundStyle(Theme.ink)
        .padding(20)
        .frame(width: 340, alignment: .leading)
    }

    private func difficultyTab(_ level: Difficulty, stars: Int) -> some View {
        let selected = difficulty == level
        let color = Self.color(for: level)
        return Button { difficulty = level } label: {
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<stars, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.system(size: 14, weight: .bold))
                    }
                }
                Text(level.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 68)
            .foregroundStyle(selected ? .white : color)
            .background(selected ? color : .white, in: RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityLabel(level.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("difficulty-\(level.rawValue)")
    }

    private static func color(for level: Difficulty) -> Color {
        switch level {
        case .easy: return Color(red: 0.27, green: 0.58, blue: 0.33)
        case .medium: return Theme.teal
        case .hard: return Color(red: 0.84, green: 0.42, blue: 0.16)
        case .expert: return Theme.violet
        }
    }

    private func open(_ template: MandalaTemplate?) {
        let page = Page(template: template)
        openedPageID = page.id
        selectedPage = page
    }
}

struct TemplateCard: View {
    let template: MandalaTemplate
    let previewRevision: Int

    var body: some View {
        ArtworkPreview(template: template, revision: previewRevision)
            .aspectRatio(1, contentMode: .fit)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(6)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(Theme.ink.opacity(0.06)) }
    }
}

struct ArtworkPreview: View {
    let template: MandalaTemplate?
    let revision: Int
    @State private var preview: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.ink)
                    .padding(8)
            } else if let preview {
                Image(uiImage: preview).resizable().scaledToFit()
            } else {
                Color.white.overlay { ProgressView() }
            }
        }
        .background(.white)
        .accessibilityIdentifier("preview-\(template?.id ?? "free-draw")")
        .task(id: revision) {
            do {
                preview = try await PreviewRenderer.shared.image(for: template, revision: revision)
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }

    }
}

private actor PreviewRenderer {
    static let shared = PreviewRenderer()
    private let cache = NSCache<NSString, UIImage>()

    func image(for template: MandalaTemplate?, revision: Int) throws -> UIImage {
        let id = template?.id ?? "free-draw"
        let key = "\(id)#\(revision)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        try Task.checkCancellation()
        let image: UIImage
        if let url = try? CanvasEngine.thumbnailURL(for: id), let saved = UIImage(contentsOfFile: url.path) {
            image = saved
        } else {
            // Untouched pages and drawings saved before thumbnails existed.
            image = try CanvasEngine.preview(template: template)
        }
        cache.setObject(image, forKey: key)
        return image
    }
}
