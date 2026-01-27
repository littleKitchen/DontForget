import SwiftUI
import MapKit

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    let isVoucher: Bool
    
    @State private var title = ""
    @State private var notes = ""
    @State private var storeName = ""
    @State private var voucherValue = ""
    @State private var voucherCode = ""
    @State private var expirationDate = Date()
    @State private var hasExpiration = false
    
    @State private var useLocation = false
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: SavedLocation?
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(isVoucher ? "Voucher Info" : "Reminder") {
                    TextField(isVoucher ? "e.g., Target Gift Card" : "e.g., Buy milk", text: $title)
                    
                    if isVoucher {
                        TextField("Store name", text: $storeName)
                        TextField("Value (e.g., $20, 15% off)", text: $voucherValue)
                        TextField("Code (optional)", text: $voucherCode)
                    } else {
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
                
                if isVoucher {
                    Section("Expiration") {
                        Toggle("Has Expiration Date", isOn: $hasExpiration)
                        
                        if hasExpiration {
                            DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                        }
                    }
                }
                
                Section("Location Reminder") {
                    Toggle("Remind me at a location", isOn: $useLocation)
                    
                    if useLocation {
                        if let location = selectedLocation {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(location.name)
                                        .font(.headline)
                                    if let address = location.address {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button {
                                    selectedLocation = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            HStack {
                                TextField("Search for a place...", text: $searchText)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                
                                if isSearching {
                                    ProgressView()
                                }
                            }
                            .onChange(of: searchText) { _, newValue in
                                searchPlaces(query: newValue)
                            }
                            
                            if !searchResults.isEmpty {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        selectPlace(item)
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(item.name ?? "Unknown")
                                                .foregroundStyle(.primary)
                                            if let address = item.placemark.title {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isVoucher ? "Add Voucher" : "Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func searchPlaces(query: String) {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let location = locationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            isSearching = false
            searchResults = response?.mapItems.prefix(5).map { $0 } ?? []
        }
    }
    
    private func selectPlace(_ item: MKMapItem) {
        selectedLocation = SavedLocation(
            name: item.name ?? "Unknown",
            address: item.placemark.title,
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude,
            radius: 100
        )
        searchText = ""
        searchResults = []
    }
    
    private func saveReminder() {
        let reminder = Reminder(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            location: useLocation ? selectedLocation : nil,
            isVoucher: isVoucher,
            voucherCode: voucherCode.isEmpty ? nil : voucherCode,
            expirationDate: hasExpiration ? expirationDate : nil,
            storeName: storeName.isEmpty ? nil : storeName,
            voucherValue: voucherValue.isEmpty ? nil : voucherValue
        )
        
        store.add(reminder)
        
        // Schedule notifications
        if useLocation && selectedLocation != nil {
            notificationManager.scheduleLocationNotification(for: reminder)
        }
        
        if isVoucher && hasExpiration {
            notificationManager.scheduleExpirationNotification(for: reminder)
        }
        
        dismiss()
    }
}

#Preview {
    AddReminderView(isVoucher: false)
        .environmentObject(ReminderStore())
        .environmentObject(LocationManager())
        .environmentObject(NotificationManager())
}
