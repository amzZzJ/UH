import SwiftUI

struct WorkoutPlanView: View {
    @State private var userInput: String = ""
    @State private var workoutPlans: [String] = []
    @State private var expandedPlans: Set<Int> = []
    @State private var isLoading: Bool = false
    
    private let OAUTH_TOKEN = Config.OAUTH_TOKEN
    private let FOLDER_ID = Config.FOLDER_ID
    private let API_URL = Config.API_URL
    @State private var iamToken: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Составление плана тренировок")
                .font(.title)
                .padding()
            
            TextField("Введите вашу цель", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: generateWorkoutPlan) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Создать план тренировки")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || userInput.isEmpty)
            
            ScrollView {
                ForEach(workoutPlans.indices, id: \.self) { index in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { self.expandedPlans.contains(index) },
                            set: { isExpanded in
                                if isExpanded {
                                    self.expandedPlans.insert(index)
                                } else {
                                    self.expandedPlans.remove(index)
                                }
                            }
                        ),
                        content: {
                            Text(workoutPlans[index])
                                .padding()
                        },
                        label: {
                            Text("План \(index + 1)")
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        })
                        .padding(.horizontal)
                }
            }
        }
        .padding()
    }
    
    private func generateWorkoutPlan() {
        guard !userInput.isEmpty else {
            workoutPlans = ["Пожалуйста, введите цель."]
            return
        }
        
        isLoading = true

        fetchIAMToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    self.workoutPlans = ["Не удалось получить IAM токен."]
                    self.isLoading = false
                }
                return
            }
            
            self.iamToken = token

            fetchWorkoutPlan(for: userInput, iamToken: token) { response in
                DispatchQueue.main.async {
                    if let response = response {
                        let workouts = self.parseWorkouts(from: response)
                        self.workoutPlans = workouts
                    } else {
                        self.workoutPlans = ["Ошибка при получении ответа от API."]
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchIAMToken(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://iam.api.cloud.yandex.net/iam/v1/tokens")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "yandexPassportOauthToken": OAUTH_TOKEN
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при получении IAM токена:", error)
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Нет данных в ответе.")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["iamToken"] as? String {
                    completion(token)
                } else {
                    print("Ошибка парсинга ответа.")
                    completion(nil)
                }
            } catch {
                print("Ошибка парсинга JSON:", error)
                completion(nil)
            }
        }
        
        task.resume()
    }

    private func fetchWorkoutPlan(for userGoal: String, iamToken: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: API_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
                "modelUri": "gpt://\(FOLDER_ID)/yandexgpt",
                "completionOptions": [
                    "temperature": 0.3,
                    "maxTokens": 1000
                ],
                "messages": [
                    ["role": "system", "text": "Ты - опытный спортивный тренер. Придумай три различных плана тренировок на неделю для пользователя. Каждый план должен включать 3 тренировки, и должен быть стандартизированным: указаны название тренировки, описание упражнений и общая информация в одном формате. Каждый план выводится в виде: \n1. Название тренировки\n- Описание упражнений. \n2. Название тренировки\n- Описание упражнений. \n3. Название тренировки\n- Описание упражнений."],
                    ["role": "user", "text": userGoal]
                ]
            ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при выполнении запроса:", error)
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Нет данных в ответе.")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let result = json["result"] as? [String: Any],
                   let alternatives = result["alternatives"] as? [[String: Any]],
                   let message = alternatives.first?["message"] as? [String: Any],
                   let text = message["text"] as? String {
                    completion(text)
                } else {
                    print("Ошибка парсинга ответа.")
                    completion(nil)
                }
            } catch {
                print("Ошибка парсинга JSON:", error)
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func parseWorkouts(from response: String) -> [String] {
        let lines = response.split(separator: "\n")
        
        var workouts = [String]()
        var currentPlan = ""
        
        for line in lines {
            if line.contains("План") && !line.contains("Планка") {
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

struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutPlanView()
    }
}
