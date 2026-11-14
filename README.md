# Mandolino

An offline, iPad-only coloring app for ages 4-10. Version 1 includes 96 original classic and animal coloring pages: 24 each in Easy, Medium, Hard, and Expert. Forty colors, a multi-color mixer with adjustable amounts, five glitter/crystal finishes with animated twinkles, a color eraser, and colored freestyle drawing on every page are included. Black pencil lines, circles, rectangles, and triangles remain available as outline tools. Expert pages contain at least 150 enclosed coloring spaces for a substantially harder challenge. Collection variations have distinct outlines, ring counts, and jewel patterns rather than renamed duplicates. Gallery previews show the actual saved artwork, including free drawing and glitter textures, and refresh when you return from coloring.

German is the default language. Switch to English in the gallery or with the globe button in the editor; the choice is saved. Swipe the two-row color box horizontally to reach all forty colors. The color mixer automatically moves from choosing the first color to the second. Add more colors, adjust each ingredient's parts with its slider, and see its percentage of the mixture and a live result. Familiar primary combinations produce orange, green, and purple. Choose no glitter, fine glitter, diamond, ruby, emerald, or amethyst directly with one tap; your finish is remembered separately for each color, including mixed colors. Animated twinkles respect the iPad's Reduce Motion setting, and exported images retain the glitter/crystal texture.

Paint style offers solid color, gradients, stripes, dots, checkerboards, and chevrons. Use From and To to choose the two colors for a gradient or pattern; gradients can run horizontally, vertically, or diagonally. Fills stretch gradients across the selected region, while freestyle gradients use the whole page so consecutive brush segments join seamlessly. Patterns and gradients can be combined with glitter and remain visible in saved drawings, gallery previews, and exports. With Eraser, tap to clear a region or tap a drawn outline to erase locally; drag to rub out drawn lines, brush strokes, color, and glitter. The original mandala outlines are always preserved, and erasing supports undo/redo.

Select a color and tap inside a black outline to fill the whole connected space. Select Brush to draw freely with the selected color and finish on any page; changing colors keeps Brush active. Black outlines stay visible above painted strokes. Pinch the paper to zoom up to 4x for tiny details; use two fingers to move around the zoomed page. Drag with Pencil or a shape tool to add black outlines, then select a color to switch to Fill. Freehand outlines must be closed; gaps connect spaces. Undo/redo supports the last twelve actions. Clear asks for confirmation and is undoable. Each page saves locally and automatically, including freestyle strokes and editable outlines. Existing saved drawings remain compatible. Brush masks cover only the touched area, coalesced touch samples render together, and outlines are cached. Gallery rendering and automatic file encoding run off the UI thread. Share exports the current drawing as an image using the iPad share sheet. No accounts, advertising, analytics, network requests, or third-party dependencies.

## Build and test

Requires Xcode with an iOS 17 or newer SDK. The checked-in Xcode project is ready to open. `project.yml` is its XcodeGen source; regenerate with `xcodegen generate` after changing target configuration.

```sh
xcodebuild -project Mandolino.xcodeproj -scheme Mandolino \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -derivedDataPath build test CODE_SIGNING_ALLOWED=NO
```

For a physical iPad, select your Apple Development team in Signing & Capabilities, pair/trust the device in Xcode, enable Developer Mode, and select it as the run destination. Wireless installation requires an active Xcode network pairing. Development profiles expire according to the Apple account type; this is not an App Store distribution.

Drawings are stored in the app's Documents/Drawings directory. Deleting the app deletes its local drawings; use Share to keep exported images.
