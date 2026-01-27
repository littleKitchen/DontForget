import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String?
    @Binding var codeFormat: String?
    
    @State private var isScanning = true
    @State private var showingManualEntry = false
    @State private var manualCode = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                BarcodeScannerRepresentable(
                    scannedCode: $scannedCode,
                    codeFormat: $codeFormat,
                    isScanning: $isScanning
                )
                .ignoresSafeArea()
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanning frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 280, height: 150)
                        .background(Color.black.opacity(0.001)) // Tap target
                    
                    Text("Point camera at barcode")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Manual entry button
                    Button {
                        showingManualEntry = true
                    } label: {
                        Label("Enter Manually", systemImage: "keyboard")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onChange(of: scannedCode) { _, newValue in
                if newValue != nil {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Dismiss after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
            .alert("Enter Code Manually", isPresented: $showingManualEntry) {
                TextField("Card number or code", text: $manualCode)
                    .keyboardType(.default)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if !manualCode.isEmpty {
                        scannedCode = manualCode
                        codeFormat = "Manual"
                        dismiss()
                    }
                }
            } message: {
                Text("Enter the gift card number or barcode")
            }
        }
    }
}

// UIKit wrapper for camera
struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var codeFormat: String?
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerRepresentable
        
        init(_ parent: BarcodeScannerRepresentable) {
            self.parent = parent
        }
        
        func didFindCode(_ code: String, format: String) {
            parent.scannedCode = code
            parent.codeFormat = format
            parent.isScanning = false
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String, format: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [
                .qr,
                .ean8,
                .ean13,
                .pdf417,
                .code128,
                .code39,
                .code93,
                .upce,
                .aztec,
                .dataMatrix,
                .itf14
            ]
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        
        self.captureSession = session
        self.previewLayer = preview
        
        startScanning()
    }
    
    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else {
            return
        }
        
        stopScanning()
        
        let format = formatName(for: object.type)
        delegate?.didFindCode(code, format: format)
    }
    
    private func formatName(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr: return "QR"
        case .ean8: return "EAN-8"
        case .ean13: return "EAN-13"
        case .pdf417: return "PDF417"
        case .code128: return "Code 128"
        case .code39: return "Code 39"
        case .code93: return "Code 93"
        case .upce: return "UPC-E"
        case .aztec: return "Aztec"
        case .dataMatrix: return "Data Matrix"
        case .itf14: return "ITF-14"
        default: return "Unknown"
        }
    }
}

#Preview {
    BarcodeScannerView(scannedCode: .constant(nil), codeFormat: .constant(nil))
}
