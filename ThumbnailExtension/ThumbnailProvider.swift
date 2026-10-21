import AppKit
import QuickLookThumbnailing
import WebKit

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        Task { @MainActor in
            do {
                let image = try await Self.snapshot(of: request.fileURL, maximumSize: request.maximumSize)
                let reply = QLThumbnailReply(contextSize: image.size) {
                    image.draw(in: NSRect(origin: .zero, size: image.size))
                    return true
                }
                handler(reply, nil)
            } catch {
                handler(nil, error)
            }
        }
    }

    @MainActor
    private static func snapshot(of url: URL, maximumSize: CGSize) async throws -> NSImage {
        let renderer = ExcalidrawRenderer()
        // WKWebView only paints while it is in a window, so host it in an offscreen one.
        let window = NSWindow(contentRect: NSRect(x: -10_000, y: -10_000, width: 800, height: 600),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = renderer.webView
        defer { window.contentView = nil }

        let natural = try await renderer.render(fileAt: url, dark: false, throwOnInvalid: true)
        let scale = min(maximumSize.width / natural.width, maximumSize.height / natural.height)
        let size = CGSize(width: max(natural.width * scale, 1).rounded(), height: max(natural.height * scale, 1).rounded())
        window.setContentSize(size)
        renderer.webView.frame = NSRect(origin: .zero, size: size)
        // Give WebKit a moment to lay out and paint at the new size.
        try await Task.sleep(for: .milliseconds(150))

        let config = WKSnapshotConfiguration()
        config.rect = NSRect(origin: .zero, size: size)
        config.snapshotWidth = NSNumber(value: Double(size.width))
        return try await renderer.webView.takeSnapshot(configuration: config)
    }
}
