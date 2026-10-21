import AppKit
import OSLog
import WebKit

let log = Logger(subsystem: "com.edunascimentt.excaliview", category: "render")

/// Renders .excalidraw files with the official Excalidraw library running in a WKWebView.
/// The bundled web assets (render.js, fonts) are served through a custom URL scheme so
/// Excalidraw can fetch and inline its fonts without network access.
@MainActor
final class ExcalidrawRenderer: NSObject, WKNavigationDelegate {
    static let scheme = "excaliview"

    let webView: WKWebView
    private var loadContinuation: CheckedContinuation<Void, Error>?

    override init() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: Self.scheme)
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
        super.init()
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
    }

    struct RenderError: Error { let message: String }

    /// Loads the renderer page and draws the given file. Returns the drawing's natural size.
    /// The page shows an inline message for unreadable drawings; `throwOnInvalid` also throws.
    func render(fileAt url: URL, dark: Bool, throwOnInvalid: Bool = false) async throws -> CGSize {
        let text = try String(contentsOf: url, encoding: .utf8)
        log.info("Loading renderer page for \(url.lastPathComponent, privacy: .public)")
        try await loadPage()
        log.info("Renderer page loaded")
        let result = try await webView.callAsyncJavaScript(
            "return await window.renderExcalidraw(text, dark);",
            arguments: ["text": text, "dark": dark],
            contentWorld: .page
        )
        log.info("Render finished: \(String(describing: result), privacy: .public)")
        let dict = result as? [String: Any] ?? [:]
        if throwOnInvalid, let message = dict["error"] as? String {
            throw RenderError(message: message)
        }
        let width = (dict["width"] as? NSNumber)?.doubleValue ?? 800
        let height = (dict["height"] as? NSNumber)?.doubleValue ?? 600
        return CGSize(width: max(width, 1), height: max(height, 1))
    }

    private func loadPage() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadContinuation = continuation
            webView.load(URLRequest(url: URL(string: "\(Self.scheme)://app/index.html")!))
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MainActor.assumeIsolated { finishLoad(nil) }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        MainActor.assumeIsolated { finishLoad(error) }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        MainActor.assumeIsolated { finishLoad(error) }
    }

    nonisolated func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        MainActor.assumeIsolated {
            log.error("WebContent process terminated")
            finishLoad(URLError(.cancelled))
        }
    }

    private func finishLoad(_ error: Error?) {
        if let error { log.error("Page load failed: \(error.localizedDescription, privacy: .public)") }
        guard let continuation = loadContinuation else { return }
        loadContinuation = nil
        if let error { continuation.resume(throwing: error) } else { continuation.resume() }
    }
}

/// Serves files from the bundle's Web folder for excaliview://app/<path>.
private final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    private let root = Bundle(for: BundleSchemeHandler.self).resourceURL!.appendingPathComponent("Web")

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        let fileURL = root.appendingPathComponent(url.path).standardizedFileURL
        guard fileURL.path.hasPrefix(root.standardizedFileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            log.error("Missing resource \(url.path, privacy: .public)")
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": Self.mimeType(for: fileURL.pathExtension),
                "Content-Length": String(data.count),
                "Access-Control-Allow-Origin": "*",
            ]
        )!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext {
        case "html": return "text/html; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "woff2": return "font/woff2"
        case "wasm": return "application/wasm"
        default: return "application/octet-stream"
        }
    }
}
