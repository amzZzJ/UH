import SwiftUI

struct Vitamin: Identifiable {
    let id = UUID()
    let name: String
    let shortDescription: String
    let detailedDescription: String
}

struct VitaminGuideView: View {
    let vitamins: [Vitamin] = [
        Vitamin(name: "Витамин A",
                shortDescription: "Полезен для зрения и иммунитета",
                detailedDescription: "Витамин A необходим для здоровья глаз, кожи и иммунной системы. Он помогает при росте клеток, улучшает зрение в темноте и предотвращает воспалительные процессы. Содержится в моркови, тыкве, печени, сливочном масле."),
        
        Vitamin(name: "Витамин B1 (Тиамин)",
                shortDescription: "Поддерживает нервную систему и обмен веществ",
                detailedDescription: "Тиамин играет ключевую роль в углеводном обмене и нормальной работе нервной системы. Дефицит может привести к слабости, раздражительности и усталости. Источники: злаки, бобовые, мясо, орехи."),
        
        Vitamin(name: "Витамин C",
                shortDescription: "Укрепляет иммунитет, антиоксидант",
                detailedDescription: "Витамин C улучшает защитные функции организма, ускоряет заживление ран, участвует в выработке коллагена и защищает от свободных радикалов. Содержится в цитрусовых, ягодах, болгарском перце."),
        
        Vitamin(name: "Витамин D",
                shortDescription: "Укрепляет кости и иммунитет",
                detailedDescription: "Витамин D помогает усваивать кальций, что важно для здоровья костей. Он также поддерживает иммунитет. Дефицит может привести к остеопорозу. Источники: солнечный свет, рыбий жир, молочные продукты."),
        
        Vitamin(name: "Витамин E",
                shortDescription: "Антиоксидант, замедляет старение",
                detailedDescription: "Этот витамин защищает клетки от повреждений, замедляет процессы старения, улучшает состояние кожи и волос. Источники: растительные масла, орехи, шпинат."),
        
        Vitamin(name: "Витамин K",
                shortDescription: "Отвечает за свертываемость крови",
                detailedDescription: "Витамин K участвует в процессах свертываемости крови и укрепляет кости. Он содержится в зеленых овощах, брокколи, киви."),
    ]
    
    var body: some View {
        NavigationView {
            List(vitamins) { vitamin in
                NavigationLink(destination: VitaminDetailView(vitamin: vitamin)) {
                    VStack(alignment: .leading) {
                        Text(vitamin.name)
                            .font(.headline)
                        Text(vitamin.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Справочник витаминов")
        }
    }
}

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

struct VitaminGuideView_Previews: PreviewProvider {
    static var previews: some View {
        VitaminGuideView()
    }
}
