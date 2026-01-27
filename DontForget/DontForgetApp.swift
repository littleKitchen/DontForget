import SwiftUI

@main
struct DontForgetApp: App {
    @StateObject private var store = ReminderStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .onAppear {
                    notificationManager.requestPermission()
                    locationManager.requestPermission()
                }
        }
    }
}
