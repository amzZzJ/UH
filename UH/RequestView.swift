import SwiftUI

struct RequestView: View {
    @State private var userInput: String = ""
    @State private var responseText: String = "Введите запрос и получите ответ!"
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("🤖 YandexGPT Chat")
                .font(.title)
                .fontWeight(.bold)

            TextField("Введите запрос...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                fetchGPTResponse(for: userInput)
            }) {
                Text("Отправить")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(userInput.isEmpty || isLoading)

            if isLoading {
                ProgressView()
            } else {
                Text(responseText)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }

    func fetchGPTResponse(for query: String) {
        guard let url = URL(string: "https://llm.api.cloud.yandex.net/foundationModels/v1/completion") else { return }

        isLoading = true
        let requestBody: [String: Any] = [
            "model": "yandexgpt",
            "prompt": query,
            "temperature": 0.7,
            "max_tokens": 100
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer YOUR_IAM_TOKEN", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            responseText = "Ошибка формирования запроса"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    responseText = "Ошибка: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    responseText = "Пустой ответ от сервера"
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(YandexGPTResponse.self, from: data)
                    responseText = decodedResponse.completion
                } catch {
                    responseText = "Ошибка обработки ответа"
                }
            }
        }.resume()
    }
}

struct YandexGPTResponse: Codable {
    let completion: String
}

struct RequestView_Previews: PreviewProvider {
    static var previews: some View {
        RequestView()
    }
}
