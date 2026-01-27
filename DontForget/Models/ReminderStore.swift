import Foundation
import SwiftUI

@MainActor
class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = []
    
    private let saveKey = "SavedVouchers_v2" // New key for updated model
    
    // All active vouchers (not used, not expired)
    var activeVouchers: [Reminder] {
        reminders.filter { !$0.isCompleted && !$0.isExpired }
    }
    
    // Used/redeemed vouchers
    var usedVouchers: [Reminder] {
        reminders.filter { $0.isCompleted }
    }
    
    // Expired vouchers
    var expiredVouchers: [Reminder] {
        reminders.filter { $0.isExpired && !$0.isCompleted }
    }
    
    // Vouchers expiring within 7 days
    var expiringSoonVouchers: [Reminder] {
        activeVouchers.filter { $0.isExpiringSoon }
    }
    
    // Vouchers with location set (for geofencing)
    var locationVouchers: [Reminder] {
        activeVouchers.filter { $0.location != nil }
    }
    
    // Total balance across all active vouchers
    var totalBalance: Double {
        activeVouchers.compactMap { $0.balance }.reduce(0, +)
    }
    
    init() {
        loadReminders()
        #if DEBUG
        // Add sample data for screenshots if empty
        if reminders.isEmpty {
            loadSampleData()
        }
        #endif
    }
    
    #if DEBUG
    private func loadSampleData() {
        let sampleVouchers = [
            Reminder(
                title: "Target Gift Card",
                voucherCode: "4532-8901-2345-6789",
                expirationDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()),
                storeName: "Target",
                voucherValue: "$50",
                balance: 35.50
            ),
            Reminder(
                title: "Starbucks Reward",
                voucherCode: "6011-2345-6789-0123",
                expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                storeName: "Starbucks",
                voucherValue: "$25",
                balance: 18.75
            ),
            Reminder(
                title: "Amazon Gift Card",
                voucherCode: "AMZN-GIFT-1234-5678",
                expirationDate: nil,
                storeName: "Amazon",
                voucherValue: "$100",
                balance: 67.23
            ),
            Reminder(
                title: "Chipotle Rewards",
                voucherCode: "CHIP-2024-FREE-BOWL",
                expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                storeName: "Chipotle",
                voucherValue: "Free Bowl",
                balance: nil
            ),
            Reminder(
                title: "Best Buy Store Credit",
                voucherCode: "BBY-9876-5432-1098",
                expirationDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                storeName: "Best Buy",
                voucherValue: "$200",
                balance: 142.99
            )
        ]
        reminders = sampleVouchers
    }
    #endif
    
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
    
    func markAsUsed(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted = true
            reminders[index].balance = 0
            saveReminders()
        }
    }
    
    func updateBalance(_ reminder: Reminder, newBalance: Double) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].balance = newBalance
            if newBalance <= 0 {
                reminders[index].isCompleted = true
            }
            saveReminders()
        }
    }
    
    func vouchersNear(location: (latitude: Double, longitude: Double)) -> [Reminder] {
        locationVouchers.filter { voucher in
            guard let loc = voucher.location else { return false }
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
