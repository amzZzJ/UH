import SwiftUI

struct HealthView: View {
    var body: some View {
        VStack(spacing: 30) {
            NavigationLink(destination: NutritionView()) {
                HealthCard(title: "Питание", icon: "leaf.fill", color: .blue)
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: WaterTrackerView()) {
                HealthCard(title: "Трекер воды", icon: "drop.fill", color: .blue)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding()
        .navigationTitle("Здоровье")
    }
}

struct HealthCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            Spacer()
        }
        .padding()
        .frame(width: 300, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct HealthView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HealthView()
        }
    }
}
