import SwiftUI

struct AddWorkoutView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $selectedTab) {
                    ManualWorkoutView()
                        .tabItem {
                            Label("Вручную", systemImage: "pencil")
                        }
                        .tag(0)
                    
                    AIWorkoutView()
                        .tabItem {
                            Label("С ИИ", systemImage: "sparkles")
                        }
                        .tag(1)
                }
            }
            .navigationTitle("Добавить тренировку")
        }
    }
}
