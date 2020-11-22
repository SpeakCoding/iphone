import UIKit


class SegmentedControl: UIControl {
    
    private var buttons = [UIButton]()
    var selectedSegmentIndex: Int {
        didSet {
            for (index, button) in self.buttons.enumerated() {
                self.tint(button: button, at: index)
            }
        }
    }
    
    override init(frame: CGRect) {
        self.selectedSegmentIndex = -1
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        self.selectedSegmentIndex = -1
        super.init(coder: coder)
    }
    
    func addSegment(with image: UIImage?) {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(image, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(handleButtonPress(sender:)), for: UIControl.Event.touchUpInside)
        self.tint(button: button, at: self.buttons.count)
        self.buttons.append(button)
        self.addSubview(button)
    }
    
    private func tint(button: UIButton, at index: Int) {
        button.tintColor = UIColor(named: index == self.selectedSegmentIndex ? "sc-main-tint-color" : "sc-pale-tint-color")
    }
    
    @objc private func handleButtonPress(sender: UIButton) {
        let pressedButtonIndex = self.buttons.firstIndex(of: sender)!
        let selectedButtonIndex = self.selectedSegmentIndex
        if pressedButtonIndex == selectedButtonIndex {
            return
        }
        
        self.selectedSegmentIndex = pressedButtonIndex
        if selectedButtonIndex >= 0 && selectedButtonIndex < self.buttons.count {
            self.tint(button: self.buttons[selectedButtonIndex], at: selectedButtonIndex)
        }
        self.tint(button: sender, at: pressedButtonIndex)
        self.sendActions(for: UIControl.Event.valueChanged)
    }
    
    override func layoutSubviews() {
        let buttonWidth = self.bounds.width / CGFloat(self.buttons.count)
        var buttonFrame = CGRect(x: 0, y: 0, width: buttonWidth, height: self.bounds.height)
        for button in self.buttons {
            button.frame = buttonFrame
            buttonFrame.origin.x += buttonWidth
        }
    }
}
