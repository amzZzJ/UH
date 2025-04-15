import SwiftUI

struct AIWorkoutView: View {
    @Binding var isPresented: Bool
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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.weekdays, id: \.self) { day in
                                        Button(action: {
                                            viewModel.toggleDay(day)
                                        }) {
                                            Circle()
                                                .fill(viewModel.selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text(day)
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 14))
                                        )}
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
                    
                    Section(header: Text("Выберите упражнения")) {
                        ForEach(viewModel.workoutPlans.indices, id: \.self) { index in
                            ExerciseRowView(
                                index: index,
                                content: viewModel.workoutPlans[index],
                                isSelected: viewModel.selectedExercises.contains(index),
                                isExpanded: viewModel.expandedPlans.contains(index),
                                toggleSelection: { viewModel.toggleExerciseSelection(at: index) },
                                toggleExpansion: { viewModel.togglePlanExpansion(at: index) }
                            )
                        }
                    }
                }
            }
            
            if !viewModel.selectedExercises.isEmpty {
                Button("Сохранить тренировку") {
                    viewModel.saveWorkout()
                    isPresented = false
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
