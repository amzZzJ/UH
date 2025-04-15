import CoreData
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var username: String = UserDefaults.standard.string(forKey: "username") ?? "друг"

    private let weekdays = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func fetchTodaysWorkouts(_ workouts: FetchedResults<Workout>) -> [Workout] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let currentWeekday = calendar.component(.weekday, from: currentDate)
        
        return workouts.filter { workout in
            switch workout.type {
            case "Ежедневная":
                return true
                
            case "Еженедельная":
                guard let daysString = workout.dayOfWeek else { return false }
                let selectedDays = daysString.components(separatedBy: ",")
                
                let workoutWeekdays = selectedDays.compactMap { day -> Int? in
                    guard let index = weekdays.firstIndex(of: day) else { return nil }
                    return index + 1
                }
                
                return workoutWeekdays.contains(currentWeekday)
                
            case "Разовая":
                guard let workoutDate = workout.date else { return false }
                return workoutDate >= startOfDay && workoutDate < endOfDay
                
            default:
                return false
            }
        }
        .sorted { ($0.time ?? Date()) < ($1.time ?? Date()) }
    }

    func isWorkoutCompleted(_ workout: Workout) -> Bool {
        let key = "workout_\(workout.id?.uuidString ?? "default")"
        return UserDefaults.standard.bool(forKey: key)
    }

    func toggleWorkoutCompletion(_ workout: Workout, isCompleted: Bool) {
        let key = "workout_\(workout.id?.uuidString ?? "default")"
        UserDefaults.standard.set(isCompleted, forKey: key)
        objectWillChange.send()
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
