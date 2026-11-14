import SwiftUI

struct ColorMixer: View {
    @AppStorage("appLanguage") private var language = "de"
    @Environment(\.dismiss) private var dismiss
    @State private var first = PaintColor.palette[1]
    @State private var second = PaintColor.palette[4]
    @State private var choosingFirst = true
    let use: (PaintColor) -> Void
    private var mixed: PaintColor { PaintColor.mix(first, second) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text(L.text("Mix colors"))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Spacer()
                    Button(L.text("Close")) { dismiss() }
                }
                Text(L.text("Pick two colors. Make a new one!"))
                    .font(.system(size: 18, design: .rounded))
                HStack(spacing: 20) {
                    ingredient(first, title: "First color", active: choosingFirst, id: "mix-first") {
                        choosingFirst = true
                    }
                    Image(systemName: "plus").font(.title.bold())
                    ingredient(second, title: "Second color", active: !choosingFirst, id: "mix-second") {
                        choosingFirst = false
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(PaintColor.palette) { color in
                        Button {
                            if choosingFirst {
                                first = color
                                choosingFirst = false
                            } else {
                                second = color
                            }
                        } label: {
                            Circle().fill(Color(uiColor: color.uiColor))
                                .frame(width: 56, height: 56)
                                .overlay { Circle().stroke(Theme.ink.opacity(0.15)) }
                        }
                        .accessibilityLabel(L.text(color.name))
                        .accessibilityIdentifier("mix-color-\(color.id)")
                    }
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(30)
            .frame(maxWidth: 660)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Circle().fill(Color(uiColor: mixed.uiColor))
                    .frame(width: 64, height: 64)
                    .overlay { Circle().stroke(Theme.ink.opacity(0.1)) }
                    .accessibilityIdentifier("mixed-preview")
                Text(L.text("Your new color"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Button { use(mixed) } label: {
                    Text(L.text("Use this color"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundStyle(.white)
                        .background(Theme.teal, in: RoundedRectangle(cornerRadius: 18))
                }
                .accessibilityIdentifier("use-mixed-color")
            }
            .padding(20)
            .background(Theme.cream)
        }
    }

    private func ingredient(_ color: PaintColor, title: String, active: Bool, id: String,
                            select: @escaping () -> Void) -> some View {
        Button(action: select) {
            VStack(spacing: 10) {
                Circle().fill(Color(uiColor: color.uiColor))
                    .frame(width: 84, height: 84)
                    .padding(6)
                    .overlay { Circle().stroke(active ? Theme.teal : .clear, lineWidth: 4) }
                Text(L.text(title)).font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
        .accessibilityIdentifier(id)
    }
}
