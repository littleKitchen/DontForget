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
    
    // Voucher/Gift Card specific
    var voucherCode: String?
    var barcodeData: String?     // Scanned barcode string
    var barcodeFormat: String?   // e.g., "QR", "EAN-13", "Code128"
    var expirationDate: Date?
    var storeName: String?
    var voucherValue: String?    // Original value e.g., "$50"
    var balance: Double?         // Current remaining balance
    var cardImageData: Data?     // Photo of the actual card
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        location: SavedLocation? = nil,
        triggerOnArrival: Bool = true,
        voucherCode: String? = nil,
        barcodeData: String? = nil,
        barcodeFormat: String? = nil,
        expirationDate: Date? = nil,
        storeName: String? = nil,
        voucherValue: String? = nil,
        balance: Double? = nil,
        cardImageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.location = location
        self.triggerOnArrival = triggerOnArrival
        self.voucherCode = voucherCode
        self.barcodeData = barcodeData
        self.barcodeFormat = barcodeFormat
        self.expirationDate = expirationDate
        self.storeName = storeName
        self.voucherValue = voucherValue
        self.balance = balance
        self.cardImageData = cardImageData
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
    
    var formattedBalance: String? {
        guard let balance = balance else { return nil }
        return String(format: "$%.2f", balance)
    }
    
    var hasBarcode: Bool {
        barcodeData != nil || voucherCode != nil
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
    static let sampleVoucher = Reminder(
        title: "Target Gift Card",
        location: SavedLocation(name: "Target", address: "456 Oak Ave", latitude: 37.3382, longitude: -121.8863),
        voucherCode: "XXXX-1234",
        expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
        storeName: "Target",
        voucherValue: "$50",
        balance: 35.50
    )
    
    static let sampleVoucherExpiring = Reminder(
        title: "Starbucks Reward",
        location: SavedLocation(name: "Starbucks", address: "789 Coffee Lane", latitude: 37.3352, longitude: -121.8811),
        expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
        storeName: "Starbucks",
        voucherValue: "$10",
        balance: 10.00
    )
}
