import SwiftUI

@main
struct UHApp: App {
    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.context) // Передаем контекст
        }
    }
}
