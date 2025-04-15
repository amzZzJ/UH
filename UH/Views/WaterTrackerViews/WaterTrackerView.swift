import SwiftUI
import CoreData

struct WaterTrackerView: View {
    @StateObject private var viewModel: WaterTrackerViewModel
    @State private var inputGoal: String = ""
    @State private var inputWater: String = ""
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let context = CoreDataManager.shared.context
        _viewModel = StateObject(wrappedValue: WaterTrackerViewModel(context: context))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Водный трекер")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                goalSection
                
                progressCircle
                
                addWaterSection
                
                quickButtonsSection
                
                resetButton
                
                weeklyStatisticsSection
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.checkForNewDay()
            }
        }
        .onAppear {
            viewModel.loadWeeklyData()
        }
    }
    
    private var goalSection: some View {
        HStack {
            TextField("Цель (мл)", text: $inputGoal)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Установить") {
                if let goal = Double(inputGoal), goal > 0 {
                    viewModel.setGoal(goal)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.loadWeeklyData()
                    }

                    inputGoal = ""
                    hideKeyboard()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var progressCircle: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 1.0)
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            Circle()
                .trim(from: 0.0, to: viewModel.progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: viewModel.progress)
            
            VStack {
                Text("\(Int(viewModel.currentIntake)) мл")
                    .font(.largeTitle)
                    .bold()
                Text("из \(Int(viewModel.dailyGoal)) мл")
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 200, height: 200)
    }
    
    private var addWaterSection: some View {
        HStack {
            TextField("Добавить (мл)", text: $inputWater)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("+") {
                if let amount = Double(inputWater), amount > 0 {
                    viewModel.addWater(amount)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.loadWeeklyData()
                    }

                    inputWater = ""
                    hideKeyboard()
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.title)
        }
    }
    
    private var quickButtonsSection: some View {
        HStack {
            ForEach([100, 250, 500], id: \.self) { amount in
                Button("+\(amount)") {
                    viewModel.addWater(Double(amount))

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.loadWeeklyData()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var resetButton: some View {
        Button("Сбросить") {
            viewModel.reset()
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }
    
    private var weeklyStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Статистика за последние 7 дней")
                .font(.title2)
                .bold()
                .padding(.top, 20)
            
            ForEach(viewModel.weeklyData, id: \.date) { dayData in
                HStack {
                    Text(dayData.date.formatted(date: .abbreviated, time: .omitted))
                        .frame(width: 80, alignment: .leading)
                    
                    ProgressView(value: min(dayData.intake / dayData.goal, 1))
                        .tint(dayData.intake >= dayData.goal ? .orange : .blue)
                    
                    Text("\(Int(dayData.intake))/\(Int(dayData.goal)) мл")
                        .frame(width: 100, alignment: .trailing)
                }
            }
            
            if viewModel.weeklyData.isEmpty {
                Text("Нет данных за последние 7 дней")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct WaterTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        WaterTrackerView()
    }
}
