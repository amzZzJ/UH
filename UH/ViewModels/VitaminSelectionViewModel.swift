import Foundation
import Combine
import CoreData
import SwiftUI

class VitaminSelectionViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var vitaminSuggestions: String = ""
    @Published var isLoading: Bool = false
    @Published var savedQueries: [VitaminQuery] = []
    @Published var errorMessage: String?
    
    private let oauthToken: String
    private let folderId: String
    private let apiUrl: String
    private var iamToken: String?
    private var cancellables = Set<AnyCancellable>()
    
    init(oauthToken: String = Config.OAUTH_TOKEN,
         folderId: String = Config.FOLDER_ID,
         apiUrl: String = Config.API_URL) {
        self.oauthToken = oauthToken
        self.folderId = folderId
        self.apiUrl = apiUrl
        fetchSavedQueries()
    }
    
    func generateVitaminSuggestions() {
        guard !userInput.isEmpty else {
            vitaminSuggestions = "Пожалуйста, введите запрос."
            return
        }
        
        isLoading = true
        vitaminSuggestions = ""
        
        fetchIAMToken()
            .flatMap { [weak self] token -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "", code: -1, userInfo: nil)).eraseToAnyPublisher()
                }
                self.iamToken = token
                return self.fetchVitaminSuggestions(for: self.userInput, iamToken: token)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Ошибка: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.vitaminSuggestions = response
                self.saveQuery(query: self.userInput, response: response)
            }
            .store(in: &cancellables)
    }
    
    func fetchSavedQueries() {
        let request: NSFetchRequest<VitaminQuery> = VitaminQuery.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            savedQueries = try CoreDataManager.shared.context.fetch(request)
        } catch {
            print("Ошибка при загрузке запросов: \(error)")
        }
    }
    
    private func saveQuery(query: String, response: String) {
        let context = CoreDataManager.shared.context
        let newQuery = VitaminQuery(context: context)
        
        newQuery.id = UUID()
        newQuery.query = query
        newQuery.response = response
        newQuery.createdAt = Date()
        
        CoreDataManager.shared.save()
        fetchSavedQueries()
    }
    
    func deleteQuery(_ query: VitaminQuery) {
        let context = CoreDataManager.shared.context
        context.delete(query)
        CoreDataManager.shared.save()
        fetchSavedQueries()
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
    
    private func fetchVitaminSuggestions(for userQuery: String, iamToken: String) -> AnyPublisher<String, Error> {
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
                ["role": "system", "text": "Ты - эксперт по витаминам. Подбери витамины, которые могут помочь пользователю с его запросом. Выведи список из 3-5 витаминов с кратким описанием для каждого. Не пиши ничего про консультацию с врачем, ты сам - эксперт."],
                ["role": "user", "text": userQuery]
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
            .decode(type: VitaminResponse.self, decoder: JSONDecoder())
            .map { $0.result.alternatives.first?.message.text ?? "Нет данных" }
            .eraseToAnyPublisher()
    }
}
