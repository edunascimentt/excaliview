import Cocoa
import Quartz
import WebKit

final class PreviewViewController: NSViewController, QLPreviewingController {
    private let renderer = ExcalidrawRenderer()

    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        renderer.webView.autoresizingMask = [.width, .height]
        view = renderer.webView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        let dark = view.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        Task { @MainActor in
            do {
                let size = try await renderer.render(fileAt: url, dark: dark)
                preferredContentSize = Self.fit(size, in: CGSize(width: 1200, height: 900))
                handler(nil)
            } catch {
                handler(error)
            }
        }
    }

    private static func fit(_ size: CGSize, in bounds: CGSize) -> CGSize {
        let scale = min(bounds.width / size.width, bounds.height / size.height, 1)
        return CGSize(width: max(size.width * scale, 320), height: max(size.height * scale, 240))
    }
}
