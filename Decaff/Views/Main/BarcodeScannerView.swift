import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannerModel = BarcodeScannerModel()
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Camera view
                    CameraPreview(session: scannerModel.session)
                        .ignoresSafeArea()
                    
                    // Scanning overlay
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white, lineWidth: 2)
                            .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.2)
                            .overlay {
                                if scannerModel.isScanning {
                                    Rectangle()
                                        .fill(.white.opacity(0.2))
                                        .animation(.easeInOut(duration: 1).repeatForever(), value: scannerModel.isScanning)
                                }
                            }
                        Spacer()
                    }
                    
                    // Instructions
                    VStack {
                        Spacer()
                        Text("Position barcode within frame")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(.bottom, 50)
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(item: $scannerModel.currentProduct) { product in
            ProductInfoView(product: product, dismiss: dismiss)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: scannerModel.error.map { $0.localizedDescription }) { description in
            showError = description != nil
            errorMessage = description ?? ""
        }
        .onAppear {
            print("📸 Scanner view appeared")
            scannerModel.startScanning()
        }
        .onDisappear {
            print("🚫 Scanner view disappeared")
            scannerModel.stopScanning()
        }
    }
    
    private func addToLog(name: String, quantity: String) {
        print("📝 Adding product to log: \(name)")
        // Extract numeric value from quantity string (e.g., "330 ml" -> 330)
        let numericQuantity = quantity.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        let volume = Double(numericQuantity) ?? 0
        
        let entry = CaffeineEntry(
            caffeineAmount: 0, // We don't have caffeine info from OpenFoodFacts
            beverageName: name,
            beverageType: .custom,
            volume: volume
        )
        modelContext.insert(entry)
        try? modelContext.save()
        print("✅ Entry added to log")
    }
}

// Camera preview using AVFoundation
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
            
            // Ensure proper orientation
            if let connection = videoPreviewLayer.connection {
                let orientation = UIDevice.current.orientation
                let previewLayerConnection = connection
                
                if previewLayerConnection.isVideoOrientationSupported {
                    switch orientation {
                    case .portrait:
                        previewLayerConnection.videoOrientation = .portrait
                    case .landscapeRight:
                        previewLayerConnection.videoOrientation = .landscapeLeft
                    case .landscapeLeft:
                        previewLayerConnection.videoOrientation = .landscapeRight
                    case .portraitUpsideDown:
                        previewLayerConnection.videoOrientation = .portraitUpsideDown
                    default:
                        previewLayerConnection.videoOrientation = .portrait
                    }
                }
            }
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.setNeedsLayout()
    }
}

// Product info view
struct ProductInfoView: View {
    let product: OpenFoodFactsProduct
    let dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismissSheet
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Product Image
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        
                        if let imageUrl = product.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 40))
                            }
                        } else {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 40))
                        }
                    }
                    .frame(height: 200)
                    
                    // Product Details
                    VStack(spacing: 8) {
                        Text(product.productName ?? "Unknown Product")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            InfoCard(
                                title: "Serving",
                                value: product.quantity ?? "Unknown",
                                unit: "",
                                icon: "drop.fill"
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismissSheet()
                },
                trailing: Button("Add") {
                    addToLog()
                    dismissSheet()
                }
            )
        }
    }
    
    private func addToLog() {
        let entry = CaffeineEntry(
            caffeineAmount: 0, // No caffeine info from OpenFoodFacts
            beverageName: product.productName ?? "Unknown Product",
            beverageType: .custom,
            volume: 0 // We don't have standardized volume information
        )
        modelContext.insert(entry)
        try? modelContext.save()
        print("Added entry to log: \(product.productName ?? "Unknown Product")")
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(value)\(unit.isEmpty ? "" : " \(unit)")")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
