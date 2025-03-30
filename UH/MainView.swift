import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var currentDate = Date()
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
            ZStack {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 150)
                            .fill(Color.blue)
                            .frame(width: 430, height: 200)
                            .offset(y: -100)

                        HStack(spacing: 30) {
                            Button(action: {
                                changeDate(by: -1)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }

                            Text(formatDate(currentDate))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(width: 100, height: 60)
                                .foregroundStyle(Color.blue)
                                .background(.white)
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

                            Button(action: {
                                changeDate(by: 1)
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                        }
                        .padding(.top, -100)
                    }
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.blue)
                                .frame(width: 390, height: 300)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

                            VStack(alignment: .center, spacing: 10) {
                                Text("ПЛАН НА ДЕНЬ")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 10)

                                let startOfDay = Calendar.current.startOfDay(for: currentDate)
                                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

                                let todaysWorkouts = workouts.filter { workout in
                                    guard let workoutDate = workout.date else { return false }

                                    if workout.type == "Разовая" {
                                        return workoutDate >= startOfDay && workoutDate < endOfDay
                                    }

                                    if workout.type == "Ежедневная" {
                                        return true
                                    }

                                    return false
                                }

                                if todaysWorkouts.isEmpty {
                                    Text("Нет тренировок на сегодня")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                } else {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 10) {
                                            ForEach(todaysWorkouts, id: \.id) { workout in
                                                WorkoutCard(workout: workout)
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 200)
                                    .padding(.horizontal)
                                }
                            }
                            .padding()
                        }
                    }

                    VStack(spacing: 20) {
                        HStack {
                            NavigationLink(destination: VitaminGuideView()) {
                                Text("Витамины")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 170, height: 100)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }

                            NavigationLink(destination: WaterTrackerView()) {
                                Text("Трекер воды")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 170, height: 100)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                        }

                        HStack {
                            NavigationLink(destination: WaterTrackerView()) {
                                Text("Питание")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 170, height: 100)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }

                            NavigationLink(destination: CalendarView()) {
                                Text("Каледарь")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 170, height: 100)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            }
                        }
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func changeDate(by days: Int) {
        currentDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) ?? Date()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
