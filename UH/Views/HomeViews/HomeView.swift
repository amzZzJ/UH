import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HomeViewModel
    
    init() {
        let context = CoreDataManager.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }
    
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Workout.time, ascending: true),
            NSSortDescriptor(keyPath: \Workout.date, ascending: true)
        ]
    ) var workouts: FetchedResults<Workout>

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 15) {
                HomeHeaderView(username: $viewModel.username, currentDate: $viewModel.currentDate)

                let todaysWorkouts = viewModel.fetchTodaysWorkouts(workouts)

                if todaysWorkouts.isEmpty {
                    Text("Сегодня нет тренировок")
                        .font(.title)
                        .foregroundColor(.orange)
                        .padding(.top, 10)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(todaysWorkouts, id: \.id) { workout in
                                WorkoutCardHomeView(
                                    workout: workout,
                                    isChecked: Binding(
                                        get: {
                                            viewModel.isWorkoutCompleted(workout)
                                        },
                                        set: { newValue in
                                            viewModel.toggleWorkoutCompletion(workout, isCompleted: newValue)
                                        }
                                    )
                                )
                            }
                        }
                    }
                    .padding(.top, 35)
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
