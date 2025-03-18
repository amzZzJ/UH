import SwiftUI
import EventKit

struct MainView: View {
    @State private var currentDate = Date()
    @State private var events: [EKEvent] = []
    private let eventStore = EKEventStore()
    
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
                                .multilineTextAlignment(.center)
                            
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
                                
                                if events.isEmpty {
                                    Text("Нет событий")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                } else {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 10) {
                                            ForEach(events, id: \.eventIdentifier) { event in
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text(event.title ?? "Без названия")
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                        Text(event.startDate, style: .time)
                                                            .font(.subheadline)
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }
                                                    Spacer()
                                                }
                                                .padding(10)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(10)
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
                        
                        NavigationLink(destination: WorkoutPlanView()) {
                            Text("Тренировки")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 170, height: 100)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.top, 20)
                    
                    HStack {
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
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    requestAccessAndLoadEvents()
                }
                .onChange(of: currentDate) { _ in
                    loadEvents(for: currentDate)
                }
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

    private func requestAccessAndLoadEvents() {
        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted {
                loadEvents(for: currentDate)
            } else {
                print("Доступ к календарю не разрешен")
            }
        }
    }

    private func loadEvents(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        events = eventStore.events(matching: predicate)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
