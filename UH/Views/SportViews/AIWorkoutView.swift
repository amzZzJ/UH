import SwiftUI

struct AIWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AIWorkoutViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Составление тренировки")
                .font(.title)
                .padding()
            
            TextField("Введите вашу цель", text: $viewModel.userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: viewModel.generateWorkoutPlan) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Подобрать упражнения")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(viewModel.isLoading || viewModel.userInput.isEmpty)
            
            if !viewModel.workoutPlans.isEmpty {
                Form {
                    Section(header: Text("Название тренировки")) {
                        TextField("Введите название", text: $viewModel.workoutName)
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
                    
                    Section(header: Text("Выберите упражнения")) {
                        ForEach(viewModel.workoutPlans.indices, id: \.self) { index in
                            HStack {
                                Button(action: {
                                    viewModel.toggleExerciseSelection(at: index)
                                }) {
                                    Image(systemName: viewModel.selectedExercises.contains(index) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(viewModel.selectedExercises.contains(index) ? .blue : .gray)
                                }
                                
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { viewModel.expandedPlans.contains(index) },
                                        set: { _ in viewModel.togglePlanExpansion(at: index) }
                                    ),
                                    content: {
                                        Text(viewModel.workoutPlans[index])
                                            .padding()
                                    },
                                    label: {
                                        Text("Упражнение \(index + 1)")
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    })
                            }
                        }
                    }
                }
            }
            
            if !viewModel.selectedExercises.isEmpty {
                Button("Сохранить тренировку") {
                    viewModel.saveWorkout()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        AddWorkoutView()
    }
}
