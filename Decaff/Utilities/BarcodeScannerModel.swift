import AVFoundation
import SwiftUI
import Combine

class BarcodeScannerModel: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var error: Error?
    @Published var currentProduct: OpenFoodFactsProduct?
    @Published var isLoading = false
    
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
        }
        DispatchQueue.main.async { [weak self] in
            self?.isScanning = true
        }
    }
    
    func stopScanning() {
        guard session.isRunning else { return }
        
        print("Stopping scanning session")
        session.stopRunning()
        DispatchQueue.main.async { [weak self] in
            self?.isScanning = false
        }
    }
}

extension BarcodeScannerModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        DispatchQueue.main.async {
            self.scannedCode = stringValue
            self.isLoading = true
            
            OpenFoodFactsService.shared.fetchProduct(barcode: stringValue)
                .sink { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.error = error
                    }
                } receiveValue: { product in
                    self.currentProduct = product
                    self.stopScanning()
                }
                .store(in: &self.cancellables)
        }
    }
}
