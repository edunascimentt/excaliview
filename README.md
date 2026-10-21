# Excaliview

Quick Look support for `.excalidraw` files on macOS: press Space in Finder to preview a drawing, and Finder icons show a thumbnail of it.

Rendering uses the official `@excalidraw/excalidraw` library (`exportToSvg`) inside a `WKWebView`, so output matches excalidraw.com, including the hand-drawn fonts. All assets (JS bundle and fonts) ship inside the app and are served through a custom `excaliview://` URL scheme; a Content-Security-Policy blocks any network request.

## Layout

- `App/` – minimal host app (only needed to carry the extensions and declare the `com.excalidraw.excalidraw` UTI)
- `PreviewExtension/` – Quick Look preview (Space bar), follows system light/dark mode
- `ThumbnailExtension/` – Finder thumbnails, rendered offscreen and snapshotted
- `Shared/Sources/ExcalidrawRenderer.swift` – WKWebView renderer + bundle scheme handler used by both extensions
- `web/` – renderer page and esbuild bundle script (outputs to `Shared/Web/`)
- `project.yml` – XcodeGen spec

## Build & install

Requires Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Node.

```sh
make install
```

Then select a `.excalidraw` file in Finder and press Space. If nothing shows up, check System Settings → General → Login Items & Extensions → Quick Look and make sure the Excaliview extensions are enabled.

Signing uses the "Apple Development" identity and team set in `project.yml`.

## Debugging

```sh
qlmanage -t -s 512 -o /tmp samples/sample.excalidraw   # thumbnail to a PNG
qlmanage -p samples/sample.excalidraw                  # preview window
/usr/bin/log show --last 2m --info --predicate 'subsystem == "com.edunascimentt.excaliview"'
```
