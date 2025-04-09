import SwiftUI

struct HomeHeaderView: View {
    @Binding var username: String
    @Binding var currentDate: Date
    
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: geometry.size.width * 1.5, height: 160)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -50, y: -25)
            }
            .edgesIgnoringSafeArea(.top)

            Text("Привет, \(username)!\nИтак, наш план на сегодня:")
                .font(.system(size: 30))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading, 15)
        }
        .frame(height: 140)
    }
}
