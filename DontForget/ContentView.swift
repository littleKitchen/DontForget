import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ReminderStore
    
    var body: some View {
        TabView {
            RemindersListView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
            
            VouchersListView()
                .tabItem {
                    Label("Vouchers", systemImage: "ticket.fill")
                }
        }
    }
}

struct RemindersListView: View {
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAddReminder = false
    
    var body: some View {
        NavigationStack {
            Group {
                if store.activeReminders.filter({ !$0.isVoucher }).isEmpty {
                    ContentUnavailableView {
                        Label("No Reminders", systemImage: "bell.slash")
                    } description: {
                        Text("Add location-based reminders so you never forget.")
                    } actions: {
                        Button("Add Reminder") {
                            showingAddReminder = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.activeReminders.filter { !$0.isVoucher }) { reminder in
                            ReminderRowView(reminder: reminder)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        notificationManager.cancelNotifications(for: reminder)
                                        store.delete(reminder)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        store.toggleComplete(reminder)
                                    } label: {
                                        Label("Done", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(isVoucher: false)
            }
        }
    }
}

struct VouchersListView: View {
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAddVoucher = false
    
    var body: some View {
        NavigationStack {
            Group {
                if store.vouchers.isEmpty {
                    ContentUnavailableView {
                        Label("No Vouchers", systemImage: "ticket")
                    } description: {
                        Text("Track your gift cards and coupons so they never expire unused.")
                    } actions: {
                        Button("Add Voucher") {
                            showingAddVoucher = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if !store.expiringSoonVouchers.isEmpty {
                            Section("⚠️ Expiring Soon") {
                                ForEach(store.expiringSoonVouchers) { voucher in
                                    VoucherRowView(voucher: voucher)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                notificationManager.cancelNotifications(for: voucher)
                                                store.delete(voucher)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            
                                            Button {
                                                store.toggleComplete(voucher)
                                            } label: {
                                                Label("Used", systemImage: "checkmark")
                                            }
                                            .tint(.green)
                                        }
                                }
                            }
                        }
                        
                        let otherVouchers = store.vouchers.filter { !$0.isExpiringSoon }
                        if !otherVouchers.isEmpty {
                            Section("All Vouchers") {
                                ForEach(otherVouchers) { voucher in
                                    VoucherRowView(voucher: voucher)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                notificationManager.cancelNotifications(for: voucher)
                                                store.delete(voucher)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            
                                            Button {
                                                store.toggleComplete(voucher)
                                            } label: {
                                                Label("Used", systemImage: "checkmark")
                                            }
                                            .tint(.green)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vouchers")
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
                AddReminderView(isVoucher: true)
            }
        }
    }
}

struct ReminderRowView: View {
    let reminder: Reminder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reminder.title)
                .font(.headline)
            
            if let location = reminder.location {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                    Text(location.name)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            if let notes = reminder.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct VoucherRowView: View {
    let voucher: Reminder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(voucher.title)
                        .font(.headline)
                    
                    if let value = voucher.voucherValue {
                        Text(value)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                
                if let store = voucher.storeName {
                    HStack {
                        Image(systemName: "storefront.fill")
                        Text(store)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                if let location = voucher.location {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text(location.name)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let days = voucher.daysUntilExpiry {
                VStack {
                    Text("\(days)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(days <= 3 ? .red : (days <= 7 ? .orange : .primary))
                    Text("days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderStore())
        .environmentObject(LocationManager())
        .environmentObject(NotificationManager())
}
