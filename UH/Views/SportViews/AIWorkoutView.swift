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
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        viewModel.toggleExerciseSelection(at: index)
                                    }) {
                                        Image(systemName: viewModel.selectedExercises.contains(index) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(viewModel.selectedExercises.contains(index) ? .blue : .gray)
                                            .font(.system(size: 22))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("Упражнение \(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.togglePlanExpansion(at: index)
                                    }) {
                                        Image(systemName: viewModel.expandedPlans.contains(index) ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.togglePlanExpansion(at: index)
                                }
                                
                                if viewModel.expandedPlans.contains(index) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Divider()
                                        
                                        Text(viewModel.workoutPlans[index])
                                            .font(.body)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.expandedPlans.contains(index))
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
