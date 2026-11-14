import SwiftUI

struct ColorMixer: View {
    @AppStorage("appLanguage") private var language = "de"
    @Environment(\.dismiss) private var dismiss
    private struct Ingredient: Identifiable {
        let id = UUID()
        var color: PaintColor
        var amount: Double = 50
    }

    @State private var ingredients: [Ingredient]
    @State private var selectedID: UUID
    let use: (PaintColor) -> Void
    private var mixed: PaintColor { PaintColor.mix(ingredients.map { ($0.color, $0.amount) }) }
    private var total: Double { ingredients.reduce(0) { $0 + $1.amount } }

    init(use: @escaping (PaintColor) -> Void) {
        let initial = [Ingredient(color: PaintColor.palette[1]), Ingredient(color: PaintColor.palette[4])]
        _ingredients = State(initialValue: initial)
        _selectedID = State(initialValue: initial[0].id)
        self.use = use
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text(L.text("Mix colors"))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Spacer()
                    Button(L.text("Close")) { dismiss() }
                }
                Text(L.text("Pick colors and adjust their amounts."))
                    .font(.system(size: 18, design: .rounded))
                ForEach($ingredients) { $ingredient in
                    if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                        ingredientRow($ingredient, index: index)
                    }
                }
                Button {
                    let ingredient = Ingredient(color: PaintColor.palette[10])
                    ingredients.append(ingredient)
                    selectedID = ingredient.id
                } label: {
                    Label(L.text("Add color"), systemImage: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .accessibilityIdentifier("mix-add-color")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(PaintColor.palette) { color in
                        Button {
                            if let index = ingredients.firstIndex(where: { $0.id == selectedID }) {
                                ingredients[index].color = color
                                if index == 0, ingredients.count > 1 { selectedID = ingredients[1].id }
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

    private func ingredientRow(_ ingredient: Binding<Ingredient>, index: Int) -> some View {
        let value = ingredient.wrappedValue
        return VStack(spacing: 10) {
            HStack(spacing: 16) {
                Button { selectedID = value.id } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Color(uiColor: value.color.uiColor))
                            .frame(width: 48, height: 48)
                            .overlay { Circle().stroke(selectedID == value.id ? Theme.teal : .clear, lineWidth: 3) }
                        Text(L.text(value.color.name))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
                .accessibilityAddTraits(selectedID == value.id ? .isSelected : [])
                .accessibilityIdentifier(index == 0 ? "mix-first" : index == 1 ? "mix-second" :
                                         "mix-ingredient-\(value.id)")
                Spacer()
                Text("\(Int((value.amount / total * 100).rounded()))%")
                    .monospacedDigit()
                Button {
                    ingredients.removeAll { $0.id == value.id }
                    if selectedID == value.id { selectedID = ingredients[0].id }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .disabled(ingredients.count == 1)
                .accessibilityLabel(L.text("Remove color"))
                .accessibilityIdentifier("mix-remove-\(index)")
            }
            HStack {
                Text(L.text("Amount"))
                Slider(value: ingredient.amount, in: 1...100, step: 1)
                    .accessibilityLabel("\(L.text("Amount")): \(L.text(value.color.name))")
                    .accessibilityValue("\(Int(value.amount)) \(L.text("Parts"))")
                    .accessibilityIdentifier("mix-amount-\(index)")
                Text("\(Int(value.amount)) \(L.text("Parts"))")
                    .font(.system(size: 14, design: .rounded))
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
