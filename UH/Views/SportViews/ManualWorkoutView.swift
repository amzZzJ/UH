import SwiftUI
import CoreData

struct ManualWorkoutView: View {
    @StateObject private var viewModel = ManualWorkoutViewModel()
    @Binding var isPresented: Bool
    
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.weekdays, id: \.self) { day in
                                Circle()
                                    .fill(viewModel.selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(day)
                                            .foregroundColor(.white)
                                    )
                                    .onTapGesture {
                                        viewModel.toggleDay(day)
                                    }
                            }
                        }
                        .padding(.vertical, 5)
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
                isPresented = false
            }
        }
    }
}
