import SwiftUI
import Combine
import CoreData

class WaterTrackerViewModel: ObservableObject {
    @Published var dailyGoal: Double = 2000
    @Published var currentIntake: Double = 0
    @Published var progress: Double = 0
    @Published var weeklyData: [DayWaterData] = []
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        setupDayChangeObserver()
        loadTodayData()
    }
    
    func setGoal(_ goal: Double) {
        dailyGoal = goal
        updateTodayRecord()
        updateProgress()
    }
    
    func addWater(_ amount: Double) {
        currentIntake += amount
        updateTodayRecord()
        updateProgress()
    }
    
    func reset() {
        currentIntake = 0
        updateTodayRecord()
        updateProgress()
    }
    
    func loadWeeklyData() {
        let fetchRequest: NSFetchRequest<WaterIntake> = WaterIntake.fetchRequest()
            
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else { return }
            
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
            
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WaterIntake.date, ascending: true)]
            
        do {
            let results = try context.fetch(fetchRequest)
                
            let grouped = Dictionary(grouping: results) { (intake) -> Date in
                calendar.startOfDay(for: intake.date ?? Date())
            }

            var data: [DayWaterData] = []
                
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
                    
                let dayIntakes = grouped[date] ?? []
                
                let totalIntake: Double
                let goal: Double
                
                if dayIntakes.isEmpty {
                    totalIntake = 0
                    goal = 200
                } else {
                    totalIntake = dayIntakes.reduce(0) { $0 + ($1.amount) }
                    goal = dayIntakes.first?.goal ?? self.dailyGoal
                }
                
                data.append(DayWaterData(
                    date: date,
                    intake: totalIntake,
                    goal: goal
                ))
            }


            weeklyData = data.sorted { $0.date > $1.date }
                
        } catch {
            print("Error fetching weekly data: \(error.localizedDescription)")
            weeklyData = []
        }
    }
    
    private func updateTodayRecord() {
        let request: NSFetchRequest<WaterIntake> = WaterIntake.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        
        request.predicate = NSPredicate(format: "date >= %@", today as NSDate)
        request.fetchLimit = 1
        
        do {
            let record = try context.fetch(request).first ?? WaterIntake(context: context)
            record.date = today
            record.goal = dailyGoal
            record.amount = currentIntake
            saveContext()
        } catch {
            print("Ошибка обновления записи:", error)
        }
    }
    
    private func updateProgress() {
        progress = min(currentIntake / dailyGoal, 1.0)
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения:", error)
        }
    }
    
    private func setupDayChangeObserver() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkForNewDay()
            }
            .store(in: &cancellables)

        checkForNewDay()
    }

    private func resetDailyData() {
        currentIntake = 0
        UserDefaults.standard.set(Date(), forKey: "lastWaterUpdateDate")
        saveCurrentState()
    }
    
    func checkForNewDay() {
        let calendar = Calendar.current
        let lastUpdateDate = UserDefaults.standard.object(forKey: "lastWaterUpdateDate") as? Date ?? Date()

        if !calendar.isDate(lastUpdateDate, inSameDayAs: Date()) {
            resetDailyData()
        }
    }
    
    private func loadTodayData() {
        let today = Calendar.current.startOfDay(for: Date())
        let request: NSFetchRequest<WaterIntake> = WaterIntake.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", today as NSDate)
        
        do {
            if let todayRecord = try context.fetch(request).first {
                currentIntake = todayRecord.amount
                dailyGoal = todayRecord.goal
            }
        } catch {
            print("Ошибка загрузки данных:", error)
        }
    }
    
    func saveCurrentState() {
        let today = Calendar.current.startOfDay(for: Date())
        let request: NSFetchRequest<WaterIntake> = WaterIntake.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", today as NSDate)
        
        do {
            let record = try context.fetch(request).first ?? WaterIntake(context: context)
            record.date = today
            record.amount = currentIntake
            record.goal = dailyGoal
            try context.save()
        } catch {
            print("Ошибка сохранения:", error)
        }
    }
}
