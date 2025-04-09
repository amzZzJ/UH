import SwiftUI

struct NutritionView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var mealPlanName: String = ""
    @State private var mealType: String = "Еженедельное"
    @State private var selectedDate: Date = Date()
    @State private var userInput: String = ""
    @State private var mealPlans: [String] = []
    @State private var expandedPlans: Set<Int> = []
    @State private var isLoading: Bool = false
    @State private var selectedMeals: Set<Int> = []

    private let OAUTH_TOKEN = Config.OAUTH_TOKEN
    private let FOLDER_ID = Config.FOLDER_ID
    private let API_URL = Config.API_URL
    @State private var iamToken: String?

    let mealTypes = ["Еженедельное"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Составление плана питания")
                .font(.title)
                .padding()

            TextField("Введите ваш запрос", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: generateMealPlan) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Подобрать рецепты")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || userInput.isEmpty)

            if !mealPlans.isEmpty {
                Form {
                    Section(header: Text("Название плана питания")) {
                        TextField("Введите название", text: $mealPlanName)
                    }

                    Section(header: Text("Тип плана питания")) {
                        Picker("Выберите тип", selection: $mealType) {
                            ForEach(mealTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Section(header: Text("Выберите дни недели")) {
                        HStack {
                            ForEach(weekdays, id: \.self) { day in
                                Button(action: {
                                    if selectedMeals.contains(day.hashValue) {
                                        selectedMeals.remove(day.hashValue)
                                    } else {
                                        selectedMeals.insert(day.hashValue)
                                    }
                                }) {
                                    Text(day)
                                        .padding()
                                        .background(selectedMeals.contains(day.hashValue) ? Color.blue : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    Section(header: Text("Рецепты на каждый день")) {
                        ForEach(mealPlans.indices, id: \.self) { index in
                            HStack {
                                Button(action: {
                                    if selectedMeals.contains(index) {
                                        selectedMeals.remove(index)
                                    } else {
                                        selectedMeals.insert(index)
                                    }
                                }) {
                                    Image(systemName: selectedMeals.contains(index) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedMeals.contains(index) ? .blue : .gray)
                                }

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
                                        Text(mealPlans[index])
                                            .padding()
                                    },
                                    label: {
                                        Text("Рецепт \(index + 1)")
                                            .font(.headline)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    })
                            }
                        }
                    }
                }
            }

            if !selectedMeals.isEmpty {
                Button("Сохранить план питания") {
                    saveMealPlan()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            }
        }
        .padding()
    }

    private func generateMealPlan() {
        guard !userInput.isEmpty else {
            mealPlans = ["Пожалуйста, введите запрос."]
            return
        }

        isLoading = true

        fetchIAMToken { token in
            guard let token = token else {
                DispatchQueue.main.async {
                    self.mealPlans = ["Не удалось получить IAM токен."]
                    self.isLoading = false
                }
                return
            }

            self.iamToken = token

            fetchMealPlan(for: userInput, iamToken: token) { response in
                DispatchQueue.main.async {
                    if let response = response {
                        self.mealPlans = self.parseMeals(from: response)
                    } else {
                        self.mealPlans = ["Ошибка при получении ответа от API."]
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func saveMealPlan() {
        let context = CoreDataManager.shared.context
        let newMealPlan = MealPlan(context: context)

        newMealPlan.id = UUID()
        newMealPlan.name = mealPlanName.isEmpty ? "План питания с ИИ" : mealPlanName
        newMealPlan.descriptionText = "Автоматически подобранные рецепты"
        newMealPlan.type = mealType

        for index in selectedMeals {
            let meal = Meal(context: context)
            meal.id = UUID()
            meal.name = mealPlans[index]
            newMealPlan.addToMeals(meal)
        }

        CoreDataManager.shared.save()
        presentationMode.wrappedValue.dismiss()
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

    private func fetchMealPlan(for userGoal: String, iamToken: String, completion: @escaping (String?) -> Void) {
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
                ["role": "system", "text": "Ты - опытный диетолог. Придумай рецепты завтраков, обедов и ужинов на всю неделю."],
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

    private func parseMeals(from response: String) -> [String] {
        let lines = response.split(separator: "\n")
        
        var meals = [String]()
        var currentMeal = ""
        
        for line in lines {
            if line.contains("Рецепт"){
                if !currentMeal.isEmpty {
                    meals.append(currentMeal)
                }
                currentMeal = String(line)
            } else {
                currentMeal += "\n" + line
            }
        }
        
        if !currentMeal.isEmpty {
            meals.append(currentMeal)
        }
        
        return meals
    }
}

struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NutritionView()
    }
}
