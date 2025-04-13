import EventKit

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var accessGranted = false
    
    func requestAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.accessGranted = granted
                if granted {
                    self?.loadEvents()
                }
            }
        }
    }
    
    func loadEvents(for date: Date = Date()) {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        events = eventStore.events(matching: predicate)
    }
}
