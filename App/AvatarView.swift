import UIKit


/**
 This class represents a view which displays a round avatar image.
 Note that it is a subclass of `AsynchronousImageView`
 and thus inherits its functionality: `AvatarView` can download images too!
 */
@IBDesignable
class AvatarView: AsynchronousImageView {
    
    private var clipMask: CAShapeLayer?
    private var placeholderImage: UIImage {
        get {
            return UIImage(named: "avatar-placeholder", in: Bundle(for: AvatarView.self), compatibleWith: nil)!
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Create a circle mask to trim image corners, unless we've already created it
        if self.clipMask == nil {
            self.clipMask = CAShapeLayer()
            self.layer.mask = self.clipMask!
            // Display the initial placeholder image
            if self.image == nil {
                self.image = self.placeholderImage
            }
        }
        // Adjust the mask's size to fill the view if needed
        if self.clipMask!.frame.size != self.bounds.size {
            // Make sure the clip mask is a perfect circle
            let clipMaskDiameter = min(self.bounds.size.width, self.bounds.size.height)
            let clipMaskFrame = CGRect(x: 0, y: 0, width: clipMaskDiameter, height: clipMaskDiameter)
            self.clipMask!.frame = clipMaskFrame
            self.clipMask!.path = UIBezierPath(ovalIn: clipMaskFrame).cgPath
            // Enforce proportional image scaling
            self.contentMode = .scaleAspectFill
        }
    }
    
    override var image: UIImage? {
        get {
            return super.image
        }
        set(newImage) {
            super.image = newImage ?? self.placeholderImage
        }
    }
}
