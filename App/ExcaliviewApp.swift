import SwiftUI

@main
struct ExcaliviewApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("Excaliview").font(.largeTitle.bold())
                Text("Quick Look support for .excalidraw files is installed.")
                Text("Select a .excalidraw file in Finder and press Space to preview it. Finder icons show a thumbnail of the drawing.")
                    .foregroundStyle(.secondary)
                Text("If previews don't show up, make sure the extensions are enabled in System Settings → General → Login Items & Extensions → Quick Look.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .frame(width: 480)
            .fixedSize()
        }
        .windowResizability(.contentSize)
    }
}
