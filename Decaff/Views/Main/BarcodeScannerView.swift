import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannerModel = BarcodeScannerModel()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCaffeineAlert = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Camera view
                    CameraPreview(session: scannerModel.session)
                        .ignoresSafeArea()
                    
                    // Scanning overlay
                    ScanningOverlayView(isScanning: scannerModel.isScanning, geometry: geometry)
                    
                    // Instructions
                    InstructionsOverlayView(isLoading: scannerModel.isLoading)
                }
            }
            .background(Color.black)
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        scannerModel.stopScanning()
                        scannerModel.currentProduct = nil
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(item: $scannerModel.currentProduct) { product in
            ProductDetailSheet(product: product, showCaffeineAlert: $showCaffeineAlert, onAdd: {
                addToLog(product: product)
                dismiss()
            }, onCancel: {
                scannerModel.stopScanning()
                scannerModel.currentProduct = nil
                dismiss()
            })
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
    
    private func addToLog(product: NutritionixProduct) {
        guard let caffeineContent = product.nfCaffeine else { return }
        
        print("📝 Adding product to log: \(product.foodName)")
        
        let entry = CaffeineEntry(
            caffeineAmount: caffeineContent,
            beverageName: product.brandName != nil ? "\(product.brandName!) \(product.foodName)" : product.foodName,
            beverageType: .custom,
            volume: product.servingQuantity
        )
        
        modelContext.insert(entry)
        try? modelContext.save()
        print("✅ Entry added to log: \(product.foodName) with \(caffeineContent)mg caffeine")
    }
}

// MARK: - Supporting Views

struct ScanningOverlayView: View {
    let isScanning: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.2)
                .overlay {
                    if isScanning {
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .animation(.easeInOut(duration: 1).repeatForever(), value: isScanning)
                    }
                }
            Spacer()
        }
    }
}

struct InstructionsOverlayView: View {
    let isLoading: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                        .padding()
                        .background(.black.opacity(0.7))
                        .cornerRadius(8)
                } else {
                    Text("Position barcode within frame")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(.black.opacity(0.7))
                        .cornerRadius(8)
                }
            }
            .padding(.bottom, 50)
            .padding(.horizontal)
        }
    }
}

struct ProductDetailSheet: View {
    let product: NutritionixProduct
    @Binding var showCaffeineAlert: Bool
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let photoURL = product.photoURL,
                   let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    } placeholder: {
                        ProgressView()
                    }
                    .padding()
                }
                
                Text(product.foodName)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let brand = product.brandName {
                    Text(brand)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text("Serving: \(String(format: "%.1f", product.servingQuantity)) \(product.servingUnit)")
                
                if let caffeine = product.nfCaffeine {
                    Text("Caffeine: \(Int(caffeine))mg")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                } else {
                    Text("Caffeine content not available")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Add to Log") {
                        if product.nfCaffeine != nil {
                            onAdd()
                        } else {
                            showCaffeineAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel", role: .cancel, action: onCancel)
                        .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Missing Caffeine Content", isPresented: $showCaffeineAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This product doesn't have caffeine content information available.")
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) { }
}
