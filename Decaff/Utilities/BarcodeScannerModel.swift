import AVFoundation
import SwiftUI
import Combine

class BarcodeScannerModel: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var error: Error?
    
    let session = AVCaptureSession()
    private let metadataQueue = DispatchQueue(label: "com.decaff.barcodescanner.metadata")
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        print("Initializing scanner model")
        setupCamera()
    }
    
    private func setupCamera() {
        print("Setting up camera")
        // Start with session configuration
        session.beginConfiguration()
        
        // Add video input
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No video device found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                print("Added video input")
            }
            
            // Add metadata output
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: metadataQueue)
                output.metadataObjectTypes = [.ean8, .ean13, .upce]
                print("Added metadata output")
            }
            
            // Commit configuration
            session.commitConfiguration()
            print("Camera setup completed")
            
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func startScanning() {
        print("Starting scanning session")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isScanning = true
                print("Scanning started")
            }
        }
    }
    
    func stopScanning() {
        print("Stopping scanning session")
        session.stopRunning()
        DispatchQueue.main.async { [weak self] in
            self?.isScanning = false
        }
    }
}

extension BarcodeScannerModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = metadataObject.stringValue {
            print("Barcode detected: \(code)")
            DispatchQueue.main.async { [weak self] in
                self?.scannedCode = code
                self?.stopScanning()
            }
        }
    }
}

struct BarcodeProduct: Identifiable {
    let id = UUID()
    let name: String
    let caffeineContent: Int
    let servingSize: Int
    let imageURL: URL?
    let barcode: String
}

class BarcodeAPI {
    static let shared = BarcodeAPI()
    
    private init() {}
    
    func fetchProduct(barcode: String) async throws -> BarcodeProduct? {
        print("🔍 Fetching product for barcode: \(barcode)")
        
        // Mock data for testing
        let product: BarcodeProduct
        switch barcode {
        case "5449000000996":  // Regular Coca-Cola
            product = BarcodeProduct(
                name: "Coca-Cola Classic",
                caffeineContent: 32,
                servingSize: 330,
                imageURL: URL(string: "https://world.openfoodfacts.org/images/products/544/900/000/0996/front_en.248.400.jpg"),
                barcode: barcode
            )
        case "9002490100070":  // Red Bull
            product = BarcodeProduct(
                name: "Red Bull Energy Drink",
                caffeineContent: 80,
                servingSize: 250,
                imageURL: URL(string: "https://world.openfoodfacts.org/images/products/900/249/010/0070/front_en.191.400.jpg"),
                barcode: barcode
            )
        default:  // Generic energy drink
            product = BarcodeProduct(
                name: "Energy Drink",
                caffeineContent: 80,
                servingSize: 250,
                imageURL: nil,
                barcode: barcode
            )
        }
        
        print("📦 Product found: \(product.name)")
        return product
    }
} 
