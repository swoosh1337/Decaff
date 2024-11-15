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
        .sheet(isPresented: $showingProductInfo) {
            if let product = scannedProduct {
                ProductInfoView(product: product, dismiss: dismiss)
            }
        }
        .onChange(of: scannerModel.scannedCode) { _, newCode in
            guard let code = newCode else { return }
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
        // Temporarily using mock data - replace with actual API call
        Task {
            do {
                if let product = try await BarcodeAPI.shared.fetchProduct(barcode: code) {
                    await MainActor.run {
                        scannedProduct = product
                        showingProductInfo = true
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
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        AsyncImage(url: product.imageURL) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text("\(product.caffeineContent) mg caffeine")
                                .foregroundColor(.secondary)
                            Text("\(product.servingSize) ml")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button("Add to Today's Log") {
                        addToLog()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
    }
} 

