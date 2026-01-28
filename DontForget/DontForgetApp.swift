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
                    #if DEBUG
                    let isScreenshotMode = CommandLine.arguments.contains("-NO_PERMISSIONS") ||
                                          CommandLine.arguments.contains(where: { $0.hasPrefix("-SCREENSHOT_") })
                    if !isScreenshotMode {
                        notificationManager.requestPermission()
                        locationManager.requestPermission()
                    }
                    #else
                    notificationManager.requestPermission()
                    locationManager.requestPermission()
                    #endif
                }
        }
    }
}
