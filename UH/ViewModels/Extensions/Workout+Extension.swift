import Foundation

extension Workout {
    func shouldAppear(on date: Date) -> Bool {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        
        switch self.type {
        case "Ежедневная":
            return true
            
        case "Еженедельная":
            guard let daysString = self.dayOfWeek else { return false }
            let selectedDays = daysString.components(separatedBy: ",")
            
            let workoutWeekdays = selectedDays.compactMap { day -> Int? in
                guard let index = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"].firstIndex(of: day) else { return nil }
                return index + 2
            }
            
            return workoutWeekdays.contains(currentWeekday)
            
        case "Разовая":
            guard let workoutDate = self.date else { return false }
            return calendar.isDate(workoutDate, inSameDayAs: date)
            
        default:
            return false
        }
    }
}
