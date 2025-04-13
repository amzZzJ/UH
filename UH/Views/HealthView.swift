import SwiftUI

struct HealthDashboardView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: NutritionView()) {
                    DashboardButton(
                        title: "Рецепты",
                        icon: "leaf.fill",
                        color: .orange,
                        width: 300,
                        height: 150
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                
                NavigationLink(destination: WaterTrackerView()) {
                    DashboardButton(
                        title: "Трекер воды",
                        icon: "drop.fill",
                        color: .blue,
                        width: 300,
                        height: 150
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Питание")
        }
    }
}


struct DashboardButton: View {
    let title: String
    let icon: String
    let color: Color
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
            VStack(spacing: 10) {
                Color.clear.overlay(
                    VStack {
                        Image(systemName: icon)
                        Text(title)
                    }
                    .foregroundColor(.white)
                )
            }
            .background(color)
            .cornerRadius(20)
        }
}

struct HealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HealthDashboardView()
        }
    }
}
