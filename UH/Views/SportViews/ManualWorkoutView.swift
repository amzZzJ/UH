import SwiftUI

struct ManualWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ManualWorkoutViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Название тренировки")) {
                TextField("Введите название", text: $viewModel.workoutName)
            }
            
            Section(header: Text("Описание")) {
                TextField("Введите описание", text: $viewModel.workoutDescription)
            }
            
            Section(header: Text("Тип тренировки")) {
                Picker("Выберите тип", selection: $viewModel.workoutType) {
                    ForEach(viewModel.workoutTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            if viewModel.workoutType == "Разовая" {
                Section(header: Text("Дата")) {
                    DatePicker("Выберите дату",
                              selection: $viewModel.selectedDate,
                              displayedComponents: .date)
                }
            } else if viewModel.workoutType == "Еженедельная" {
                Section(header: Text("Выберите дни недели")) {
                    HStack {
                        ForEach(viewModel.weekdays, id: \.self) { day in
                            Button(action: {
                                viewModel.toggleDay(day)
                            }) {
                                Text(day)
                                    .padding()
                                    .background(viewModel.selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Время")) {
                DatePicker("Выберите время",
                         selection: $viewModel.selectedTime,
                         displayedComponents: .hourAndMinute)
            }
            
            Section(header: Text("Упражнения")) {
                HStack {
                    TextField("Введите упражнение", text: $viewModel.newExercise)
                    Button("Добавить") {
                        viewModel.addExercise()
                    }
                }
                
                ForEach(viewModel.exercises.indices, id: \.self) { index in
                    HStack {
                        Text(viewModel.exercises[index])
                        Spacer()
                        Button(action: {
                            viewModel.removeExercise(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Button("Сохранить") {
                viewModel.saveWorkout()
                dismiss()
            }
        }
    }
}
