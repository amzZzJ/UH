import Foundation
import CoreData
import SwiftUI
import UserNotifications

class NutritionViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var generatedRecipes: [GeneratedRecipe] = []
    @Published var savedRecipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var selectedMealType: MealType = .breakfast
    @Published var activeTab: NutritionTab = .generate
    @Published var savedRecipeIDs: Set<UUID> = []
    
    @Published var breakfastReminderEnabled: Bool = false
    @Published var breakfastTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var lunchReminderEnabled: Bool = false
    @Published var lunchTime: Date = Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var dinnerReminderEnabled: Bool = false
    @Published var dinnerTime: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
    
    private let OAUTH_TOKEN = Config.OAUTH_TOKEN
    private let FOLDER_ID = Config.FOLDER_ID
    private let API_URL = Config.API_URL
    private var iamToken: String?
    
    enum MealType: String, CaseIterable {
        case breakfast = "Завтрак"
        case lunch = "Обед"
        case dinner = "Ужин"
    }
    
    enum NutritionTab {
        case generate
        case myRecipes
        case reminders
    }
    
    init() {
        fetchSavedRecipes()
        loadReminderSettings()
        requestNotificationAuthorization()
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if !granted {
                print("Уведомления не разрешены")
            }
        }
    }
    
    func loadReminderSettings() {
        let defaults = UserDefaults.standard
        breakfastReminderEnabled = defaults.bool(forKey: "breakfastReminderEnabled")
        lunchReminderEnabled = defaults.bool(forKey: "lunchReminderEnabled")
        dinnerReminderEnabled = defaults.bool(forKey: "dinnerReminderEnabled")
        
        if let time = defaults.object(forKey: "breakfastTime") as? Date {
            breakfastTime = time
        }
        if let time = defaults.object(forKey: "lunchTime") as? Date {
            lunchTime = time
        }
        if let time = defaults.object(forKey: "dinnerTime") as? Date {
            dinnerTime = time
        }
    }
    
    func saveReminderSettings() {
        let defaults = UserDefaults.standard
        defaults.set(breakfastReminderEnabled, forKey: "breakfastReminderEnabled")
        defaults.set(lunchReminderEnabled, forKey: "lunchReminderEnabled")
        defaults.set(dinnerReminderEnabled, forKey: "dinnerReminderEnabled")
        defaults.set(breakfastTime, forKey: "breakfastTime")
        defaults.set(lunchTime, forKey: "lunchTime")
        defaults.set(dinnerTime, forKey: "dinnerTime")
        
        scheduleNotifications()
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let nutritionIds = requests
                .filter { $0.identifier.hasPrefix("nutrition_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: nutritionIds)
            
            DispatchQueue.main.async {
                if self.breakfastReminderEnabled {
                    self.scheduleMealNotification(for: self.breakfastTime, mealType: "breakfast")
                }
                if self.lunchReminderEnabled {
                    self.scheduleMealNotification(for: self.lunchTime, mealType: "lunch")
                }
                if self.dinnerReminderEnabled {
                    self.scheduleMealNotification(for: self.dinnerTime, mealType: "dinner")
                }
            }
        }
    }
    
    private func scheduleMealNotification(for date: Date, mealType: String) {
        let content = UNMutableNotificationContent()
        
        if mealType == "breakfast" {
            content.title = "Напоминание"
            content.body = "Время завтрака!"
        }
        if mealType == "lunch" {
            content.title = "Напоминание"
            content.body = "Время обеда!"
        }
        if mealType == "dinner" {
            content.title = "Напоминание"
            content.body = "Время ужина!"
        }

        content.sound = .default
        content.categoryIdentifier = "nutrition_reminder"
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let timeString = String(format: "%02d%02d", components.hour ?? 0, components.minute ?? 0)
        let identifier = "nutrition_\(mealType)_\(timeString)"
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let oldNotifications = requests.filter {
                $0.identifier.hasPrefix("nutrition_\(mealType)")
            }.map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: oldNotifications)
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Ошибка при установке уведомления для \(mealType): \(error.localizedDescription)")
                } else {
                    print("Успешно установлено уведомление: \(identifier)")
                }
            }
        }
    }
    
    func generateRecipes() {
        guard !userInput.isEmpty else { return }
        
        isLoading = true
        generatedRecipes = []
        
        fetchIAMToken { [weak self] token in
            guard let self = self, let token = token else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            self.iamToken = token
            self.fetchRecipesFromAPI { response in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let response = response {
                        self.generatedRecipes = self.parseRecipes(from: response)
                    }
                }
            }
        }
    }

    func saveRecipe(_ recipe: GeneratedRecipe) {
        let context = CoreDataManager.shared.context
        let newRecipe = Recipe(context: context)
        
        newRecipe.id = UUID()
        newRecipe.name = recipe.name
        newRecipe.type = selectedMealType.rawValue
        newRecipe.ingredients = recipe.ingredients
        newRecipe.instructions = recipe.instructions
        newRecipe.createdAt = Date()
        
        CoreDataManager.shared.save()
        savedRecipeIDs.insert(newRecipe.id!)
        fetchSavedRecipes()
    }

    func isRecipeSaved(_ recipe: GeneratedRecipe) -> Bool {
        savedRecipes.contains { $0.name == recipe.name }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        let context = CoreDataManager.shared.context
        context.delete(recipe)
        CoreDataManager.shared.save()
        fetchSavedRecipes()
    }
    
    private func fetchSavedRecipes() {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            savedRecipes = try CoreDataManager.shared.context.fetch(request)
        } catch {
            print("Ошибка при загрузке рецептов: \(error)")
        }
    }
    
    private func fetchRecipesFromAPI(completion: @escaping (String?) -> Void) {
        print("Отправка запроса к API...")
        let url = URL(string: API_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(iamToken!)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        Строго следуй этому шаблону для 3 рецептов. Никаких лишних слов и символов, только рецепты!

        Название: [Название рецепта 1]
        Тип: \(selectedMealType.rawValue)
        Ингредиенты:
        - Ингредиент 1
        - Ингредиент 2
        - ...
        Приготовление:
        1. Шаг 1
        2. Шаг 2
        3. ...

        Название: [Название рецепта 2]
        Тип: \(selectedMealType.rawValue)
        Ингредиенты:
        - Ингредиент 1
        - Ингредиент 2
        - ...
        Приготовление:
        1. Шаг 1
        2. Шаг 2
        3. ...

        Название: [Название рецепта 3]
        Тип: \(selectedMealType.rawValue)
        Ингредиенты:
        - Ингредиент 1
        - Ингредиент 2
        - ...
        Приготовление:
        1. Шаг 1
        2. Шаг 2
        3. ...

        Запрос: \(userInput). Только рецепты в указанном формате, без вступлений и заключений!
        """
        
        let body: [String: Any] = [
            "modelUri": "gpt://\(FOLDER_ID)/yandexgpt",
            "completionOptions": [
                "temperature": 0.7,
                "maxTokens": 2000
            ],
            "messages": [
                ["role": "system", "text": "Ты - опытный шеф-повар и диетолог. Отвечай ТОЛЬКО на вопросы, связанные с кулинарией, рецептами, питанием и диетологией. Если вопрос не относится к этим темам, вежливо откажись отвечать, объяснив, что твоя экспертиза ограничена кулинарной сферой."],
                ["role": "user", "text": prompt]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка запроса:", error)
                completion(nil)
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Получен ответ от API:", responseString)
            }
            
            guard let data = data else {
                print("Нет данных в ответе")
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
                    print("Ошибка парсинга ответа")
                    completion(nil)
                }
            } catch {
                print("Ошибка парсинга JSON:", error)
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func parseRecipes(from response: String) -> [GeneratedRecipe] {
        let cleanedText = response
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "###", with: "")
        
        let recipeBlocks = cleanedText.components(separatedBy: "Название:").dropFirst()
        var recipes: [GeneratedRecipe] = []
        
        for block in recipeBlocks {
            let lines = block.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            guard !lines.isEmpty else { continue }
            
            var name = ""
            var ingredients: [String] = []
            var instructions: [String] = []
            var currentSection: ParserSection = .name
            
            enum ParserSection {
                case name, type, ingredients, instructions
            }
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                if trimmedLine.hasPrefix("Тип:") {
                    currentSection = .type
                } else if trimmedLine.lowercased().hasPrefix("ингредиенты:") {
                    currentSection = .ingredients
                } else if trimmedLine.lowercased().hasPrefix("приготовление:") {
                    currentSection = .instructions
                } else {
                    switch currentSection {
                    case .name:
                        name = trimmedLine
                    case .ingredients:
                        if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*") {
                            ingredients.append(trimmedLine.dropFirst().trimmingCharacters(in: .whitespaces))
                        }
                    case .instructions:
                        if trimmedLine.first?.isNumber == true ||
                           trimmedLine.hasPrefix("-") ||
                           trimmedLine.hasPrefix("*") ||
                           trimmedLine.hasPrefix("•") {
                            instructions.append(trimmedLine)
                        }
                    default:
                        break
                    }
                }
            }
            
            if !name.isEmpty {
                let recipe = GeneratedRecipe(
                    name: name,
                    ingredients: ingredients.joined(separator: "\n"),
                    instructions: instructions.joined(separator: "\n")
                )
                recipes.append(recipe)
            }
        }

        return recipes.isEmpty ? parseFallback(response) : recipes
    }

    private func parseFallback(_ text: String) -> [GeneratedRecipe] {
        let cleanedText = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "###", with: "")
            .replacingOccurrences(of: "```", with: "")
        
        let potentialRecipes = cleanedText.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var recipes: [GeneratedRecipe] = []
        
        for recipeText in potentialRecipes {
            let name: String
            if let nameRange = recipeText.range(of: "(?<=Название: ).*", options: .regularExpression) {
                name = String(recipeText[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                name = recipeText.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespaces) ?? "Рецепт"
            }
            
            var ingredients = ""
            if let ingredientsRange = recipeText.range(of: "(?<=Ингредиенты:)[\\s\\S]*?(?=Приготовление:|$)", options: .regularExpression) {
                let ingredientsText = String(recipeText[ingredientsRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                
                ingredients = ingredientsText.joined(separator: "\n")
            }
            
            var instructions = ""
            if let instructionsRange = recipeText.range(of: "(?<=Приготовление:)[\\s\\S]*", options: .regularExpression) {
                let instructionsText = String(recipeText[instructionsRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                
                instructions = instructionsText.joined(separator: "\n")
            } else if ingredients.isEmpty {
                instructions = recipeText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            let recipe = GeneratedRecipe(
                name: name,
                ingredients: ingredients.isEmpty ? "Ингредиенты не указаны" : ingredients,
                instructions: instructions.isEmpty ? "Инструкции не указаны" : instructions
            )
            
            recipes.append(recipe)
            
            if recipes.count >= 3 {
                break
            }
        }
        
        if recipes.isEmpty {
            return [GeneratedRecipe(
                name: "Рецепт",
                ingredients: "Ингредиенты не распознаны",
                instructions: cleanedText
            )]
        }
        
        return recipes
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
}

extension NutritionViewModel.NutritionTab: CaseIterable {
    static var allCases: [NutritionViewModel.NutritionTab] {
        return [.generate, .myRecipes, .reminders]
    }
    
    var title: String {
        switch self {
        case .generate: return "Генерация"
        case .myRecipes: return "Мои рецепты"
        case .reminders: return "Напоминания"
        }
    }
}
