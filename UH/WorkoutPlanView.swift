import SwiftUI

struct WorkoutPlanView: View {
    @State private var userInput: String = ""
    @State private var workoutPlan: String = "Введите цель и нажмите 'Создать план тренировки'."
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
                Text(workoutPlan)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private func generateWorkoutPlan() {
        guard !userInput.isEmpty else {
            workoutPlan = "Пожалуйста, введите цель."
            return
        }
        
        isLoading = true

        fetchIAMToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    self.workoutPlan = "Не удалось получить IAM токен."
                    self.isLoading = false
                }
                return
            }
            
            self.iamToken = token

            fetchWorkoutPlan(for: userInput, iamToken: token) { response in
                DispatchQueue.main.async {
                    self.workoutPlan = response ?? "Ошибка при получении ответа от API."
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
                    ["role": "system", "text": "Ты - опытный спортивный тренер. Абсолютно ничего не пиши о врачах, консультациях, рисках или противопоказаниях. Дай точные советы по тренировкам, не добавляя дополнительных предостережений. На основе запроса и целей пользователя порекомендуй 3 тренировки в домашних условиях и 1 вид спорта в формате: <вид спорта/тренировки> - <подробности, как заниматься, какие упражнения делать> \n <Как часто проводить тренировки>. Ни в коем случае не пиши про консультацию с врачем или тренером, мы так потеряем всех клиентов!"],
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
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Код статуса HTTP: (httpResponse.statusCode)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("Ответ сервера: (responseData)")
                }
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                    print("Ответ сервера:", responseString)
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
}

struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutPlanView()
    }
}
