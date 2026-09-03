//
//  Copyright 2026 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

#if !canImport(UIKit)

    import AppKit
    import func AVFoundation.AVMakeRect
    import Foundation

    /// AppKit stand-ins for the two UIKit types that appear in ReadiumShared's
    /// public API.
    ///
    /// Aliasing rather than renaming keeps every call site — and every signature
    /// clients depend on — spelled the same on both platforms, so the macOS
    /// support patch stays confined to imports and a handful of `#if`s.
    ///
    /// One asymmetry the alias cannot hide: `UIImage` is `NS_SWIFT_SENDABLE`,
    /// `NSImage` is not. So `Publication.cover()`, which returns
    /// `ReadResult<UIImage?>`, is Sendable-clean on iOS and not on macOS. Passing
    /// a cover across an actor boundary therefore compiles on iOS and warns or
    /// errors on macOS — under `@preconcurrency import` it is only a warning,
    /// which makes it easy to miss. Read cover *bytes* rather than the image if
    /// the result has to cross isolation.
    public typealias UIImage = NSImage
    public typealias UIColor = NSColor

    public extension NSImage {
        convenience init(cgImage: CGImage) {
            self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }

        /// Mirrors `UIImage.pngData()`.
        func pngData() -> Data? {
            guard let tiff = tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else {
                return nil
            }
            return rep.representation(using: .png, properties: [:])
        }
    }

    extension NSImage {
        /// Mirrors the `UIImage.scaleToFit(maxSize:)` extension in
        /// `Toolkit/Extensions/UIImage.swift`, which is iOS-only.
        ///
        /// Internal, like the iOS one it mirrors.
        ///
        /// Two things here are deliberately not the naive translation:
        ///
        /// `NSImage.size` is in points, derived from the DPI recorded in the
        /// image file, whereas `UIImage(data:)` always has scale 1 so its `size`
        /// *is* pixels. A 3000×3000 cover tagged 300 DPI reports a `size` of
        /// 720×720, which would sail past the early return and skip the
        /// downscale this function exists to perform. Pixel dimensions are read
        /// off the representation instead.
        ///
        /// `NSImage(size:flipped:drawingHandler:)` would be the direct analogue
        /// of `UIGraphicsImageRenderer.image`, but its handler runs lazily and
        /// captures `self`, so the "scaled" image pins the full-resolution
        /// original in memory for as long as it lives — the opposite of the
        /// point. This renders eagerly into a bitmap and lets the source go.
        func scaleToFit(maxSize: CGSize) -> NSImage {
            var pixelSize = size
            if let rep = representations.first, rep.pixelsWide > 0, rep.pixelsHigh > 0 {
                pixelSize = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            }

            if pixelSize.width <= maxSize.width, pixelSize.height <= maxSize.height {
                return self
            }

            let target = AVMakeRect(aspectRatio: pixelSize, insideRect: CGRect(origin: .zero, size: maxSize))
            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(target.width.rounded()),
                pixelsHigh: Int(target.height.rounded()),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else {
                return self
            }
            bitmap.size = target.size

            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            draw(in: CGRect(origin: .zero, size: target.size))

            let scaled = NSImage(size: target.size)
            scaled.addRepresentation(bitmap)
            return scaled
        }
    }

#endif
