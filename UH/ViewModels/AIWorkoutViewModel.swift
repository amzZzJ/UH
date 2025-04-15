import Foundation
import Combine
import CoreData
import UserNotifications

class AIWorkoutViewModel: ObservableObject {
    @Published var workoutName: String = ""
    @Published var workoutType: String = "Разовая"
    @Published var selectedDate: Date = Date()
    @Published var selectedTime: Date = Date()
    @Published var selectedDays: Set<String> = []
    @Published var userInput: String = ""
    @Published var workoutPlans: [String] = []
    @Published var expandedPlans: Set<Int> = []
    @Published var isLoading: Bool = false
    @Published var selectedExercises: Set<Int> = []
    
    private let oauthToken: String
    private let folderId: String
    private let apiUrl: String
    private var iamToken: String?
    private var cancellables = Set<AnyCancellable>()
    
    let workoutTypes = ["Разовая", "Еженедельная", "Ежедневная"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    
    init(oauthToken: String = Config.OAUTH_TOKEN,
         folderId: String = Config.FOLDER_ID,
         apiUrl: String = Config.API_URL) {
        self.oauthToken = oauthToken
        self.folderId = folderId
        self.apiUrl = apiUrl
    }
    
    private func scheduleNotification(for workout: Workout) {
        let content = UNMutableNotificationContent()
        content.title = "Скоро тренировка: \(workout.name ?? "Без названия")"
        content.body = "Тренировка начнётся через 30 минут!"
        content.sound = .default

        let calendar = Calendar.current
        let prefix = "workout_"
        let id = prefix + (workout.id?.uuidString ?? UUID().uuidString)

        switch workout.type {
        case "Разовая":
            if let date = workout.date, let time = workout.time {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute

                if let fullDate = calendar.date(from: dateComponents),
                   let finalDate = calendar.date(byAdding: .minute, value: -30, to: fullDate) {

                    let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                }
            }

        case "Еженедельная":
            let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
            guard let dayOfWeek = workout.dayOfWeek?.components(separatedBy: ",") else { return }

            for day in dayOfWeek {
                if let index = weekdays.firstIndex(of: day) {
                    var weekday = index + 2
                    if weekday > 7 { weekday = 1 } // Вс = 1

                    let timeComponents = calendar.dateComponents([.hour, .minute], from: workout.time ?? Date())

                    if let dateFromTime = calendar.date(from: timeComponents),
                       let adjustedTime = calendar.date(byAdding: .minute, value: -30, to: dateFromTime) {

                        let adjustedComponents = calendar.dateComponents([.hour, .minute], from: adjustedTime)
                        var dateComponents = DateComponents()
                        dateComponents.weekday = weekday
                        dateComponents.hour = adjustedComponents.hour
                        dateComponents.minute = adjustedComponents.minute

                        let request = UNNotificationRequest(
                            identifier: "\(id)_\(weekday)",
                            content: content,
                            trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        )
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }

        case "Ежедневная":
            let timeComponents = calendar.dateComponents([.hour, .minute], from: workout.time ?? Date())
            if let dateFromTime = calendar.date(from: timeComponents),
               let adjustedTime = calendar.date(byAdding: .minute, value: -30, to: dateFromTime) {

                let adjustedComponents = calendar.dateComponents([.hour, .minute], from: adjustedTime)
                var dateComponents = DateComponents()
                dateComponents.hour = adjustedComponents.hour
                dateComponents.minute = adjustedComponents.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }

        default:
            break
        }
    }

    
    func togglePlanExpansion(at index: Int) {
        if expandedPlans.contains(index) {
            expandedPlans.remove(index)
        } else {
            expandedPlans.insert(index)
        }
    }
    
    func toggleExerciseSelection(at index: Int) {
        if selectedExercises.contains(index) {
            selectedExercises.remove(index)
        } else {
            selectedExercises.insert(index)
        }
    }
    
    func saveWorkout() {
        let context = CoreDataManager.shared.context
        let newWorkout = Workout(context: context)
        
        newWorkout.id = UUID()
        newWorkout.name = workoutName.isEmpty ? "Тренировка с ИИ" : workoutName
        newWorkout.descriptionText = "Автоматически подобранные упражнения"
        newWorkout.type = workoutType
        newWorkout.date = selectedDate
        newWorkout.time = selectedTime
        newWorkout.dayOfWeek = selectedDays.joined(separator: ",")
        
        for index in selectedExercises {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = workoutPlans[index]
            newWorkout.addToExercises(exercise)
        }
        
        CoreDataManager.shared.save()
        scheduleNotification(for: newWorkout)
    }
    
    func generateWorkoutPlan() {
        guard !userInput.isEmpty else {
            workoutPlans = ["Пожалуйста, введите цель."]
            return
        }
        
        isLoading = true
        
        fetchIAMToken()
            .flatMap { [weak self] token -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                self.iamToken = token
                return self.fetchWorkoutPlan(for: self.userInput, iamToken: token)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.workoutPlans = ["Ошибка: \(error.localizedDescription)"]
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.workoutPlans = self.parseWorkouts(from: response)
            }
            .store(in: &cancellables)
    }
    
    private func fetchIAMToken() -> AnyPublisher<String, Error> {
        let url = URL(string: "https://iam.api.cloud.yandex.net/iam/v1/tokens")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "yandexPassportOauthToken": oauthToken
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: IAMTokenResponse.self, decoder: JSONDecoder())
            .map { $0.iamToken }
            .eraseToAnyPublisher()
    }
    
    private func fetchWorkoutPlan(for userGoal: String, iamToken: String) -> AnyPublisher<String, Error> {
        let url = URL(string: apiUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "modelUri": "gpt://\(folderId)/yandexgpt",
            "completionOptions": [
                "temperature": 0.3,
                "maxTokens": 1000
            ],
            "messages": [
                ["role": "system", "text": "Ты - опытный спортивный тренер. Придумай четыре различных упражнения. Каждое упражнение должно быть стандартизированным: указывается слово Упражнение и номер упражнения, далее указаны название упражнения, описание упражнения и общая информация в одном формате. Каждое упражнение выводится в виде: \nУпражнение 1. Название упражнения - Описание упражнения. \nУпражнение 2. Название упражнения - Описание упражнения. \nУпражнение 3. Название упражнения - Описание упражнения. \nУпражнение 4. Название упражнения - Описание упражнения."],
                ["role": "user", "text": userGoal]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: WorkoutPlanResponse.self, decoder: JSONDecoder())
            .map { $0.result.alternatives.first?.message.text ?? "Нет данных" }
            .eraseToAnyPublisher()
    }
    
    private func parseWorkouts(from response: String) -> [String] {
        let lines = response.split(separator: "\n")
        var workouts = [String]()
        var currentPlan = ""
        
        for line in lines {
            if line.contains("Упражнение") {
                if !currentPlan.isEmpty {
                    workouts.append(currentPlan)
                }
                currentPlan = String(line)
            } else {
                currentPlan += "\n" + line
            }
        }
        
        if !currentPlan.isEmpty {
            workouts.append(currentPlan)
        }
        
        return workouts
    }
}

extension AIWorkoutViewModel {
    func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
