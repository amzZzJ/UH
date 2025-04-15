import SwiftUI

import UserNotifications

struct WorkoutCardView: View {
    var workout: Workout
    @State private var showWorkoutDetail = false
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.name ?? "Без названия")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(workout.descriptionText ?? "Нет описания")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let time = workout.time {
                        HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.white)
                                
                                Text("\(formattedTime(time))")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                    }
                }
                Spacer()

                Button(action: {
                    removeNotifications(for: workout)
                    let context = CoreDataManager.shared.context
                    context.delete(workout)
                    CoreDataManager.shared.save()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal)
            .onTapGesture {
                showWorkoutDetail.toggle()
            }
            .sheet(isPresented: $showWorkoutDetail) {
                WorkoutDetailView(workout: workout)
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

func removeNotifications(for workout: Workout) {
    let center = UNUserNotificationCenter.current()
    
    guard let id = workout.id?.uuidString else { return }
    
    let workoutPrefix = "workout_"
    let baseIdentifier = workoutPrefix + id
    
    center.getPendingNotificationRequests { requests in
        var identifiersToRemove = [String]()
        
        for request in requests {
            if request.identifier == baseIdentifier ||
               request.identifier.hasPrefix("\(baseIdentifier)_") {
                identifiersToRemove.append(request.identifier)
            }
        }
        
        if let daysString = workout.dayOfWeek {
            let days = daysString.components(separatedBy: ",")
            for day in days {
                if let index = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"].firstIndex(of: day) {
                    let weekday = index + 2
                    identifiersToRemove.append("\(baseIdentifier)_\(weekday)")
                }
            }
        }
        
        let uniqueIdentifiers = Array(Set(identifiersToRemove))
        
        if !uniqueIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: uniqueIdentifiers)
            print("Удалены уведомления для тренировки: \(uniqueIdentifiers)")
        }
    }
}
