// CameraPreview.swift
// Fixed camera code for iOS 18.6+
// Location: AyurScan/Components/CameraPreview.swift

import SwiftUI
import AVFoundation
import Combine
import UIKit

// MARK: - Video Orientation Extension
extension AVCaptureVideoOrientation {
    init(uiOrientation: UIInterfaceOrientation) {
        switch uiOrientation {
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: self = .portrait
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            if let connection = view.videoPreviewLayer.connection, connection.isVideoOrientationSupported {
                let orientation = UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
                    .first ?? .portrait
                connection.videoOrientation = AVCaptureVideoOrientation(uiOrientation: orientation)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        DispatchQueue.main.async {
            if let connection = uiView.videoPreviewLayer.connection, connection.isVideoOrientationSupported {
                let orientation = UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
                    .first ?? .portrait
                connection.videoOrientation = AVCaptureVideoOrientation(uiOrientation: orientation)
            }
        }
    }
    
    @MainActor
    static func dismantleUIView(_ uiView: VideoPreviewView, coordinator: ()) {
        uiView.videoPreviewLayer.session = nil
    }
}

// MARK: - Video Preview View
class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Camera Error
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

// MARK: - Camera Setup Error
private enum CameraSetupError: Error {
    case cannotAddInput
    case cannotAddOutput
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = false
    @Published var isCameraReady = false
    @Published var error: CameraError?
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var isCapturing = false
    @Published var isUsingFrontCamera = false
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var isConfigured = false
    
    override init() {
        super.init()
        // Don't call checkPermission here - wait for view to appear
    }
    
    deinit {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    // MARK: - Check Permission
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            if !isConfigured {
                setupCamera()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    } else {
                        self.error = .permissionDenied
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = .permissionDenied
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = .permissionDenied
            }
        }
    }
    
    // MARK: - Setup Camera (FIXED)
    func setupCamera() {
        // Check permission first
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            DispatchQueue.main.async {
                self.error = .permissionDenied
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Prevent multiple configurations
            guard !self.isConfigured else { return }
            
            // Stop if already running
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            self.session.beginConfiguration()
            
            // Reset session
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }
            
            // Set session preset
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }

            // Select back camera
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                }
                return
            }
            
            self.currentDevice = device

            do {
                // Create input
                let input = try AVCaptureDeviceInput(device: device)
                
                guard self.session.canAddInput(input) else {
                    throw CameraSetupError.cannotAddInput
                }
                self.session.addInput(input)
                self.videoDeviceInput = input
                
                // Create output
                self.photoOutput = AVCapturePhotoOutput()
                
                guard self.session.canAddOutput(self.photoOutput) else {
                    throw CameraSetupError.cannotAddOutput
                }
                self.session.addOutput(self.photoOutput)
                
                // Enable high resolution after adding output
                if self.photoOutput.isHighResolutionCaptureEnabled {
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                }

                self.session.commitConfiguration()
                self.isConfigured = true
                
                // Start session
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }

            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.error = .setupFailed
                }
                print("Camera setup error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Capture Photo
    func capturePhoto() {
        guard isCameraReady, !isCapturing else { return }
        
        DispatchQueue.main.async {
            self.isCapturing = true
        }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let settings = AVCapturePhotoSettings()
            
            // Set flash mode if supported
            if self.photoOutput.supportedFlashModes.contains(self.flashMode) {
                settings.flashMode = self.isUsingFrontCamera ? .off : self.flashMode
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - Switch Camera
    func switchCamera() {
        guard isCameraReady else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }
            
            let newPosition: AVCaptureDevice.Position = self.isUsingFrontCamera ? .back : .front
            
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                // Restore previous input
                if let currentInput = self.videoDeviceInput {
                    if self.session.canAddInput(currentInput) {
                        self.session.addInput(currentInput)
                    }
                }
                self.session.commitConfiguration()
                return
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.videoDeviceInput = newInput
                    self.currentDevice = newDevice
                    
                    DispatchQueue.main.async {
                        self.isUsingFrontCamera.toggle()
                    }
                } else {
                    // Restore previous input
                    if let currentInput = self.videoDeviceInput {
                        if self.session.canAddInput(currentInput) {
                            self.session.addInput(currentInput)
                        }
                    }
                }
            } catch {
                // Restore previous input
                if let currentInput = self.videoDeviceInput {
                    if self.session.canAddInput(currentInput) {
                        self.session.addInput(currentInput)
                    }
                }
                print("Switch camera error: \(error.localizedDescription)")
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Toggle Flash
    func toggleFlash() {
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
    }
    
    // MARK: - Start Session
    func startSession() {
        // Check permission when starting
        checkPermission()
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isConfigured && !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    // MARK: - Stop Session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isCapturing = false
            
            if let error = error {
                self.error = .captureFailed
                print("Capture error: \(error.localizedDescription)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.error = .captureFailed
                return
            }
            
            self.capturedImage = image
            
            // Haptic feedback
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    }
}

// MARK: - Custom Camera View
struct CustomCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera Preview
            if cameraManager.isCameraReady {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else if cameraManager.error != nil {
                // Error View
                errorView
            } else {
                // Loading View
                loadingView
            }
            
            // Controls Overlay
            controlsOverlay
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
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            Text(cameraManager.error?.errorDescription ?? "Camera Error")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            if case .permissionDenied = cameraManager.error {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.blue)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Initializing Camera...")
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Controls Overlay
    private var controlsOverlay: some View {
        VStack {
            // Top Bar
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
                
                if !cameraManager.isUsingFrontCamera {
                    Button(action: { cameraManager.toggleFlash() }) {
                        Image(systemName: flashIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // Bottom Bar
            HStack(spacing: 60) {
                // Switch Camera
                Button(action: { cameraManager.switchCamera() }) {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                }
                .disabled(!cameraManager.isCameraReady)
                .opacity(cameraManager.isCameraReady ? 1 : 0.5)
                
                // Capture Button
                Button(action: { cameraManager.capturePhoto() }) {
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
                .disabled(cameraManager.isCapturing || !cameraManager.isCameraReady)
                .opacity(cameraManager.isCameraReady ? 1 : 0.5)
                
                // Placeholder for alignment
                Color.clear
                    .frame(width: 50, height: 50)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Flash Icon
    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .auto: return "bolt.badge.automatic.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.badge.automatic.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    CustomCameraView(capturedImage: .constant(nil))
}
