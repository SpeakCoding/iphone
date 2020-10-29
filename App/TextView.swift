import UIKit


@IBDesignable
class TextView: UITextView {
    
    private var placeholderLabel: UILabel!
    private var backgroundView: UIImageView?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setUpInternals()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpInternals()
    }
    
    private func setUpInternals() {
        if placeholderLabel == nil {
            placeholderLabel = UILabel(frame: CGRect.zero)
            placeholderLabel.font = self.font
            placeholderLabel.textColor = UIColor.placeholderText
            self.addSubview(placeholderLabel)
            
            NotificationCenter.default.addObserver(self, selector: #selector(updatePlaceholderVisibility), name: UITextView.textDidChangeNotification, object: self)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBInspectable var placeholder: String? {
        get {
            placeholderLabel?.text
        }
        set {
            setUpInternals()
            placeholderLabel.text = newValue
            placeholderLabel.sizeToFit()
        }
    }
    
    @IBInspectable var backgroundImageName: String? {
        didSet {
            if backgroundImageName != nil {
                let backgroundImage = UIImage(named: backgroundImageName!, in: Bundle(for: TextField.self), compatibleWith: nil)
                backgroundView = UIImageView(image: backgroundImage)
                backgroundView!.frame = self.bounds
                self.insertSubview(backgroundView!, at: 0)
            } else {
                backgroundView?.removeFromSuperview()
                backgroundView = nil
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        placeholderLabel.frame.origin = CGPoint(x: self.contentInset.left + self.textContainer.lineFragmentPadding, y: self.contentInset.top + 8)
        backgroundView?.frame = self.bounds
    }
    
    override var text: String! {
        didSet {
            updatePlaceholderVisibility()
        }
    }
    
    @objc private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = self.text.count > 0
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpInternals()
    }
}
