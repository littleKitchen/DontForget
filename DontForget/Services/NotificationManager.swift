import Foundation
import UserNotifications
import CoreLocation

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleLocationNotification(for voucher: Reminder) {
        guard let location = voucher.location else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📍 You're near \(location.name)!"
        
        var body = "Don't forget: \(voucher.title)"
        
        if let balance = voucher.formattedBalance {
            body += " (\(balance) remaining)"
        } else if let value = voucher.voucherValue {
            body += " (\(value))"
        }
        
        if let days = voucher.daysUntilExpiry, days <= 7 {
            body += " — expires in \(days) days!"
        }
        
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "VOUCHER_NEARBY"
        
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: location.radius,
            identifier: voucher.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        let request = UNNotificationRequest(
            identifier: "location-\(voucher.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleExpirationNotification(for voucher: Reminder) {
        guard let expirationDate = voucher.expirationDate else { return }
        
        // Schedule notifications for 7 days, 3 days, and 1 day before
        let intervals: [(days: Int, urgency: String)] = [
            (7, ""),
            (3, "⚠️ "),
            (1, "🚨 ")
        ]
        
        for (days, urgency) in intervals {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: -days, to: expirationDate),
                  triggerDate > Date() else {
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = "\(urgency)\(voucher.title) expires in \(days) day\(days == 1 ? "" : "s")!"
            
            var body = ""
            if let store = voucher.storeName {
                body = "Use it at \(store)"
            }
            if let balance = voucher.formattedBalance {
                body += body.isEmpty ? "\(balance) remaining" : " — \(balance) remaining"
            }
            
            content.body = body.isEmpty ? "Don't let it go to waste!" : body
            content.sound = .default
            content.categoryIdentifier = "VOUCHER_EXPIRING"
            
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "expiry-\(days)-\(voucher.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
        
        // Also schedule for the actual expiration day
        let content = UNMutableNotificationContent()
        content.title = "🚨 \(voucher.title) expires TODAY!"
        content.body = "Last chance to use it!"
        content.sound = .default
        content.categoryIdentifier = "VOUCHER_EXPIRING"
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: expirationDate)
        components.hour = 9 // 9 AM on expiration day
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "expiry-day-\(voucher.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotifications(for voucher: Reminder) {
        let identifiers = [
            "location-\(voucher.id.uuidString)",
            "expiry-7-\(voucher.id.uuidString)",
            "expiry-3-\(voucher.id.uuidString)",
            "expiry-1-\(voucher.id.uuidString)",
            "expiry-day-\(voucher.id.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func setupCategories() {
        // Voucher nearby actions
        let useNowAction = UNNotificationAction(
            identifier: "USE_NOW",
            title: "Show Card",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 hour",
            options: []
        )
        
        let nearbyCategory = UNNotificationCategory(
            identifier: "VOUCHER_NEARBY",
            actions: [useNowAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Expiring voucher actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW",
            title: "View Card",
            options: [.foreground]
        )
        
        let expiringCategory = UNNotificationCategory(
            identifier: "VOUCHER_EXPIRING",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([nearbyCategory, expiringCategory])
    }
}
