import SwiftUI

struct NutritionView: View {
    @StateObject private var viewModel = NutritionViewModel()
    
    var body: some View {
        VStack {
            Picker("Выберите раздел", selection: $viewModel.activeTab) {
                Text("Генерация рецептов").tag(NutritionViewModel.NutritionTab.generate)
                Text("Мои рецепты").tag(NutritionViewModel.NutritionTab.myRecipes)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            TabView(selection: $viewModel.activeTab) {
                generateRecipesTab
                    .tag(NutritionViewModel.NutritionTab.generate)
                
                myRecipesTab
                    .tag(NutritionViewModel.NutritionTab.myRecipes)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Рецепты")
    }
    
    private var generateRecipesTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Тип приема пищи", selection: $viewModel.selectedMealType) {
                    ForEach(NutritionViewModel.MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                TextField("Введите ваш запрос", text: $viewModel.userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: viewModel.generateRecipes) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Сгенерировать рецепты")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.userInput.isEmpty)
                .padding(.horizontal)

                if !viewModel.generatedRecipes.isEmpty {
                    Text("Сгенерированные рецепты")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.generatedRecipes.indices, id: \.self) { index in
                        GeneratedRecipeCard(
                            recipe: viewModel.generatedRecipes[index],
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var myRecipesTab: some View {
        ScrollView {
            VStack {
                if viewModel.savedRecipes.isEmpty {
                    Text("У вас пока нет сохраненных рецептов")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.savedRecipes, id: \.id) { recipe in
                        SavedRecipeCard(
                            recipe: recipe,
                            onDelete: { viewModel.deleteRecipe(recipe) }
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionView()
        }
    }
}
