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
        if clipMask == nil {
            clipMask = CAShapeLayer()
            layer.mask = clipMask!
            // Display the initial placeholder image
            if image == nil {
                image = placeholderImage
            }
        }
        // Adjust the mask's size to fill the view if needed
        if clipMask!.frame.size != bounds.size {
            // Make sure the clip mask is a perfect circle
            let clipMaskDiameter = min(bounds.size.width, bounds.size.height)
            let clipMaskFrame = CGRect(x: 0, y: 0, width: clipMaskDiameter, height: clipMaskDiameter)
            clipMask!.frame = clipMaskFrame
            clipMask!.path = UIBezierPath(ovalIn: clipMaskFrame).cgPath
            // Enforce proportional image scaling
            contentMode = .scaleAspectFill
        }
    }
    
    override var image: UIImage? {
        get {
            return super.image
        }
        set(newImage) {
            super.image = newImage ?? placeholderImage
        }
    }
}
