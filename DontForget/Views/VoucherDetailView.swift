import SwiftUI
import CoreImage.CIFilterBuiltins

struct VoucherDetailView: View {
    let voucher: Reminder
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ReminderStore
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var showingEditSheet = false
    @State private var showingBalanceUpdate = false
    @State private var newBalance = ""
    @State private var brightness: CGFloat = UIScreen.main.brightness
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Info
                    VStack(spacing: 8) {
                        Text(voucher.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let store = voucher.storeName {
                            Text(store)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Balance Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Balance")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let balance = voucher.formattedBalance {
                                Text(balance)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.green)
                            } else if let value = voucher.voucherValue {
                                Text(value)
                                    .font(.system(size: 36, weight: .bold))
                            } else {
                                Text("No balance set")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            newBalance = voucher.balance.map { String(format: "%.2f", $0) } ?? ""
                            showingBalanceUpdate = true
                        } label: {
                            Label("Update", systemImage: "pencil.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Barcode Display
                    if let code = voucher.barcodeData ?? voucher.voucherCode {
                        VStack(spacing: 12) {
                            // Generate barcode image
                            if let barcodeImage = generateBarcode(from: code) {
                                Image(uiImage: barcodeImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                            }
                            
                            Text(code)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            if let format = voucher.barcodeFormat {
                                Text(format)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                    
                    // Details
                    VStack(spacing: 16) {
                        if let days = voucher.daysUntilExpiry {
                            DetailRow(
                                icon: "calendar",
                                title: "Expires",
                                value: days == 0 ? "Today!" : "in \(days) days",
                                color: days <= 3 ? .red : (days <= 7 ? .orange : .primary)
                            )
                        }
                        
                        if let location = voucher.location {
                            DetailRow(
                                icon: "location.fill",
                                title: "Location",
                                value: location.name,
                                color: .blue
                            )
                        }
                        
                        if let notes = voucher.notes, !notes.isEmpty {
                            DetailRow(
                                icon: "note.text",
                                title: "Notes",
                                value: notes,
                                color: .secondary
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            store.markAsUsed(voucher)
                            notificationManager.cancelNotifications(for: voucher)
                            dismiss()
                        } label: {
                            Label("Mark as Used", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(role: .destructive) {
                            notificationManager.cancelNotifications(for: voucher)
                            store.delete(voucher)
                            dismiss()
                        } label: {
                            Label("Delete Card", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                AddVoucherView(editingVoucher: voucher)
            }
            .alert("Update Balance", isPresented: $showingBalanceUpdate) {
                TextField("New balance", text: $newBalance)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) { }
                Button("Update") {
                    if let balance = Double(newBalance.replacingOccurrences(of: "$", with: "")) {
                        store.updateBalance(voucher, newBalance: balance)
                    }
                }
            } message: {
                Text("Enter the remaining balance")
            }
            .onAppear {
                // Increase brightness for barcode scanning
                brightness = UIScreen.main.brightness
                UIScreen.main.brightness = 1.0
            }
            .onDisappear {
                // Restore brightness
                UIScreen.main.brightness = brightness
            }
        }
    }
    
    private func generateBarcode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        
        filter.message = Data(string.utf8)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    VoucherDetailView(voucher: Reminder.sampleVoucher)
        .environmentObject(ReminderStore())
        .environmentObject(NotificationManager())
}
