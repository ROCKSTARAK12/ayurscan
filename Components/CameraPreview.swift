import SwiftUI
import AVFoundation
import Combine

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = false
    @Published var isCameraReady = false
    @Published var error: CameraError?
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var isCapturing = false
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var isUsingFrontCamera = false
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            error = .permissionDenied
        @unknown default:
            isAuthorized = false
        }
    }
    
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            error = .cameraUnavailable
            return
        }
        
        currentDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            session.commitConfiguration()
            isCameraReady = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } catch {
            self.error = .setupFailed
        }
    }
    
    func capturePhoto() {
        guard isCameraReady, !isCapturing else { return }
        
        isCapturing = true
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func switchCamera() {
        guard isCameraReady else { return }
        
        session.beginConfiguration()
        
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = isUsingFrontCamera ? .back : .front
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentDevice = newDevice
                isUsingFrontCamera.toggle()
            } else {
                session.addInput(currentInput)
            }
        } catch {
            session.addInput(currentInput)
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.isCapturing = false
            
            if let error = error {
                self.error = .captureFailed
                print("Capture error: \(error)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.error = .captureFailed
                return
            }
            
            self.capturedImage = image
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    }
}

enum CameraError: LocalizedError {
    case permissionDenied
    case cameraUnavailable
    case setupFailed
    case captureFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied. Please enable in Settings."
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .setupFailed:
            return "Failed to setup camera."
        case .captureFailed:
            return "Failed to capture photo."
        }
    }
}

struct CustomCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraManager.isCameraReady {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Initializing Camera...")
                        .foregroundColor(.white)
                }
            }
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { cameraManager.toggleFlash() }) {
                        Image(systemName: flashIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                HStack(spacing: 60) {
                    Button(action: { cameraManager.switchCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                    }
                    
                    Button(action: {
                        cameraManager.capturePhoto()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 75, height: 75)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 65, height: 65)
                                .scaleEffect(cameraManager.isCapturing ? 0.9 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: cameraManager.isCapturing)
                        }
                    }
                    .disabled(cameraManager.isCapturing)
                    
                    Color.clear
                        .frame(width: 50, height: 50)
                }
                .padding(.bottom, 40)
            }
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage {
                capturedImage = image
                dismiss()
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .auto: return "bolt.badge.automatic.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.badge.automatic.fill"
        }
    }
}

#Preview {
    CustomCameraView(capturedImage: .constant(nil))
}
