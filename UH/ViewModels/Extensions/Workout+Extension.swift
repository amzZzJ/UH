import Foundation

extension Workout {
    func shouldAppear(on date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch self.type {
        case "Разовая":
            return self.date != nil && calendar.isDate(self.date!, inSameDayAs: date)
            
        case "Ежедневная":
            return true
            
        case "Еженедельная":
            guard let daysOfWeek = self.daysOfWeek else { return false }
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "E"
            
            let weekdayString = formatter.string(from: date)
            return daysOfWeek.contains(weekdayString.prefix(2))
            
        default:
            return false
        }
    }
}
