import SwiftUI

/// Invisible host that presents whatever GameKit hands us (the auth sheet, the
/// turn-based matchmaker) modally. Embed it once, near the root of the view tree.
struct GameKitViewControllerPresenter: UIViewControllerRepresentable {
    @ObservedObject var manager: GameCenterManager

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let vc = manager.presentedViewController {
            guard uiViewController.presentedViewController == nil else { return }
            uiViewController.present(vc, animated: true)
        } else if uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: true)
        }
    }
}
