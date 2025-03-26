import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var showTasks = false
    @State private var showWorkoutScreen = false
    @State private var workouts: [Workout] = []
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        showTasks.toggle()
                    }
                
                Button("Тренировки") {
                    showWorkoutScreen.toggle()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showWorkoutScreen) {
                    WorkoutView { newWorkout in
                        workouts.append(newWorkout)
                    }
                }
            }
            .navigationTitle("Календарь")
            .sheet(isPresented: $showTasks) {
                TaskListView(date: selectedDate, workouts: workouts)
            }
        }
    }
}

struct TaskListView: View {
    let date: Date
    let workouts: [Workout]
    
    var body: some View {
        VStack {
            Text("Список дел на \(formattedDate(date))")
                .font(.headline)
                .padding()
            
            List {
                ForEach(workouts.filter { $0.shouldAppear(on: date) }, id: \..id) { workout in
                    VStack(alignment: .leading) {
                        Text(workout.name).font(.headline)
                        Text(workout.description).font(.subheadline)
                        Text("Время: \(workout.time, formatter: timeFormatter)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Text("Упражнения:")
                            .font(.headline)
                        ForEach(workout.exercises, id: \..self) { exercise in
                            Text("• \(exercise)")
                        }
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct WorkoutView: View {
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
    var onSave: (Workout) -> Void
    
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
                        ForEach(workoutTypes, id: \..self) { type in
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
                            ForEach(weekdays, id: \..self) { day in
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
                
                Button("Добавить тренировку") {
                    let newWorkout = Workout(id: UUID(), name: workoutName, description: workoutDescription, type: workoutType, date: selectedDate, daysOfWeek: selectedDays, time: selectedTime, exercises: exercises)
                    onSave(newWorkout)
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Добавить тренировку")
        }
    }
}

struct Workout: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let type: String
    let date: Date
    let daysOfWeek: Set<String>
    let time: Date
    let exercises: [String]
    
    func shouldAppear(on date: Date) -> Bool {
        let calendar = Calendar.current
        switch type {
        case "Разовая":
            return calendar.isDate(self.date, inSameDayAs: date)
        case "Ежедневная":
            return true
        case "Еженедельная":
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "E"
            let weekdayString = weekdayFormatter.string(from: date)
            return daysOfWeek.contains(String(weekdayString.prefix(2)))
        default:
            return false
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
