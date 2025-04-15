import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "CoreDataModel")
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Ошибка загрузки CoreData: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }

    func save() {
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }
}
