import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            
            NavigationStack {
                ProfileView()
                    .environmentObject(authService)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .tint(.accentColor)
    }
}
