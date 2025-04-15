import SwiftUI
import CoreData
import EventKit

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var calendarManager = CalendarManager()
    @State private var completedEvents: Set<String> = []
    
    init() {
        let context = CoreDataManager.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }
    
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Workout.time, ascending: true),
            NSSortDescriptor(keyPath: \Workout.date, ascending: true)
        ]
    ) var workouts: FetchedResults<Workout>

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 15) {
                HomeHeaderView(currentDate: $viewModel.currentDate)

                let todaysItems = combinedTodaysItems()
                
                if todaysItems.isEmpty {
                    Text("Сегодня нет событий")
                        .font(.title)
                        .foregroundColor(.orange)
                        .padding(.top, 10)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(todaysItems) { item in
                                if let workout = item.value as? Workout {
                                    WorkoutCardHomeView(
                                        workout: workout,
                                        isChecked: Binding(
                                            get: { viewModel.isWorkoutCompleted(workout) },
                                            set: { viewModel.toggleWorkoutCompletion(workout, isCompleted: $0) }
                                        )
                                    )
                                } else if let event = item.value as? EKEvent {
                                    CalendarEventHomeView(
                                        event: event,
                                        isChecked: Binding(
                                            get: { completedEvents.contains(event.eventIdentifier) },
                                            set: { isCompleted in
                                                if isCompleted {
                                                    completedEvents.insert(event.eventIdentifier)
                                                } else {
                                                    completedEvents.remove(event.eventIdentifier)
                                                }
                                            }
                                        )
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 35)
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                calendarManager.requestAccess()
                calendarManager.loadEvents(for: viewModel.currentDate)
                loadCompletedEvents()
            }
            .onChange(of: viewModel.currentDate) { newDate in
                calendarManager.loadEvents(for: newDate)
            }
        }
    }

    private func loadCompletedEvents() {
        if let savedEvents = UserDefaults.standard.array(forKey: "completedEvents") as? [String] {
            completedEvents = Set(savedEvents)
        }
    }
    
    private func combinedTodaysItems() -> [AnyIdentifiable] {
        let todaysWorkouts = viewModel.fetchTodaysWorkouts(workouts)
        let todaysEvents = calendarManager.events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: viewModel.currentDate)
        }

        let combined = (todaysWorkouts as [Any]) + (todaysEvents as [Any])
        
        return combined
            .sorted {
                let date1 = ($0 as? Workout)?.time ?? ($0 as? EKEvent)?.startDate ?? Date.distantPast
                let date2 = ($1 as? Workout)?.time ?? ($1 as? EKEvent)?.startDate ?? Date.distantPast
                return date1 < date2
            }
            .map { AnyIdentifiable($0) }
    }
}
