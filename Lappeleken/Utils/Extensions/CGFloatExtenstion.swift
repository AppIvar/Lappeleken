//
//  CGFloatExtenstion.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import UIKit

// Extension to handle NaN and infinity values in CoreGraphics
extension CGFloat {
    /// Returns a valid CGFloat value, replacing NaN and Infinity with default values
    var validated: CGFloat {
        if self.isNaN {
            print("Warning: NaN value detected in CGFloat and was replaced with 0")
            return 0.0
        }
        if self.isInfinite {
            print("Warning: Infinite value detected in CGFloat and was replaced with \(self > 0 ? 10000 : -10000)")
            return self > 0 ? 10000 : -10000
        }
        return self
    }
}

// Extension to UIView to help prevent NaN issues in layout
extension UIView {
    /// Sets the frame safely by validating CGFloat values
    func setSafeFrame(_ frame: CGRect) {
        self.frame = CGRect(
            x: frame.origin.x.validated,
            y: frame.origin.y.validated,
            width: max(0, frame.size.width.validated),
            height: max(0, frame.size.height.validated)
        )
    }
}
