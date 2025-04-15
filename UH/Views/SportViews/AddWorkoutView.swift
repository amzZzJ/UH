import SwiftUI

struct AddWorkoutView: View {
    enum WorkoutTab: CaseIterable {
        case manual
        case ai
        
        var title: String {
            switch self {
            case .manual: return "Вручную"
            case .ai: return "С ИИ"
            }
        }
        
        var icon: String {
            switch self {
            case .manual: return "pencil"
            case .ai: return "sparkles"
            }
        }
    }
    
    @State private var selectedTab: WorkoutTab = .manual
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(WorkoutTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                    Text(tab.title)
                                }
                                .font(.subheadline)
                                .foregroundColor(selectedTab == tab ? .orange : .gray)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                
                                if selectedTab == tab {
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
                
                Group {
                    switch selectedTab {
                    case .manual:
                        ManualWorkoutView(isPresented: $isPresented)
                    case .ai:
                        AIWorkoutView(isPresented: $isPresented)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Добавить тренировку")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
