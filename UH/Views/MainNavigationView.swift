import SwiftUI

struct MainNavigationView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Главная")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Календарь")
                }
                .tag(2)

            HealthDashboardView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Питание")
                }
                .tag(1)

            VitaminGuideView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Витамины")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Профиль")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainNavigationView()
    }
}
