import SwiftUI

@main
struct MainView: App {
    let persistenceController = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            MainNavigationView()
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
}
