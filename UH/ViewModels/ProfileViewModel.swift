import SwiftUI
import CoreData

class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var avatarImage: UIImage?
    @Published var isLoading = false
    
    private let context = CoreDataManager.shared.context
    
    init() {
        fetchProfile()
    }
    
    func fetchProfile() {
        isLoading = true
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(request)
            if let profile = profiles.first {
                username = profile.username ?? ""
                if let avatarData = profile.avatarData {
                    avatarImage = UIImage(data: avatarData)
                }
            } else {
                createDefaultProfile()
            }
        } catch {
            print("Ошибка загрузки профиля:", error)
        }
        isLoading = false
    }
    
    func saveProfile() {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(request)
            let profile = profiles.first ?? UserProfile(context: context)
            
            profile.username = username
            if let avatarImage = avatarImage {
                profile.avatarData = avatarImage.jpegData(compressionQuality: 0.8)
            }
            
            CoreDataManager.shared.save()
        } catch {
            print("Ошибка сохранения профиля:", error)
        }
    }
    
    private func createDefaultProfile() {
        let newProfile = UserProfile(context: context)
        newProfile.id = UUID()
        newProfile.username = "Новый пользователь"
        CoreDataManager.shared.save()
    }
}
