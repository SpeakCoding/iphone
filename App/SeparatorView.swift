import UIKit


#warning("Unused class")
@IBDesignable
class SeparatorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpInternals()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpInternals()
    }
    
    private func setUpInternals() {
        self.backgroundColor = UIColor(red: 237.0/255.0, green: 241.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        self.isUserInteractionEnabled = false
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentHuggingPriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
    override var intrinsicContentSize: CGSize {
        let pixelWidth = 1.0 / UIScreen.main.scale
        return CGSize(width: UIView.noIntrinsicMetric, height: pixelWidth)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpInternals()
    }
}
