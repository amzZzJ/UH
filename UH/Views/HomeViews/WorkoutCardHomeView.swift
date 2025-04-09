import SwiftUI

struct WorkoutCardHomeView: View {
    var workout: Workout
    @Binding var isChecked: Bool
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
                    isChecked.toggle()
                }) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isChecked ? .orange : .white)
                            .font(.system(size: 24))
                            .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.blue)
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
