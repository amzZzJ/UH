import SwiftUI

struct VitaminDetailView: View {
    let vitamin: Vitamin
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(vitamin.detailedDescription)
                    .font(.body)
                    .padding(.top, 5)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(vitamin.name)
    }
}
