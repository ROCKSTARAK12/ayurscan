// CameraPreview.swift - FINAL FIXED
// Replace your entire CameraPreview.swift with this
// Location: AyurScan/Components/CameraPreview.swift

import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - UIImage Extension (API Ready)
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img ?? self
    }
    
    func preparedForAPI(maxDimension: CGFloat = 1024, quality: CGFloat = 0.85) -> UIImage {
        let oriented = fixedOrientation()
        let origSize = oriented.size
        var newSize = origSize
        
        if origSize.width > maxDimension || origSize.height > maxDimension {
            let ratio = min(maxDimension / origSize.width, maxDimension / origSize.height)
            newSize = CGSize(width: origSize.width * ratio, height: origSize.height * ratio)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        oriented.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized ?? oriented
    }
}

// MARK: - Video Orientation
extension AVCaptureVideoOrientation {
    init(ui: UIInterfaceOrientation) {
        switch ui {
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: self = .portrait
        }
    }
    init(device: UIDeviceOrientation) {
        switch device {
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: self = .portrait
        }
    }
}

// MARK: - Preview View
class VideoPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> VideoPreviewView {
        let v = VideoPreviewView()
        v.backgroundColor = .black
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ v: VideoPreviewView, context: Context) {}
}

// MARK: - Camera Error
enum CameraError: LocalizedError {
    case permissionDenied, cameraUnavailable, setupFailed, captureFailed
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Camera permission denied"
        case .cameraUnavailable: return "Camera unavailable"
        case .setupFailed: return "Setup failed"
        case .captureFailed: return "Capture failed"
        }
    }
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
    private let queue = DispatchQueue(label: "cam.q", qos: .userInitiated)
    private var photoOutput = AVCapturePhotoOutput()
    private var input: AVCaptureDeviceInput?
    private var configured = false
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isAuthorized = true }
            if !configured { setup() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                DispatchQueue.main.async {
                    self?.isAuthorized = ok
                    if ok { self?.setup() } else { self?.error = .permissionDenied }
                }
            }
        default:
            DispatchQueue.main.async { self.error = .permissionDenied }
        }
    }
    
    func setup() {
        queue.async { [weak self] in
            guard let self = self, !self.configured else { return }
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            if self.session.canSetSessionPreset(.photo) { self.session.sessionPreset = .photo }
            
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let inp = try? AVCaptureDeviceInput(device: dev),
                  self.session.canAddInput(inp) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.error = .cameraUnavailable }
                return
            }
            self.session.addInput(inp)
            self.input = inp
            
            guard self.session.canAddOutput(self.photoOutput) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.error = .setupFailed }
                return
            }
            self.session.addOutput(self.photoOutput)
            self.photoOutput.isHighResolutionCaptureEnabled = true
            
            self.session.commitConfiguration()
            self.configured = true
            self.session.startRunning()
            DispatchQueue.main.async { self.isCameraReady = true }
        }
    }
    
    func capture() {
        guard isCameraReady, !isCapturing else { return }
        DispatchQueue.main.async { self.isCapturing = true }
        queue.async { [weak self] in
            guard let self = self else { return }
            let settings = AVCapturePhotoSettings()
            if self.photoOutput.supportedFlashModes.contains(self.flashMode) {
                settings.flashMode = self.isUsingFrontCamera ? .off : self.flashMode
            }
            if let conn = self.photoOutput.connection(with: .video), conn.isVideoOrientationSupported {
                conn.videoOrientation = AVCaptureVideoOrientation(device: UIDevice.current.orientation)
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func switchCam() {
        guard isCameraReady else { return }
        queue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            if let inp = self.input { self.session.removeInput(inp) }
            let pos: AVCaptureDevice.Position = self.isUsingFrontCamera ? .back : .front
            if let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
               let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp) {
                self.session.addInput(inp)
                self.input = inp
                DispatchQueue.main.async { self.isUsingFrontCamera.toggle() }
            } else if let inp = self.input, self.session.canAddInput(inp) {
                self.session.addInput(inp)
            }
            self.session.commitConfiguration()
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .auto ? .on : flashMode == .on ? .off : .auto
    }
    
    func start() { checkPermission() }
    func stop() { queue.async { [weak self] in self?.session.stopRunning() } }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ o: AVCapturePhotoOutput, didFinishProcessingPhoto p: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isCapturing = false
            guard let data = p.fileDataRepresentation(), let img = UIImage(data: data) else {
                self?.error = .captureFailed
                return
            }
            // ⭐ FIX: Process image for API
            self?.capturedImage = img.preparedForAPI()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Custom Camera View
struct CustomCameraView: View {
    @StateObject private var cam = CameraManager()
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if cam.isCameraReady {
                CameraPreviewView(session: cam.session).ignoresSafeArea()
            } else if cam.error != nil {
                VStack {
                    Image(systemName: "camera.fill").font(.system(size: 50)).foregroundColor(.white)
                    Text(cam.error?.errorDescription ?? "Error").foregroundColor(.white)
                }
            } else {
                ProgressView().tint(.white)
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.title2).foregroundColor(.white)
                            .frame(width: 44, height: 44).background(.ultraThinMaterial).clipShape(Circle())
                    }
                    Spacer()
                    if !cam.isUsingFrontCamera {
                        Button { cam.toggleFlash() } label: {
                            Image(systemName: cam.flashMode == .auto ? "bolt.badge.automatic.fill" : cam.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                                .font(.title2).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(.ultraThinMaterial).clipShape(Circle())
                        }
                    }
                }.padding()
                Spacer()
                HStack(spacing: 60) {
                    Button { cam.switchCam() } label: {
                        Image(systemName: "camera.rotate.fill").font(.title).foregroundColor(.white)
                    }
                    Button { cam.capture() } label: {
                        ZStack {
                            Circle().stroke(.white, lineWidth: 4).frame(width: 75, height: 75)
                            Circle().fill(.white).frame(width: 65, height: 65)
                        }
                    }.disabled(cam.isCapturing)
                    Color.clear.frame(width: 50)
                }.padding(.bottom, 40)
            }
        }
        .onChange(of: cam.capturedImage) { _, img in
            if let img = img { capturedImage = img; dismiss() }
        }
        .onAppear { cam.start() }
        .onDisappear { cam.stop() }
    }
}
