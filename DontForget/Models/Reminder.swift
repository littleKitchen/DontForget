import Foundation
import CoreLocation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date
    
    // Location-based trigger
    var location: SavedLocation?
    var triggerOnArrival: Bool // true = arriving, false = leaving
    
    // Time-based trigger
    var dueDate: Date?
    var notifyBefore: TimeInterval? // seconds before due date
    
    // Voucher/Coupon specific
    var isVoucher: Bool
    var voucherCode: String?
    var expirationDate: Date?
    var storeName: String?
    var voucherValue: String? // e.g., "$20 off", "15%"
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        location: SavedLocation? = nil,
        triggerOnArrival: Bool = true,
        dueDate: Date? = nil,
        notifyBefore: TimeInterval? = nil,
        isVoucher: Bool = false,
        voucherCode: String? = nil,
        expirationDate: Date? = nil,
        storeName: String? = nil,
        voucherValue: String? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.location = location
        self.triggerOnArrival = triggerOnArrival
        self.dueDate = dueDate
        self.notifyBefore = notifyBefore
        self.isVoucher = isVoucher
        self.voucherCode = voucherCode
        self.expirationDate = expirationDate
        self.storeName = storeName
        self.voucherValue = voucherValue
    }
    
    var isExpiringSoon: Bool {
        guard let expDate = expirationDate else { return false }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day ?? 0
        return daysUntilExpiry <= 7 && daysUntilExpiry >= 0
    }
    
    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }
    
    var daysUntilExpiry: Int? {
        guard let expDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
    }
}

struct SavedLocation: Codable, Equatable, Hashable {
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var radius: Double // meters
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(name: String, address: String? = nil, latitude: Double, longitude: Double, radius: Double = 100) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}

// Sample data for previews
extension Reminder {
    static let sampleReminder = Reminder(
        title: "Buy groceries",
        location: SavedLocation(name: "Whole Foods", address: "123 Main St", latitude: 37.7749, longitude: -122.4194),
        triggerOnArrival: true
    )
    
    static let sampleVoucher = Reminder(
        title: "Target Gift Card",
        location: SavedLocation(name: "Target", address: "456 Oak Ave", latitude: 37.3382, longitude: -121.8863),
        isVoucher: true,
        voucherCode: "XXXX-1234",
        expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
        storeName: "Target",
        voucherValue: "$20"
    )
}
