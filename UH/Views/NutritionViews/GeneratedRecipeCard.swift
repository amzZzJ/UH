import SwiftUI

struct GeneratedRecipeCard: View {
    let recipe: GeneratedRecipe
    @ObservedObject var viewModel: NutritionViewModel
    @State private var isSaved = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    viewModel.saveRecipe(recipe)
                    withAnimation(.spring()) {
                        isSaved = true
                    }
                }) {
                    Image(systemName: "bookmark")
                        .symbolVariant(isSaved || viewModel.isRecipeSaved(recipe) ? .fill : .none)
                        .foregroundColor(isSaved || viewModel.isRecipeSaved(recipe) ? .white : .blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(isSaved || viewModel.isRecipeSaved(recipe) ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ингредиенты:")
                            .font(.subheadline.bold())
                        Text(recipe.ingredients)
                        
                        Text("Приготовление:")
                            .font(.subheadline.bold())
                        Text(recipe.instructions)
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
        .onAppear {
            isSaved = viewModel.isRecipeSaved(recipe)
        }
    }
}
