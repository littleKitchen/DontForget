import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ReminderStore
    @State private var showingAddVoucher = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VouchersListView()
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }
                .tag(0)
            
            ExpiringSoonView()
                .tabItem {
                    Label("Expiring", systemImage: "exclamationmark.triangle.fill")
                }
                .tag(1)
                .badge(store.expiringSoonVouchers.count)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

struct VouchersListView: View {
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAddVoucher = false
    @State private var searchText = ""
    
    var filteredVouchers: [Reminder] {
        if searchText.isEmpty {
            return store.activeVouchers
        }
        return store.activeVouchers.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.storeName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.activeVouchers.isEmpty {
                    ContentUnavailableView {
                        Label("No Gift Cards", systemImage: "creditcard")
                    } description: {
                        Text("Add your gift cards and never let them expire unused!")
                    } actions: {
                        Button("Add Gift Card") {
                            showingAddVoucher = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        // Total balance header
                        if store.totalBalance > 0 {
                            Section {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Total Balance")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "$%.2f", store.totalBalance))
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.green)
                                    }
                                    Spacer()
                                    Image(systemName: "creditcard.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.green.opacity(0.3))
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Vouchers list
                        Section {
                            ForEach(filteredVouchers) { voucher in
                                VoucherRowView(voucher: voucher)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            notificationManager.cancelNotifications(for: voucher)
                                            store.delete(voucher)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            store.markAsUsed(voucher)
                                        } label: {
                                            Label("Used", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            // TODO: Quick balance update
                                        } label: {
                                            Label("Update Balance", systemImage: "dollarsign.circle")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        } header: {
                            Text("\(filteredVouchers.count) Cards")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search cards")
                }
            }
            .navigationTitle("Gift Cards")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddVoucher = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddVoucher) {
                AddVoucherView()
            }
        }
    }
}

struct VoucherRowView: View {
    let voucher: Reminder
    @EnvironmentObject var store: ReminderStore
    @State private var showingDetail = false
    @State private var showingEditSheet = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 12) {
                // Card image or icon
                if let data = voucher.cardImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 40)
                        .overlay {
                            Image(systemName: "creditcard")
                                .foregroundStyle(.secondary)
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(voucher.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    // Store + location
                    HStack(spacing: 6) {
                        if let store = voucher.storeName {
                            Text(store)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if voucher.location != nil {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        
                        if voucher.hasBarcode {
                            Image(systemName: "barcode")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Balance and expiry
                VStack(alignment: .trailing, spacing: 4) {
                    if let balance = voucher.formattedBalance {
                        Text(balance)
                            .font(.headline)
                            .foregroundStyle(.green)
                    } else if let value = voucher.voucherValue {
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    
                    if let days = voucher.daysUntilExpiry {
                        HStack(spacing: 2) {
                            if days <= 7 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                            }
                            Text(days == 0 ? "Today" : "\(days)d")
                                .font(.caption)
                        }
                        .foregroundStyle(days <= 3 ? .red : (days <= 7 ? .orange : .secondary))
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            VoucherDetailView(voucher: voucher)
        }
    }
}

struct ExpiringSoonView: View {
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        NavigationStack {
            Group {
                if store.expiringSoonVouchers.isEmpty {
                    ContentUnavailableView {
                        Label("All Good!", systemImage: "checkmark.circle")
                    } description: {
                        Text("No cards expiring in the next 7 days")
                    }
                } else {
                    List {
                        ForEach(store.expiringSoonVouchers.sorted { ($0.daysUntilExpiry ?? 999) < ($1.daysUntilExpiry ?? 999) }) { voucher in
                            VoucherRowView(voucher: voucher)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        notificationManager.cancelNotifications(for: voucher)
                                        store.delete(voucher)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        store.markAsUsed(voucher)
                                    } label: {
                                        Label("Used", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Expiring Soon")
        }
    }
}

struct SettingsView: View {
    @AppStorage("notifyDaysBefore") private var notifyDaysBefore = 7
    @AppStorage("notifyOnArrival") private var notifyOnArrival = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Stepper("Notify \(notifyDaysBefore) days before expiry", value: $notifyDaysBefore, in: 1...30)
                    Toggle("Notify when near store", isOn: $notifyOnArrival)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/littleKitchen/DontForget")!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
        .environmentObject(LocationManager())
        .environmentObject(NotificationManager())
}
