import Foundation
import CoreData
import UserNotifications

class ManualWorkoutViewModel: ObservableObject {
    @Published var workoutName = ""
    @Published var workoutDescription = ""
    @Published var workoutType = "Разовая"
    @Published var selectedDate = Date()
    @Published var selectedDays: [String] = []
    @Published var selectedTime = Date()
    @Published var exercises: [String] = []
    @Published var newExercise = ""
    
    let workoutTypes = ["Разовая", "Еженедельная", "Ежедневная"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    
    func addExercise() {
        if !newExercise.isEmpty {
            exercises.append(newExercise)
            newExercise = ""
        }
    }
    
    func removeExercise(at index: Int) {
        exercises.remove(at: index)
    }
    
    func toggleDay(_ day: String) {
        if let index = selectedDays.firstIndex(of: day) {
            selectedDays.remove(at: index)
        } else {
            selectedDays.append(day)
        }
    }
    
    func saveWorkout() {
        let context = CoreDataManager.shared.context
        let newWorkout = Workout(context: context)
        
        newWorkout.id = UUID()
        newWorkout.name = workoutName
        newWorkout.descriptionText = workoutDescription
        newWorkout.type = workoutType
        newWorkout.time = selectedTime
        
        if workoutType == "Разовая" {
            newWorkout.date = selectedDate
        } else if workoutType == "Еженедельная" {
            newWorkout.dayOfWeek = selectedDays.joined(separator: ",")
            if let firstDay = selectedDays.first,
               let nextDate = nextDateFor(day: firstDay) {
                newWorkout.date = nextDate
            }
        }
        
        for exerciseName in exercises {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = exerciseName
            newWorkout.addToExercises(exercise)
        }
        
        CoreDataManager.shared.save()
        scheduleNotification(for: newWorkout)
    }
    
    private func nextDateFor(day: String) -> Date? {
        guard let weekdayIndex = weekdays.firstIndex(of: day) else { return nil }
        let desiredWeekday = weekdayIndex + 1
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentWeekday = calendar.component(.weekday, from: today)
        
        var daysToAdd = desiredWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)
    }
    
    private func addExercises(to workout: Workout, context: NSManagedObjectContext) {
        for exerciseName in exercises {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = exerciseName
            workout.addToExercises(exercise)
        }
    }
    
    private func scheduleNotification(for workout: Workout) {
        let content = UNMutableNotificationContent()
        content.title = "Напоминание: \(workout.name ?? "Без названия")"
        content.body = "Тренировка начнётся через 30 минут!"
        content.sound = .default

        let calendar = Calendar.current
        let prefix = "workout_"
        let id = prefix + (workout.id?.uuidString ?? UUID().uuidString)

        switch workout.type {
        case "Разовая":
            if let date = workout.date, let time = workout.time {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                if let fullDate = calendar.date(from: dateComponents),
                   let finalDate = calendar.date(byAdding: .minute, value: -30, to: fullDate) {
                    
                    let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                }
            }

        case "Еженедельная":
            guard let dayOfWeek = workout.dayOfWeek?.components(separatedBy: ",") else { return }

            for day in dayOfWeek {
                if let index = weekdays.firstIndex(of: day) {
                    var weekday = index + 2
                    if weekday > 7 { weekday = 1 }
                    
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: workout.time ?? Date())
                    
                    if let dateFromTime = calendar.date(from: timeComponents),
                       let adjustedTime = calendar.date(byAdding: .minute, value: -30, to: dateFromTime) {
                        
                        let adjustedComponents = calendar.dateComponents([.hour, .minute], from: adjustedTime)
                        var dateComponents = DateComponents()
                        dateComponents.weekday = weekday
                        dateComponents.hour = adjustedComponents.hour
                        dateComponents.minute = adjustedComponents.minute
                        
                        let request = UNNotificationRequest(
                            identifier: "\(id)_\(weekday)",
                            content: content,
                            trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        )
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }

        case "Ежедневная":
            var timeComponents = calendar.dateComponents([.hour, .minute], from: workout.time ?? Date())
            if let dateFromTime = calendar.date(from: timeComponents),
               let adjustedTime = calendar.date(byAdding: .minute, value: -30, to: dateFromTime) {
                
                let adjustedComponents = calendar.dateComponents([.hour, .minute], from: adjustedTime)
                var dateComponents = DateComponents()
                dateComponents.hour = adjustedComponents.hour
                dateComponents.minute = adjustedComponents.minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }

        default:
            break
        }
    }

}
