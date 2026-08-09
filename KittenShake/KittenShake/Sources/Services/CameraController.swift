import AVFoundation
import UIKit
import SwiftUI
import Combine

/// A thin AVFoundation capture-session wrapper powering the custom camera
/// screen (`CameraCaptureView`). Deliberately avoids `UIImagePickerController`
/// so the mockup's custom chrome (flash/flip/shutter over a live preview)
/// is possible. Gracefully reports unavailability on devices with no camera
/// (the iOS Simulator) instead of crashing.
/// Not `@MainActor`-isolated: `start()`/`flip()` dispatch the actual
/// `AVCaptureSession` configuration to a private serial background queue
/// (as Apple recommends, since session configuration can block), then hop
/// back to the main actor only to publish the resulting `@Published` state.
final class CameraController: NSObject, ObservableObject {
    enum FlashMode: CaseIterable {
        case auto, on, off

        var avMode: AVCaptureDevice.FlashMode {
            switch self {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }

        var systemImage: String {
            switch self {
            case .auto: return "bolt.badge.a.fill"
            case .on: return "bolt.fill"
            case .off: return "bolt.slash.fill"
            }
        }
    }

    let session = AVCaptureSession()

    /// `false` when the device has no camera at all (Simulator) — callers
    /// should show a placeholder instead of the live preview.
    @Published private(set) var isAvailable = true
    @Published private(set) var isRunning = false
    @Published var flashMode: FlashMode = .auto
    @Published private(set) var position: AVCaptureDevice.Position = .back
    @Published var capturedImage: UIImage?

    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.kenzoragames.kittenshake.camera-session")
    private var didConfigure = false

    func start() {
        guard AVCaptureDevice.default(for: .video) != nil else {
            isAvailable = false
            return
        }
        isAvailable = true

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.didConfigure {
                self.configureSession()
            }
            self.session.startRunning()
            let running = self.session.isRunning
            Task { @MainActor in self.isRunning = running }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.stopRunning()
            Task { @MainActor in self.isRunning = false }
        }
    }

    /// Must run on `sessionQueue`.
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let input = try? Self.deviceInput(for: position) {
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
            }
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
        didConfigure = true
    }

    private static func deviceInput(for position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try AVCaptureDeviceInput(device: device)
    }

    func flip() {
        guard isAvailable else { return }
        let newPosition: AVCaptureDevice.Position = position == .back ? .front : .back
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let newInput = try? Self.deviceInput(for: newPosition) else { return }
            self.session.beginConfiguration()
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
            }
            self.session.commitConfiguration()
            Task { @MainActor in self.position = newPosition }
        }
    }

    func cycleFlash() {
        let all = FlashMode.allCases
        let idx = all.firstIndex(of: flashMode) ?? 0
        flashMode = all[(idx + 1) % all.count]
    }

    func capturePhoto() {
        guard isAvailable, isRunning else { return }
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(flashMode.avMode) {
            settings.flashMode = flashMode.avMode
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor [weak self] in
            self?.capturedImage = image
        }
    }
}

/// Full-bleed live preview backed by `AVCaptureVideoPreviewLayer`.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}
