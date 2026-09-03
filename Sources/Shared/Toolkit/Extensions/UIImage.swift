//
//  Copyright 2026 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

// swiftformat:options --ifdef no-indent
//
// The `#if` below wraps the whole file, so SwiftFormat's default ifdef
// handling would indent every line inside it. That is a lot of churn for a
// gate that is structural rather than a real scope, and it would make every
// future upstream edit to this file conflict on rebase.
//
// This option suppresses ifdef-body indentation only, leaving the `indent`
// rule itself enforcing the code below. Turning the rule off outright would
// also work, but it stays off for the rest of the file, so a real
// indentation defect introduced by a later rebase would pass silently.
#if canImport(UIKit)

import func AVFoundation.AVMakeRect
import Foundation
import UIKit

extension UIImage {
    func scaleToFit(maxSize: CGSize) -> UIImage {
        if size.width <= maxSize.width, size.height <= maxSize.height {
            return self
        }

        let targetRect = AVMakeRect(aspectRatio: size, insideRect: CGRect(origin: .zero, size: maxSize))
        let renderer = UIGraphicsImageRenderer(size: targetRect.size)
        return renderer.image { _ in
            draw(in: targetRect)
        }
    }
}

#endif
