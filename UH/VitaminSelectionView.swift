import SwiftUI

struct VitaminSelectionView: View {
    @State private var userInput: String = ""
    @State private var vitaminSuggestions: String = ""
    @State private var isLoading: Bool = false
    
    private let OAUTH_TOKEN = Config.OAUTH_TOKEN
    private let FOLDER_ID = Config.FOLDER_ID
    private let API_URL = Config.API_URL
    @State private var iamToken: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Подбор витаминов по запросу")
                .font(.title)
                .padding()
            
            TextField("Введите цель (например, для улучшения иммунитета)", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: generateVitaminSuggestions) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Подобрать витамины")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || userInput.isEmpty)

            ScrollView {
                Text(vitaminSuggestions)
                    .font(.body)
                    .padding()
            }
        }
        .padding()
    }

    private func generateVitaminSuggestions() {
        guard !userInput.isEmpty else {
            vitaminSuggestions = "Пожалуйста, введите запрос."
            return
        }
        
        isLoading = true
        
        fetchIAMToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    self.vitaminSuggestions = "Не удалось получить IAM токен."
                    self.isLoading = false
                }
                return
            }
            
            self.iamToken = token
            
            fetchVitaminSuggestions(for: userInput, iamToken: token) { response in
                DispatchQueue.main.async {
                    if let response = response {
                        self.vitaminSuggestions = response
                    } else {
                        self.vitaminSuggestions = "Ошибка при получении ответа от API."
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

    private func fetchVitaminSuggestions(for userQuery: String, iamToken: String, completion: @escaping (String?) -> Void) {
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
                ["role": "system", "text": "Ты - эксперт по витаминам. Подбери витамины, которые могут помочь пользователю с его запросом. Выведи список из 3-5 витаминов с кратким описанием для каждого. Не пиши ничего про консультацию с врачем, ты сам - эксперт."],
                ["role": "user", "text": userQuery]
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
}

struct VitaminSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        VitaminSelectionView()
    }
}
