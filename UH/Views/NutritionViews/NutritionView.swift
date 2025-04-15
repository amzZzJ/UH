import SwiftUI

struct NutritionView: View {
    @StateObject private var viewModel = NutritionViewModel()
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(NutritionViewModel.NutritionTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            viewModel.activeTab = tab
                        }
                    }) {
                        VStack {
                            Text(tab.title)
                                .font(.subheadline)
                                .foregroundColor(viewModel.activeTab == tab ? .orange : .gray)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                            
                            if viewModel.activeTab == tab {
                                Capsule()
                                    .fill(Color.orange)
                                    .frame(height: 3)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .padding(.horizontal)
            
            TabView(selection: $viewModel.activeTab) {
                generateRecipesTab
                    .tag(NutritionViewModel.NutritionTab.generate)
                
                myRecipesTab
                    .tag(NutritionViewModel.NutritionTab.myRecipes)
                
                remindersTab
                    .tag(NutritionViewModel.NutritionTab.reminders)
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
    
    private var remindersTab: some View {
        Form {
            Section(header: Text("Завтрак")) {
                Toggle("Напомнить о завтраке", isOn: $viewModel.breakfastReminderEnabled)
                
                if viewModel.breakfastReminderEnabled {
                    DatePicker("Время",
                             selection: $viewModel.breakfastTime,
                             displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("Обед")) {
                Toggle("Напомнить об обеде", isOn: $viewModel.lunchReminderEnabled)
                
                if viewModel.lunchReminderEnabled {
                    DatePicker("Время",
                             selection: $viewModel.lunchTime,
                             displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("Ужин")) {
                Toggle("Напомнить об ужине", isOn: $viewModel.dinnerReminderEnabled)
                
                if viewModel.dinnerReminderEnabled {
                    DatePicker("Время",
                             selection: $viewModel.dinnerTime,
                             displayedComponents: .hourAndMinute)
                }
            }
            
            Section {
                Button("Сохранить настройки") {
                    viewModel.saveReminderSettings()
                }
            }
        }
        .onAppear {
            viewModel.requestNotificationAuthorization()
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
