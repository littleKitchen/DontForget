import Foundation
import SwiftUI

@MainActor
class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = []
    
    private let saveKey = "SavedReminders"
    
    var activeReminders: [Reminder] {
        reminders.filter { !$0.isCompleted && !$0.isExpired }
    }
    
    var completedReminders: [Reminder] {
        reminders.filter { $0.isCompleted }
    }
    
    var vouchers: [Reminder] {
        reminders.filter { $0.isVoucher && !$0.isCompleted && !$0.isExpired }
    }
    
    var expiringSoonVouchers: [Reminder] {
        vouchers.filter { $0.isExpiringSoon }
    }
    
    var locationReminders: [Reminder] {
        reminders.filter { $0.location != nil && !$0.isCompleted }
    }
    
    init() {
        loadReminders()
    }
    
    func add(_ reminder: Reminder) {
        reminders.insert(reminder, at: 0)
        saveReminders()
    }
    
    func update(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            saveReminders()
        }
    }
    
    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
    }
    
    func toggleComplete(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted.toggle()
            saveReminders()
        }
    }
    
    func remindersNear(location: (latitude: Double, longitude: Double)) -> [Reminder] {
        locationReminders.filter { reminder in
            guard let loc = reminder.location else { return false }
            let distance = calculateDistance(
                from: (loc.latitude, loc.longitude),
                to: location
            )
            return distance <= loc.radius
        }
    }
    
    private func calculateDistance(from: (Double, Double), to: (Double, Double)) -> Double {
        let lat1 = from.0 * .pi / 180
        let lat2 = to.0 * .pi / 180
        let deltaLat = (to.0 - from.0) * .pi / 180
        let deltaLon = (to.1 - from.1) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon/2) * sin(deltaLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return 6371000 * c // Earth radius in meters
    }
    
    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded
        }
    }
}
