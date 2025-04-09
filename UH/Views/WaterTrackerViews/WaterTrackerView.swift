import SwiftUI
import Charts
import UserNotifications

struct TrackerSettingsView: View {
    @State private var dailyGoal: Double = 2000
    @State private var waterIntake: Double = 0
    @State private var inputGoal: String = ""
    @State private var inputWater: String = ""
    
    @AppStorage("waterData") private var waterData: String = ""
    
    var progress: Double {
        min(waterIntake / dailyGoal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Водный трекер")
                .font(.largeTitle)
                .bold()
            
            HStack {
                TextField("Цель (мл)", text: $inputGoal)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Установить") {
                    if let goal = Double(inputGoal), goal > 0 {
                        dailyGoal = goal
                        inputGoal = ""
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 1.0)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)

                VStack {
                    Text("\(Int(waterIntake)) мл")
                        .font(.largeTitle)
                        .bold()
                    Text("из \(Int(dailyGoal)) мл")
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 200, height: 200)
            
            HStack {
                TextField("Сколько выпили (мл)", text: $inputWater)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Добавить") {
                    if let amount = Double(inputWater), amount > 0 {
                        waterIntake += amount
                        saveWaterData()
                        inputWater = ""
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)

            Button("Сброс") {
                waterIntake = 0
                saveWaterData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadWaterData()
        }
    }
    
    func saveWaterData() {
        let dateKey = getDateKey()
        var history = getWaterHistory()
        history[dateKey] = waterIntake
        if let encoded = try? JSONEncoder().encode(history) {
            waterData = String(data: encoded, encoding: .utf8) ?? ""
        }
    }
    
    func loadWaterData() {
        let history = getWaterHistory()
        let today = getDateKey()
        waterIntake = history[today] ?? 0
    }
    
    func getWaterHistory() -> [String: Double] {
        if let data = waterData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            return decoded
        }
        return [:]
    }
    
    func getDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct WaterReminderView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderInterval") private var reminderInterval: Double = 2
    @AppStorage("reminderStartTime") private var reminderStartTimeStr = ""
    @AppStorage("reminderEndTime") private var reminderEndTimeStr = ""

    @State private var reminderStartTime: Date = Date()
    @State private var reminderEndTime: Date = Date()
    
    private let formatter = ISO8601DateFormatter()

    var body: some View {
        VStack(spacing: 20) {
            Text("Напоминания о воде")
                .font(.largeTitle)
                .bold()
            
            Toggle("Включить напоминания", isOn: $reminderEnabled)
                .padding()
                .onChange(of: reminderEnabled) { _ in updateReminders() }
            
            VStack {
                Text("Интервал напоминаний (часов)")
                Stepper("\(Int(reminderInterval)) ч", value: $reminderInterval, in: 1...6, step: 1)
                    .onChange(of: reminderInterval) { _ in updateReminders() }
            }
            .padding()
            
            VStack {
                Text("Начало напоминаний")
                DatePicker("Начало", selection: $reminderStartTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: reminderStartTime) { newValue in
                        reminderStartTimeStr = formatter.string(from: newValue)
                        updateReminders()
                    }
                
                Text("Конец напоминаний")
                DatePicker("Конец", selection: $reminderEndTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: reminderEndTime) { newValue in
                        reminderEndTimeStr = formatter.string(from: newValue)
                        updateReminders()
                    }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadSavedTimes()
            requestNotificationPermission()
        }
    }

    func loadSavedTimes() {
        if let savedStart = formatter.date(from: reminderStartTimeStr) {
            reminderStartTime = savedStart
        } else {
            reminderStartTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        if let savedEnd = formatter.date(from: reminderEndTimeStr) {
            reminderEndTime = savedEnd
        } else {
            reminderEndTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted { updateReminders() }
        }
    }

    func updateReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        guard reminderEnabled else { return }
        
        var time = reminderStartTime
        let calendar = Calendar.current
        
        while time < reminderEndTime {
            let content = UNMutableNotificationContent()
            content.title = "Пора выпить воды!"
            content.body = "Не забывайте пить воду для здоровья 💧"
            content.sound = .default
            
            let triggerDate = calendar.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            
            time = calendar.date(byAdding: .hour, value: Int(reminderInterval), to: time) ?? time
        }
    }
}

struct WaterStatisticsView: View {
    @AppStorage("waterData") private var waterData: String = ""
    
    var history: [String: Double] {
        if let data = waterData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            return decoded
        }
        return [:]
    }
    
    var sortedHistory: [(String, Double)] {
        history.sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        VStack {
            Text("Статистика выпитой воды")
                .font(.largeTitle)
                .bold()
            
            Chart {
                ForEach(sortedHistory, id: \.0) { date, amount in
                    BarMark(
                        x: .value("Дата", date),
                        y: .value("Вода (мл)", amount)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .frame(height: 300)
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct WaterTrackerView: View {
    var body: some View {
        TabView {
            TrackerSettingsView()
                .tabItem {
                    Label("Трекер", systemImage: "drop.fill")
                }
            
            WaterReminderView()
                            .tabItem {
                                Label("Напоминания", systemImage: "alarm.fill")
                            }
            
            WaterStatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }
        }
    }
}

struct WaterTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        WaterTrackerView()
    }
}
