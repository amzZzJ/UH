import CoreData
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var username: String = UserDefaults.standard.string(forKey: "username") ?? "друг"
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func fetchTodaysWorkouts(_ workouts: FetchedResults<Workout>) -> [Workout] {
        let startOfDay = Calendar.current.startOfDay(for: currentDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return workouts.filter { workout in
            guard let workoutDate = workout.date else { return false }
            return workout.type == "Ежедневная" || (workoutDate >= startOfDay && workoutDate < endOfDay)
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
