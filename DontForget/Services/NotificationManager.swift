import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleLocationNotification(for reminder: Reminder) {
        guard let location = reminder.location else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📍 You're near \(location.name)!"
        
        if reminder.isVoucher, let value = reminder.voucherValue, let days = reminder.daysUntilExpiry {
            content.body = "Don't forget: \(reminder.title) (\(value)) — expires in \(days) days!"
        } else {
            content.body = reminder.title
            if let notes = reminder.notes {
                content.body += "\n\(notes)"
            }
        }
        
        content.sound = .default
        
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: location.radius,
            identifier: reminder.id.uuidString
        )
        region.notifyOnEntry = reminder.triggerOnArrival
        region.notifyOnExit = !reminder.triggerOnArrival
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        let request = UNNotificationRequest(
            identifier: "location-\(reminder.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleExpirationNotification(for reminder: Reminder) {
        guard let expirationDate = reminder.expirationDate else { return }
        
        // Schedule notifications at 7 days, 3 days, 1 day before
        let intervals: [(days: Int, message: String)] = [
            (7, "expires in 1 week"),
            (3, "expires in 3 days"),
            (1, "expires tomorrow!")
        ]
        
        for interval in intervals {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: -interval.days, to: expirationDate),
                  triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "⏰ \(reminder.title) \(interval.message)"
            
            if let value = reminder.voucherValue, let store = reminder.storeName {
                content.body = "\(value) at \(store) — use it before it's gone!"
            } else {
                content.body = "Don't let it expire unused!"
            }
            
            content.sound = .default
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "expiry-\(interval.days)-\(reminder.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelNotifications(for reminder: Reminder) {
        let identifiers = [
            "location-\(reminder.id.uuidString)",
            "expiry-7-\(reminder.id.uuidString)",
            "expiry-3-\(reminder.id.uuidString)",
            "expiry-1-\(reminder.id.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

import CoreLocation
