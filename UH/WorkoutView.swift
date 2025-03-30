import SwiftUI

struct WorkoutView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $selectedTab) {
                    ManualWorkoutView()
                        .tabItem {
                            Label("Вручную", systemImage: "pencil")
                        }
                        .tag(0)

                    AIWorkoutView()
                        .tabItem {
                            Label("С ИИ", systemImage: "sparkles")
                        }
                        .tag(1)
                }
            }
            .navigationTitle("Добавить тренировку")
        }
    }
}

struct ManualWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var workoutName = ""
    @State private var workoutDescription = ""
    @State private var workoutType = "Разовая"
    @State private var selectedDate = Date()
    @State private var selectedDays: Set<String> = []
    @State private var selectedTime = Date()
    @State private var exercises: [String] = []
    @State private var newExercise = ""

    let workoutTypes = ["Разовая", "Еженедельная", "Ежедневная"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        Form {
            Section(header: Text("Название тренировки")) {
                TextField("Введите название", text: $workoutName)
            }

            Section(header: Text("Описание")) {
                TextField("Введите описание", text: $workoutDescription)
            }

            Section(header: Text("Тип тренировки")) {
                Picker("Выберите тип", selection: $workoutType) {
                    ForEach(workoutTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            if workoutType == "Разовая" {
                Section(header: Text("Дата")) {
                    DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                }
            } else if workoutType == "Еженедельная" {
                Section(header: Text("Выберите дни недели")) {
                    HStack {
                        ForEach(weekdays, id: \.self) { day in
                            Button(action: {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            }) {
                                Text(day)
                                    .padding()
                                    .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }

            Section(header: Text("Время")) {
                DatePicker("Выберите время", selection: $selectedTime, displayedComponents: .hourAndMinute)
            }

            Section(header: Text("Упражнения")) {
                HStack {
                    TextField("Введите упражнение", text: $newExercise)
                    Button("Добавить") {
                        if !newExercise.isEmpty {
                            exercises.append(newExercise)
                            newExercise = ""
                        }
                    }
                }

                List {
                    ForEach(exercises, id: \.self) { exercise in
                        HStack {
                            Text(exercise)
                            Spacer()
                            Button(action: {
                                exercises.removeAll { $0 == exercise }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            Button("Сохранить") {
                saveWorkout()
            }
        }
    }

    private func saveWorkout() {
        let context = CoreDataManager.shared.context
        let newWorkout = Workout(context: context)

        newWorkout.id = UUID()
        newWorkout.name = workoutName
        newWorkout.descriptionText = workoutDescription
        newWorkout.type = workoutType
        newWorkout.date = selectedDate
        newWorkout.time = selectedTime
        newWorkout.daysOfWeek = selectedDays.joined(separator: ",")

        for exerciseName in exercises {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = exerciseName
            newWorkout.addToExercises(exercise)
        }

        CoreDataManager.shared.save()
        presentationMode.wrappedValue.dismiss()
    }
}

struct AIWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var workoutName: String = ""
    @State private var workoutType: String = "Разовая"
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var selectedDays: Set<String> = []
    
    @State private var userInput: String = ""
    @State private var workoutPlans: [String] = []
    @State private var expandedPlans: Set<Int> = []
    @State private var isLoading: Bool = false
    @State private var selectedExercises: Set<Int> = []

    private let OAUTH_TOKEN = Config.OAUTH_TOKEN
    private let FOLDER_ID = Config.FOLDER_ID
    private let API_URL = Config.API_URL
    @State private var iamToken: String?

    let workoutTypes = ["Разовая", "Еженедельная", "Ежедневная"]
    let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Составление тренировки")
                .font(.title)
                .padding()

            TextField("Введите вашу цель", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: generateWorkoutPlan) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Подобрать упражнения")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || userInput.isEmpty)

            if !workoutPlans.isEmpty {
                Form {
                    Section(header: Text("Название тренировки")) {
                        TextField("Введите название", text: $workoutName)
                    }

                    Section(header: Text("Тип тренировки")) {
                        Picker("Выберите тип", selection: $workoutType) {
                            ForEach(workoutTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    if workoutType == "Разовая" {
                        Section(header: Text("Дата")) {
                            DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                        }
                    } else if workoutType == "Еженедельная" {
                        Section(header: Text("Выберите дни недели")) {
                            HStack {
                                ForEach(weekdays, id: \.self) { day in
                                    Button(action: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }) {
                                        Text(day)
                                            .padding()
                                            .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text("Время")) {
                        DatePicker("Выберите время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    }

                    Section(header: Text("Выберите упражнения")) {
                        ForEach(workoutPlans.indices, id: \.self) { index in
                            HStack {
                                Button(action: {
                                    if selectedExercises.contains(index) {
                                        selectedExercises.remove(index)
                                    } else {
                                        selectedExercises.insert(index)
                                    }
                                }) {
                                    Image(systemName: selectedExercises.contains(index) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedExercises.contains(index) ? .blue : .gray)
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
                                        Text(workoutPlans[index])
                                            .padding()
                                    },
                                    label: {
                                        Text("Упражнение \(index + 1)")
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

            if !selectedExercises.isEmpty {
                Button("Сохранить тренировку") {
                    saveWorkout()
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
                        self.workoutPlans = self.parseWorkouts(from: response)
                    } else {
                        self.workoutPlans = ["Ошибка при получении ответа от API."]
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func saveWorkout() {
        let context = CoreDataManager.shared.context
        let newWorkout = Workout(context: context)

        newWorkout.id = UUID()
        newWorkout.name = workoutName.isEmpty ? "Тренировка с ИИ" : workoutName
        newWorkout.descriptionText = "Автоматически подобранные упражнения"
        newWorkout.type = workoutType
        newWorkout.date = selectedDate
        newWorkout.time = selectedTime
        newWorkout.daysOfWeek = selectedDays.joined(separator: ",")

        for index in selectedExercises {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = workoutPlans[index]
            newWorkout.addToExercises(exercise)
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
                ["role": "system", "text": "Ты - опытный спортивный тренер. Придумай четыре различных упражнения. Каждое упражнение должно быть стандартизированным: указывается слово Упражнение и номер упражнения, далее указаны название упражнения, описание упражнения и общая информация в одном формате. Каждое упражнение выводится в виде: \nУпражнение 1. Название упражнения - Описание упражнения. \nУпражнение 2. Название упражнения - Описание упражнения. \nУпражнение 3. Название упражнения - Описание упражнения. \nУпражнение 4. Название упражнения - Описание упражнения."],
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
            if line.contains("Упражнение"){
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

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutView()
    }
}
