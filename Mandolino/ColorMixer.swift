import SwiftUI

// Each tap on a color drops one part of it into the bowl, so the amounts are something she can see and count.
struct ColorMixer: View {
    @AppStorage("appLanguage") private var language = "de"
    @Environment(\.dismiss) private var dismiss
    private struct Ingredient: Identifiable {
        let color: PaintColor
        var drops = 1
        var id: Int { color.id }
    }

    private static let maxDrops = 10
    private static let maxIngredients = 6

    @State private var ingredients: [Ingredient] = []
    let use: (PaintColor) -> Void

    private var total: Int { ingredients.reduce(0) { $0 + $1.drops } }
    private var mixed: PaintColor? {
        ingredients.isEmpty ? nil : PaintColor.mix(ingredients.map { ($0.color, Double($0.drops)) })
    }

    init(use: @escaping (PaintColor) -> Void) {
        self.use = use
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text(L.text("Mix colors"))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 48, height: 48)
                            .background(.white, in: Circle())
                    }
                    .accessibilityLabel(L.text("Close"))
                    .accessibilityIdentifier("mix-close")
                }
                HStack(spacing: 24) {
                    bowl
                    VStack(alignment: .leading, spacing: 10) {
                        if ingredients.isEmpty {
                            Text(L.text("Tap a color to drop it in."))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.ink.opacity(0.7))
                        } else {
                            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                ingredientRow(ingredient, index: index)
                            }
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { ingredients.removeAll() }
                            } label: {
                                Label(L.text("Start over"), systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .accessibilityIdentifier("mix-start-over")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 10), spacing: 10) {
                    // Metal paint can't be mixed: its shine would turn into a flat color.
                    ForEach(PaintColor.palette.filter { !$0.isMetallic }) { color in
                        Button { addDrop(of: color) } label: {
                            Circle().fill(Color(uiColor: color.uiColor))
                                .overlay { Circle().stroke(Theme.ink.opacity(0.15)) }
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .accessibilityLabel(L.text(color.name))
                        .accessibilityIdentifier("mix-color-\(color.id)")
                    }
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(28)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream)
        .safeAreaInset(edge: .bottom) {
            Button { if let mixed { use(mixed) } } label: {
                Text(L.text("Use this color"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundStyle(.white)
                    .background(Theme.teal, in: RoundedRectangle(cornerRadius: 18))
            }
            .disabled(mixed == nil)
            .opacity(mixed == nil ? 0.4 : 1)
            .accessibilityIdentifier("use-mixed-color")
            .padding(20)
            .background(Theme.cream)
        }
    }

    private var bowl: some View {
        ZStack {
            if let mixed {
                Circle().fill(Color(uiColor: mixed.uiColor))
                    .overlay { Circle().stroke(.white, lineWidth: 8) }
                    .shadow(color: Theme.ink.opacity(0.15), radius: 10, y: 4)
            } else {
                Circle().strokeBorder(Theme.ink.opacity(0.25), style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                Image(systemName: "drop")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.3))
            }
        }
        .frame(width: 180, height: 180)
        .animation(.easeInOut(duration: 0.35), value: mixed.map { "\($0.red),\($0.green),\($0.blue)" })
        .accessibilityElement()
        .accessibilityLabel(L.text("Your new color"))
        .accessibilityIdentifier("mixed-preview")
    }

    private func ingredientRow(_ ingredient: Ingredient, index: Int) -> some View {
        let percent = Int((Double(ingredient.drops) / Double(total) * 100).rounded())
        let tint = Color(uiColor: ingredient.color.uiColor)
        return HStack(spacing: 8) {
            stepButton("minus", label: "Remove a drop", id: "mix-less-\(index)") { removeDrop(at: index) }
            HStack(spacing: 1) {
                ForEach(0..<ingredient.drops, id: \.self) { _ in
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(tint)
                        .overlay {
                            Image(systemName: "drop").font(.system(size: 18)).foregroundStyle(Theme.ink.opacity(0.25))
                        }
                }
            }
            .frame(width: 150, alignment: .leading)
            stepButton("plus", label: "Add a drop", id: "mix-more-\(index)") { addDrop(of: ingredient.color) }
                .disabled(ingredient.drops >= Self.maxDrops)
                .opacity(ingredient.drops >= Self.maxDrops ? 0.4 : 1)
            Text("\(percent)%")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(L.text(ingredient.color.name)): \(ingredient.drops) \(L.text("drops")), \(percent)%")
    }

    private func stepButton(_ symbol: String, label: String, id: String,
                            perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .foregroundStyle(Theme.teal)
                .background(.white, in: Circle())
        }
        .accessibilityLabel(L.text(label))
        .accessibilityIdentifier(id)
    }

    private func addDrop(of color: PaintColor) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if let index = ingredients.firstIndex(where: { $0.color.id == color.id }) {
                ingredients[index].drops = min(ingredients[index].drops + 1, Self.maxDrops)
            } else if ingredients.count < Self.maxIngredients {
                ingredients.append(Ingredient(color: color))
            }
        }
    }

    private func removeDrop(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if ingredients[index].drops > 1 {
                ingredients[index].drops -= 1
            } else {
                ingredients.remove(at: index)
            }
        }
    }
}
