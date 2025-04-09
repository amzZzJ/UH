import Foundation
import CoreData

class ManualWorkoutViewModel: ObservableObject {
    @Published var workoutName = ""
    @Published var workoutDescription = ""
    @Published var workoutType = "Разовая"
    @Published var selectedDate = Date()
    @Published var selectedDays: Set<String> = []
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
    
    func saveWorkout() {
        let context = CoreDataManager.shared.context
        let newWorkout = Workout(context: context)
        
        newWorkout.id = UUID()
        newWorkout.name = workoutName
        newWorkout.descriptionText = workoutDescription
        newWorkout.type = workoutType
        newWorkout.date = selectedDate
        newWorkout.time = selectedTime
        newWorkout.daysOfWeek = selectedDays.joined(separator: ",")
        
        for exerciseName in exercises {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = exerciseName
            newWorkout.addToExercises(exercise)
        }
        
        CoreDataManager.shared.save()
    }
}

extension ManualWorkoutViewModel {
    func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
