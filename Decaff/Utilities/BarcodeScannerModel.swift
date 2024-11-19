import AVFoundation
import SwiftUI
import Combine

class BarcodeScannerModel: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var error: Error?
    @Published var currentProduct: NutritionixProduct?
    @Published var isLoading = false
    
    let session = AVCaptureSession()
    private let metadataQueue = DispatchQueue(label: "com.decaff.barcodescanner.metadata")
    private var cancellables = Set<AnyCancellable>()
    private var lastScannedCode: String?
    
    override init() {
        super.init()
        print("Initializing scanner model")
        setupCamera()
    }
    
    private func setupCamera() {
        print("Setting up camera")
        session.beginConfiguration()
        
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
            
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: metadataQueue)
                output.metadataObjectTypes = [.ean8, .ean13, .upce]
                print("Added metadata output")
            }
            
            session.commitConfiguration()
            print("Camera setup completed")
            
        } catch {
            self.error = error
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    func startScanning() {
        guard !session.isRunning else { return }
        
        print("Starting scanning session")
        metadataQueue.async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.isScanning = true
                self?.lastScannedCode = nil
                self?.error = nil
                self?.currentProduct = nil
            }
        }
    }
    
    func stopScanning() {
        guard session.isRunning else { return }
        
        print("Stopping scanning session")
        metadataQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { [weak self] in
                self?.isScanning = false
                self?.currentProduct = nil
                self?.scannedCode = nil
                self?.error = nil
                self?.lastScannedCode = nil
            }
        }
    }
}

extension BarcodeScannerModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue,
              lastScannedCode != stringValue else { return }
        
        lastScannedCode = stringValue
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.scannedCode = stringValue
            self.isLoading = true
            
            Task {
                do {
                    let product = try await NutritionixService.shared.searchByUPC(stringValue)
                    self.currentProduct = product
                    self.isLoading = false
                    print("✅ Found product: \(product.foodName)")
                } catch NutritionixError.productNotFound {
                    self.error = NSError(domain: "com.decaff", code: 404, userInfo: [
                        NSLocalizedDescriptionKey: "Product not found in database"
                    ])
                    self.lastScannedCode = nil // Allow rescanning
                    self.isLoading = false
                    print("❌ Product not found")
                } catch {
                    self.error = error
                    self.lastScannedCode = nil // Allow rescanning
                    self.isLoading = false
                    print("❌ Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
