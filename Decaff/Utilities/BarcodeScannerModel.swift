import AVFoundation
import SwiftUI
import Combine

class BarcodeScannerModel: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var error: Error?
    
    let session = AVCaptureSession()
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
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
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
        isScanning = false
    }
}

extension BarcodeScannerModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = metadataObject.stringValue {
            print("Barcode detected: \(code)")
            scannedCode = code
            stopScanning()
        }
    }
}

struct BarcodeProduct {
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
        // TODO: Implement actual API call to Open Food Facts or similar
        // For now, return mock data
        return BarcodeProduct(
            name: "Red Bull Energy Drink",
            caffeineContent: 80,
            servingSize: 250,
            imageURL: URL(string: "https://example.com/redbull.jpg"),
            barcode: barcode
        )
    }
} 
