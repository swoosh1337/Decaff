import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scannerModel = BarcodeScannerModel()
    @State private var showingProductInfo = false
    @State private var scannedProduct: BarcodeProduct?
    
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
        .fullScreenCover(isPresented: $showingProductInfo) {
            if let product = scannedProduct {
                ProductInfoView(product: product, dismiss: dismiss)
            }
        }
        .onChange(of: scannerModel.scannedCode) { _, newCode in
            guard let code = newCode else { return }
            print("Barcode scanned: \(code)")
            handleScannedCode(code)
        }
        .onAppear {
            scannerModel.startScanning()
        }
        .onDisappear {
            scannerModel.stopScanning()
        }
    }
    
    private func handleScannedCode(_ code: String) {
        print("Handling scanned code: \(code)")
        Task {
            do {
                if let product = try await BarcodeAPI.shared.fetchProduct(barcode: code) {
                    print("Product found: \(product.name)")
                    await MainActor.run {
                        self.scannedProduct = product
                        self.showingProductInfo = true
                        print("Showing product info sheet")
                    }
                }
            } catch {
                print("Error fetching product: \(error)")
            }
        }
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
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.frame = uiView.bounds
        }
    }
}

// Product info view
struct ProductInfoView: View {
    let product: BarcodeProduct
    let dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismissSheet
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .center, spacing: 16) {
                        // Product Image
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                            
                            AsyncImage(url: product.imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(height: 200)
                        
                        // Product Details
                        VStack(spacing: 8) {
                            Text(product.name)
                                .font(.title2)
                                .bold()
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 20) {
                                InfoCard(
                                    title: "Caffeine",
                                    value: "\(product.caffeineContent)",
                                    unit: "mg",
                                    icon: "bolt.fill"
                                )
                                
                                InfoCard(
                                    title: "Volume",
                                    value: "\(product.servingSize)",
                                    unit: "ml",
                                    icon: "drop.fill"
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                    .listRowInsets(EdgeInsets())
                }
                
                Section {
                    Button(action: {
                        addToLog()
                        dismissSheet()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Label("Add to Today's Log", systemImage: "plus.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Scanned Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismissSheet()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addToLog() {
        let entry = CaffeineEntry(
            caffeineAmount: Double(product.caffeineContent),
            beverageName: product.name,
            beverageType: .custom,
            volume: Double(product.servingSize)
        )
        modelContext.insert(entry)
        try? modelContext.save()
        print("Added entry to log: \(product.name)")
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
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .bold()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 

