import UIKit


class TagCalloutView: UIView {
    
    override class var layerClass: AnyClass {
        get {
            CAShapeLayer.self
        }
    }
    
    private var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpInternals()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpInternals()
    }
    
    private func setUpInternals() {
        self.isUserInteractionEnabled = false
        (self.layer as! CAShapeLayer).fillColor = UIColor(white: 0, alpha: 0.65).cgColor

        textLabel = UILabel(frame: CGRect.zero)
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = UIColor.white
        self.addSubview(textLabel)
    }
    
    var text: String? {
        get {
            self.textLabel.text
        }
        set {
            self.textLabel.text = newValue
            self.textLabel.sizeToFit()
            self.sizeToFit()
        }
    }
    
    var isArrowUp = false {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var point = CGPoint.zero {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // Add inset (14, 8) around the text and add an arrow height, see layoutSubviews()
        var minimalSize = self.textLabel.bounds.size
        minimalSize.width += 2 * 14
        minimalSize.height += 2 * 8 + 6
        return minimalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        /*
         Given
         - the arrow's base width W
         - its corner radius R
         - arrow angle A = 90°
         The height can be calculated as:
         H = W/2 - R*sqrt(2) + R
        */
        let arrowBaseWidth = CGFloat(16)
        let arrowPointRadius = CGFloat(5)
        let arrowHeight = CGFloat(6)
        let arrowHalfWidth = arrowBaseWidth / 2
        let bodyCornerRadius = CGFloat(6)
        
        // Calculate the text position and the frame of the callout shape's body
        var calloutShapeBodyInset = UIEdgeInsets.zero
        if self.isArrowUp {
            self.textLabel.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY + arrowHeight / 2)
            calloutShapeBodyInset.top = arrowHeight
        } else {
            self.textLabel.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY - arrowHeight / 2)
            calloutShapeBodyInset.bottom = arrowHeight
        }
        let calloutShapeBodyRect = self.bounds.inset(by: calloutShapeBodyInset)
        
        // Draw the callout shape as a bezier path
        let shape = UIBezierPath(roundedRect: calloutShapeBodyRect, cornerRadius: bodyCornerRadius)
        let arrowCenterX = min(max(self.point.x, bodyCornerRadius + arrowHalfWidth), self.bounds.maxX - (bodyCornerRadius + arrowHalfWidth))
        if self.isArrowUp {
            let arrowBaseY = calloutShapeBodyRect.minY
            shape.move(to: CGPoint(x: arrowCenterX - arrowHalfWidth, y: arrowBaseY))
            shape.addArc(withCenter: CGPoint(x: arrowCenterX, y: arrowBaseY - arrowHeight + arrowPointRadius),
                         radius: arrowPointRadius,
                         startAngle: CGFloat.pi / 4 * 5,
                         endAngle: CGFloat.pi / 4 * 7,
                         clockwise: true)
            shape.addLine(to: CGPoint(x: arrowCenterX + arrowHalfWidth, y: arrowBaseY))
        } else {
            let arrowBaseY = calloutShapeBodyRect.maxY
            shape.move(to: CGPoint(x: arrowCenterX + arrowHalfWidth, y: arrowBaseY))
            shape.addArc(withCenter: CGPoint(x: arrowCenterX, y: arrowBaseY + arrowHeight - arrowPointRadius),
                         radius: arrowPointRadius,
                         startAngle: CGFloat.pi / 4 * 1,
                         endAngle: CGFloat.pi / 4 * 3,
                         clockwise: true)
            shape.addLine(to: CGPoint(x: arrowCenterX - arrowHalfWidth, y: arrowBaseY))
        }
        (self.layer as! CAShapeLayer).path = shape.cgPath
    }
}
