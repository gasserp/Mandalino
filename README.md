# Mandolino

An offline, iPad-only coloring app for ages 4-10. Version 1 includes 96 original classic and animal coloring pages: 24 each in Easy, Medium, Hard, and Expert. Twenty colors, a child-friendly two-color mixer, textured glitter with animated twinkles, a color eraser, and a free-draw page with black pencil lines, circles, rectangles, and triangles are included. Expert pages contain at least 150 enclosed coloring spaces for a substantially harder challenge. Collection variations have distinct outlines, ring counts, and jewel patterns rather than renamed duplicates.

German is the default language. Switch to English in the gallery or with the globe button in the editor; the choice is saved. The color mixer automatically moves from choosing the first color to the second, previews the result, and puts the new color in your brush. Familiar primary combinations produce orange, green, and purple. The eraser removes a region's color and glitter, leaving its black outlines intact; erasing can be undone. Animated twinkles respect the iPad's Reduce Motion setting, and exported images retain the glitter texture.

Select a color and tap inside a black outline to fill the whole connected space. Pinch the paper to zoom up to 4x for tiny details; use two fingers to move around the zoomed page. On the free-draw page, drag to draw lines or shapes, then select a color to switch to Fill. Freehand outlines must be closed; gaps connect spaces. Undo/redo supports the last twelve actions. Clear asks for confirmation and is undoable. Each page saves locally and automatically, including editable free-draw outlines. Share exports the current drawing as an image using the iPad share sheet. No accounts, advertising, analytics, network requests, or third-party dependencies.

## Build and test

Requires Xcode with an iOS 17 or newer SDK. The checked-in Xcode project is ready to open. `project.yml` is its XcodeGen source; regenerate with `xcodegen generate` after changing target configuration.

```sh
xcodebuild -project Mandolino.xcodeproj -scheme Mandolino \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -derivedDataPath build test CODE_SIGNING_ALLOWED=NO
```

For a physical iPad, select your Apple Development team in Signing & Capabilities, pair/trust the device in Xcode, enable Developer Mode, and select it as the run destination. Wireless installation requires an active Xcode network pairing. Development profiles expire according to the Apple account type; this is not an App Store distribution.

Drawings are stored in the app's Documents/Drawings directory. Deleting the app deletes its local drawings; use Share to keep exported images.
