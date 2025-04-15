import SwiftUI

struct VitaminSelectionView: View {
    @StateObject private var viewModel = VitaminSelectionViewModel()
    @State private var showingSavedQueries = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Подбор витаминов по запросу")
                    .font(.title)
                    .padding()
                
                TextField("Введите цель (например, для улучшения иммунитета)",
                         text: $viewModel.userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: viewModel.generateVitaminSuggestions) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Подобрать витамины")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading || viewModel.userInput.isEmpty)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                ScrollView {
                    if !viewModel.vitaminSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Рекомендации:")
                                .font(.headline)
                            Text(viewModel.vitaminSuggestions)
                            
                            Divider()
                            
                            Text("Вы также можете почитать об этих витаминах в разделе Справочник.")
                                .font(.subheadline)
                        }
                        .padding()
                    }
                }
                
                Button(action: { showingSavedQueries.toggle() }) {
                    Text("История запросов")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.bottom)
            }
            .padding()
            .sheet(isPresented: $showingSavedQueries) {
                SavedQueriesView(viewModel: viewModel, isPresented: $showingSavedQueries)
            }
        }
    }
}

struct VitaminSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VitaminSelectionView()
    }
}
