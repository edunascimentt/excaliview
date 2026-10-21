APP := build/Build/Products/Release/Excaliview.app
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: web project build install clean

web:
	cd web && npm install && ./build.sh

project:
	xcodegen generate

build: web project
	xcodebuild -project Excaliview.xcodeproj -scheme Excaliview -configuration Release -derivedDataPath build build

# Copies the app to /Applications, registers both extensions and resets Quick Look caches.
# The build copy is unregistered so the repo folder can be deleted afterwards.
install: build
	-pkill -f ExcaliviewPreview; pkill -f ExcaliviewThumbnail
	rm -rf /Applications/Excaliview.app
	cp -R $(APP) /Applications/
	-$(LSREGISTER) -u $(APP)
	$(LSREGISTER) -f /Applications/Excaliview.app
	pluginkit -a /Applications/Excaliview.app/Contents/PlugIns/ExcaliviewPreview.appex
	pluginkit -a /Applications/Excaliview.app/Contents/PlugIns/ExcaliviewThumbnail.appex
	qlmanage -r >/dev/null; qlmanage -r cache >/dev/null

clean:
	rm -rf build Shared/Web Excaliview.xcodeproj
