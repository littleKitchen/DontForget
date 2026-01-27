import SwiftUI
import MapKit

struct AddVoucherView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    // Editing existing voucher
    var editingVoucher: Reminder?
    
    @State private var title = ""
    @State private var storeName = ""
    @State private var voucherValue = ""
    @State private var balance: String = ""
    @State private var voucherCode = ""
    @State private var barcodeData: String?
    @State private var barcodeFormat: String?
    @State private var expirationDate = Date()
    @State private var hasExpiration = false
    
    // Location
    @State private var useLocation = false
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: SavedLocation?
    @State private var isSearching = false
    
    // Sheets
    @State private var showingBarcodeScanner = false
    
    var isEditing: Bool {
        editingVoucher != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Card Info Section
                Section("Gift Card Info") {
                    TextField("Card name (e.g., Target Gift Card)", text: $title)
                    TextField("Store name", text: $storeName)
                    
                    HStack {
                        TextField("Original value (e.g., $50)", text: $voucherValue)
                            .keyboardType(.decimalPad)
                        
                        Divider()
                        
                        TextField("Balance", text: $balance)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                    }
                }
                
                // Barcode Section
                Section {
                    if let code = barcodeData ?? (voucherCode.isEmpty ? nil : voucherCode) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(code)
                                    .font(.system(.body, design: .monospaced))
                                if let format = barcodeFormat {
                                    Text(format)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                barcodeData = nil
                                barcodeFormat = nil
                                voucherCode = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        showingBarcodeScanner = true
                    } label: {
                        Label(
                            barcodeData != nil ? "Re-scan Barcode" : "Scan Barcode",
                            systemImage: "barcode.viewfinder"
                        )
                    }
                    
                    if barcodeData == nil {
                        TextField("Or enter code manually", text: $voucherCode)
                            .font(.system(.body, design: .monospaced))
                    }
                } header: {
                    Text("Barcode / Card Number")
                }
                
                // Expiration Section
                Section("Expiration") {
                    Toggle("Has Expiration Date", isOn: $hasExpiration)
                    
                    if hasExpiration {
                        DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                    }
                }
                
                // Location Section
                Section {
                    Toggle("Remind me at store", isOn: $useLocation)
                    
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
                            TextField("Search for store location", text: $searchText)
                                .autocorrectionDisabled()
                                .onChange(of: searchText) { _, newValue in
                                    searchLocations(query: newValue)
                                }
                            
                            if isSearching {
                                ProgressView()
                            }
                            
                            ForEach(searchResults, id: \.self) { item in
                                Button {
                                    selectLocation(item)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.name ?? "Unknown")
                                            .foregroundStyle(.primary)
                                        if let address = item.placemark.formattedAddress {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Location Alert")
                } footer: {
                    Text("Get notified when you're near the store")
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "Add Gift Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveVoucher()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView(scannedCode: $barcodeData, codeFormat: $barcodeFormat)
            }
            .onAppear {
                loadEditingVoucher()
            }
        }
    }
    
    private func loadEditingVoucher() {
        guard let voucher = editingVoucher else { return }
        
        title = voucher.title
        storeName = voucher.storeName ?? ""
        voucherValue = voucher.voucherValue ?? ""
        balance = voucher.balance.map { String(format: "%.2f", $0) } ?? ""
        voucherCode = voucher.voucherCode ?? ""
        barcodeData = voucher.barcodeData
        barcodeFormat = voucher.barcodeFormat
        
        if let expDate = voucher.expirationDate {
            hasExpiration = true
            expirationDate = expDate
        }
        
        if let loc = voucher.location {
            useLocation = true
            selectedLocation = loc
        }
    }
    
    private func saveVoucher() {
        let parsedBalance = Double(balance.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
        
        let voucher = Reminder(
            id: editingVoucher?.id ?? UUID(),
            title: title,
            location: useLocation ? selectedLocation : nil,
            voucherCode: voucherCode.isEmpty ? nil : voucherCode,
            barcodeData: barcodeData,
            barcodeFormat: barcodeFormat,
            expirationDate: hasExpiration ? expirationDate : nil,
            storeName: storeName.isEmpty ? nil : storeName,
            voucherValue: voucherValue.isEmpty ? nil : voucherValue,
            balance: parsedBalance
        )
        
        if isEditing {
            store.update(voucher)
        } else {
            store.add(voucher)
        }
        
        // Schedule notifications
        if voucher.location != nil {
            notificationManager.scheduleLocationNotification(for: voucher)
        }
        if voucher.expirationDate != nil {
            notificationManager.scheduleExpirationNotification(for: voucher)
        }
        
        dismiss()
    }
    
    private func searchLocations(query: String) {
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
        search.start { response, error in
            isSearching = false
            if let items = response?.mapItems {
                searchResults = Array(items.prefix(5))
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedLocation = SavedLocation(
            name: item.name ?? storeName,
            address: item.placemark.formattedAddress,
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude,
            radius: 100
        )
        searchText = ""
        searchResults = []
        
        // Auto-fill store name if empty
        if storeName.isEmpty, let name = item.name {
            storeName = name
        }
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        let components = [
            subThoroughfare,
            thoroughfare,
            locality,
            administrativeArea
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
}

#Preview {
    AddVoucherView()
        .environmentObject(ReminderStore())
        .environmentObject(LocationManager())
        .environmentObject(NotificationManager())
}
