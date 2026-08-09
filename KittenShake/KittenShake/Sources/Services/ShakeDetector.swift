import SwiftUI
import UIKit

/// A UIViewController that becomes first responder so it receives
/// `motionEnded` shake events from UIKit, then forwards them to SwiftUI.
private final class ShakeDetectingViewController: UIViewController {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}

/// Invisible SwiftUI wrapper that detects physical device shakes and calls
/// `onShake`. Place it in `.background()` of the editor canvas.
struct ShakeDetectorView: UIViewControllerRepresentable {
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ShakeDetectingViewController()
        controller.onShake = onShake
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? ShakeDetectingViewController)?.onShake = onShake
    }
}
