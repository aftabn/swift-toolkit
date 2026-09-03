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
    public typealias UIImage = NSImage
    public typealias UIColor = NSColor

    extension NSImage {
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

        /// Mirrors the `UIImage.scaleToFit(maxSize:)` extension in
        /// `Toolkit/Extensions/UIImage.swift`, which is iOS-only.
        func scaleToFit(maxSize: CGSize) -> NSImage {
            if size.width <= maxSize.width, size.height <= maxSize.height {
                return self
            }
            let target = AVMakeRect(aspectRatio: size, insideRect: CGRect(origin: .zero, size: maxSize))
            return NSImage(size: target.size, flipped: false) { rect in
                self.draw(in: rect)
                return true
            }
        }
    }

#endif
