import SwiftUI

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedDate = Date()
    @State private var showWorkoutScreen = false
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [
                NSSortDescriptor(keyPath: \Workout.time, ascending: true),
                NSSortDescriptor(keyPath: \Workout.date, ascending: true)
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

                        ForEach(workouts.filter { workout in workout.shouldAppear(on: selectedDate) }) { workout in
                            WorkoutCard(workout: workout)
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
                    WorkoutView()
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

struct WorkoutCard: View {
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
                    let context = CoreDataManager.shared.context
                    context.delete(workout)
                    CoreDataManager.shared.save()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background((workout.type ?? "") == "Ежедневная" ? Color.blue : Color.orange)
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


struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(workout.name ?? "Без названия")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 5)

            Text(workout.descriptionText ?? "Нет описания")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.bottom, 10)

            HStack {
                Text("Тип:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(workout.type ?? "Не указан")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 10)

            if let time = workout.time {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("\(formattedTime(time))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
            }

            if let exercises = workout.exercises as? Set<Exercise>, !exercises.isEmpty {
                Text("Упражнения:")
                    .font(.headline)
                    .padding(.top)

                ForEach(exercises.sorted { $0.name ?? "" < $1.name ?? "" }, id: \.self) { exercise in
                    HStack {
                        Text("• \(exercise.name ?? "Без названия")")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.bottom, 5)
                }
            } else {
                Text("Нет упражнений")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding([.top, .horizontal])
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
