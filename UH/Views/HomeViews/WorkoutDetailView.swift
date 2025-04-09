import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @State private var expandedExercise: Exercise?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(workout.name ?? "Без названия")
                    .foregroundColor(.orange)
                    .font(.largeTitle)
                    .fontWeight(.bold)
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

                    VStack(spacing: 10) {
                        ForEach(exercises.sorted { $0.name ?? "" < $1.name ?? "" }, id: \.self) { exercise in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(exercise.name ?? "Без названия")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(expandedExercise == exercise ? nil : 1)
                                        .truncationMode(.tail)

                                    Button(action: {
                                        withAnimation {
                                            expandedExercise = expandedExercise == exercise ? nil : exercise
                                        }
                                    }) {
                                        Image(systemName: expandedExercise == exercise ? "chevron.up" : "chevron.down")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                } else {
                    Text("Нет упражнений")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
        }
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
