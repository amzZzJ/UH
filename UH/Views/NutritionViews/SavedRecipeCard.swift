import SwiftUI

struct SavedRecipeCard: View {
    let recipe: Recipe
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name ?? "Без названия")
                        .font(.headline)
                    Text(recipe.type ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.orange)
                }
            }
            
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 10) {
                        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                            Text("Ингредиенты:")
                                .font(.subheadline.bold())
                            Text(ingredients)
                        }
                        
                        if let instructions = recipe.instructions, !instructions.isEmpty {
                            Text("Приготовление:")
                                .font(.subheadline.bold())
                            Text(instructions)
                        }
                    }
                    .padding(.top, 5)
                },
                label: {
                    Text(isExpanded ? "Скрыть детали" : "Показать детали")
                        .font(.caption)
                }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}
