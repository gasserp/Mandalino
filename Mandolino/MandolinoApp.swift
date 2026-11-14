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
    static let peach = Color(red: 1, green: 0.79, blue: 0.65)
}

struct GalleryView: View {
    @AppStorage("appLanguage") private var language = "de"
    @State private var difficulty: Difficulty = .easy
    @State private var selectedPage: Page?
    @State private var openedPageID: String?
    @State private var previewRevisions: [String: Int] = [:]

    struct Page: Identifiable {
        let template: MandalaTemplate?
        var id: String { template?.id ?? "free-draw" }
    }

    var body: some View {
        GeometryReader { geometry in
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
                        Picker(L.text("Language"), selection: $language) {
                            Text("Deutsch").tag("de")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 260)
                        .accessibilityIdentifier("language-switcher")
                        Spacer()
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.orange)
                            .padding(12)
                            .background(Theme.peach.opacity(0.4), in: Circle())
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

                    HStack {
                        Text(L.text("Pick a coloring page"))
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                        Spacer()
                        Text(L.text("Your colors save automatically"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                    Picker(L.text("Difficulty"), selection: $difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("difficulty")

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20),
                                             count: geometry.size.width > 1000 ? 4 : 2), spacing: 20) {
                        ForEach(MandalaTemplate.all.filter { $0.difficulty == difficulty }) { template in
                            Button { open(template) } label: {
                                TemplateCard(template: template,
                                             previewRevision: previewRevisions[template.id, default: 0])
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(template.localizedTitle), \(template.difficulty.title)")
                            .accessibilityIdentifier("template-\(template.id)")
                        }
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill").foregroundStyle(.pink)
                        Text(L.text("No ads. No accounts. Just you and your imagination."))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(32)
                .frame(maxWidth: 1300)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.cream)
        }
        .fullScreenCover(item: $selectedPage, onDismiss: {
            // Only the page that was just colored needs a new preview.
            if let openedPageID { previewRevisions[openedPageID, default: 0] += 1 }
        }) { page in
            ColoringView(template: page.template)
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
        VStack(alignment: .leading, spacing: 12) {
            ArtworkPreview(template: template, revision: previewRevision)
            .aspectRatio(1, contentMode: .fit)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.localizedTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(template.difficulty.title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.teal)
                    .padding(10)
                    .background(Theme.teal.opacity(0.09), in: Circle())
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .overlay { RoundedRectangle(cornerRadius: 26).stroke(Theme.ink.opacity(0.06)) }
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
