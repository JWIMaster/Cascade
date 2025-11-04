import UIKit
import QuartzCore

public func applyGaussianBlur(to layer: CALayer, radius: CGFloat) {
    // Get the CAFilter class dynamically
    guard let CAFilterClass = NSClassFromString("CAFilter") as AnyObject as? NSObjectProtocol else {
        print("CAFilter not available")
        return
    }

    // Create a Gaussian blur filter
    let blurFilter = CAFilterClass.perform(NSSelectorFromString("filterWithName:"), with: "gaussianBlur")?.takeUnretainedValue()

    // Set the blur radius
    blurFilter?.perform(NSSelectorFromString("setValue:forKey:"), with: radius, with: "inputRadius")

    // Apply the filter to the layer
    layer.setValue([blurFilter as Any].compactMap { $0 }, forKey: "filters")
}



