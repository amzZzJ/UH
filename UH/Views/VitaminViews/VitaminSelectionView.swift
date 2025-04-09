import SwiftUI

struct VitaminSelectionView: View {
    @StateObject private var viewModel = VitaminSelectionViewModel()
    
    var body: some View {
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

            ScrollView {
                Text(viewModel.vitaminSuggestions)
                    .font(.body)
                    .padding()
                Text("Вы также можете почитать об этих витаминах в разделе Справочник.")
                    .font(.body)
                    .padding()
            }
            
            NavigationLink(destination: HistoryView(history: viewModel.history)) {
                Text("Показать историю")
                    .font(.subheadline)
            }
            .padding()
        }
        .padding()
    }
}

struct HistoryView: View {
    let history: [(query: String, response: String)]

    var body: some View {
        List(history, id: \.query) { item in
            VStack(alignment: .leading) {
                Text("Запрос: \(item.query)")
                    .font(.headline)
                Text("Ответ: \(item.response)")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 5)
        }
        .navigationTitle("История")
    }
}

struct VitaminSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VitaminSelectionView()
    }
}
