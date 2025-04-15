import SwiftUI
import EventKit

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedDate = Date()
    @State private var showWorkoutScreen = false
    @State private var calendarHeight: CGFloat = 350
    
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Workout.date, ascending: true),
            NSSortDescriptor(keyPath: \Workout.time, ascending: true)
        ]
    ) var workouts: FetchedResults<Workout>
    
    private var combinedEvents: [Any] {
        let calendarEvents = calendarManager.events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: selectedDate)
        }
        
        return (calendarEvents as [Any] + filteredWorkouts as [Any])
            .sorted {
                let date1 = ($0 as? EKEvent)?.startDate ?? (($0 as? Workout)?.time ?? Date.distantPast)
                let date2 = ($1 as? EKEvent)?.startDate ?? (($1 as? Workout)?.time ?? Date.distantPast)
                return date1 < date2
            }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                let customOrange = Color(red: 1.0, green: 0.65, blue: 0.0)
                DatePicker("",
                          selection: $selectedDate,
                          displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(height: calendarHeight)
                    .padding(.horizontal)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .accentColor(customOrange)
                    .onAppear {
                        let brightOrange = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
                        if #available(iOS 16.0, *) {
                            UIDatePicker.appearance().tintColor = brightOrange
                        }
                        

                        UILabel.appearance(whenContainedInInstancesOf: [UIDatePicker.self]).textColor = brightOrange
                        
                        UIView.appearance(whenContainedInInstancesOf: [UIDatePicker.self]).tintColor = brightOrange
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height > 0 {
                                    calendarHeight = max(250, calendarHeight - 50)
                                } else {
                                    calendarHeight = min(400, calendarHeight + 50)
                                }
                            }
                    )
                
                Text(formattedDate(selectedDate))
                    .font(.title3.bold())
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(combinedEvents.indices, id: \.self) { index in
                            if let event = combinedEvents[index] as? EKEvent {
                                CalendarEventView(event: event)
                            } else if let workout = combinedEvents[index] as? Workout {
                                                WorkoutCardView(workout: workout)
                            }
                        }
                                        
                        if combinedEvents.isEmpty {
                            Text("Нет событий на \(formattedDate(selectedDate))")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding(.top, 8)
                }
                
                Button(action: { showWorkoutScreen.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.orange)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                .padding(.bottom, 20)
                .offset(y: -10)
            }
            .sheet(isPresented: $showWorkoutScreen) {
                AddWorkoutView(isPresented: $showWorkoutScreen)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                calendarManager.requestAccess()
            }
            .onChange(of: selectedDate) { newDate in
                calendarManager.loadEvents(for: newDate)
            }
            .alert("Доступ к календарю",
                   isPresented: .constant(!calendarManager.accessGranted && calendarManager.events.isEmpty),
                   actions: {
                Button("Настройки") {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                Button("Отмена", role: .cancel) {}
            }, message: {
                Text("Разрешите доступ для просмотра событий календаря")
            })
        }
    }
    
    private var filteredWorkouts: [Workout] {
        let result = workouts.filter { $0.shouldAppear(on: selectedDate) }
            .sorted { ($0.time ?? Date()) < ($1.time ?? Date()) }

        return result
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

