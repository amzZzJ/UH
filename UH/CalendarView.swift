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



struct WorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var workoutName = ""
    @State private var workoutDescription = ""
    @State private var workoutType = "Разовая"
    @State private var selectedDate = Date()
    @State private var selectedDays: Set<String> = []
    @State private var selectedTime = Date()
    @State private var exercises: [String] = []
    @State private var newExercise = ""
    
    let workoutTypes = ["Разовая", "Еженедельная", "Ежедневная"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название тренировки")) {
                    TextField("Введите название", text: $workoutName)
                }
                
                Section(header: Text("Описание")) {
                    TextField("Введите описание", text: $workoutDescription)
                }
                
                Section(header: Text("Тип тренировки")) {
                    Picker("Выберите тип", selection: $workoutType) {
                        ForEach(workoutTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if workoutType == "Разовая" {
                    Section(header: Text("Дата")) {
                        DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                    }
                } else if workoutType == "Еженедельная" {
                    Section(header: Text("Выберите дни недели")) {
                        HStack {
                            ForEach(weekdays, id: \.self) { day in
                                Button(action: {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                }) {
                                    Text(day)
                                        .padding()
                                        .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Время")) {
                    DatePicker("Выберите время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Упражнения")) {
                    HStack {
                        TextField("Введите упражнение", text: $newExercise)
                        Button("Добавить") {
                            if !newExercise.isEmpty {
                                exercises.append(newExercise)
                                newExercise = ""
                            }
                        }
                    }

                    List {
                        ForEach(exercises, id: \..self) { exercise in
                            HStack {
                                Text(exercise)
                                Spacer()
                            Button(action: {
                                    exercises.removeAll { $0 == exercise }
                            }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                Button("Сохранить") {
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
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Добавить тренировку")
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
