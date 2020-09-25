import UIKit


@IBDesignable
class TextField: UITextField {
    
    var indicatesError: Bool = false {
        didSet {
            let backgroundImageName = indicatesError ? "text-field-background-error" : "text-field-background"
            background = UIImage(named: backgroundImageName, in: Bundle(for: TextField.self), compatibleWith: nil)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpInternals()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpInternals()
    }
    
    private func setUpInternals() {
        indicatesError = false
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).insetBy(dx: 16, dy: 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpInternals()
    }
}
