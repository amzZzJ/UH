import SwiftUI

struct SavedQueriesView: View {
    @ObservedObject var viewModel: VitaminSelectionViewModel
    @State private var expandedQueryID: UUID?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.savedQueries, id: \.id) { query in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(query.query ?? "Без названия")
                                .font(.headline)
                            Spacer()
                            Image(systemName: expandedQueryID == query.id ? "chevron.up" : "chevron.down")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                expandedQueryID = expandedQueryID == query.id ? nil : query.id
                            }
                        }
                        
                        Text(formattedDate(query.createdAt))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if expandedQueryID == query.id {
                            Text(query.response ?? "")
                                .font(.body)
                                .padding(.top, 4)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 8)
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.deleteQuery(query)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("История запросов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
