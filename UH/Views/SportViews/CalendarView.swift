import SwiftUI

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedDate = Date()
    @State private var showWorkoutScreen = false
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [
                NSSortDescriptor(keyPath: \Workout.date, ascending: true),
                NSSortDescriptor(keyPath: \Workout.time, ascending: true)
            ]
    ) var workouts: FetchedResults<Workout>

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(height: 400)
                    .padding()

                ScrollView {
                    VStack(alignment: .leading) {
                        Text("\(formattedDate(selectedDate))")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(workouts.filter { workout in workout.shouldAppear(on: selectedDate) }
                            .sorted { ($0.time ?? Date()) < ($1.time ?? Date()) }
                        ) { workout in
                            WorkoutCardView(workout: workout)
                        }
                    }
                }

                Button(action: { showWorkoutScreen.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                        .padding()
                }
                .sheet(isPresented: $showWorkoutScreen) {
                    AddWorkoutView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }
}

private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMMM"
    return formatter.string(from: date)
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
