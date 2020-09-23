import UIKit


class ConfirmationCodeViewController: UIViewController {
    
    @IBOutlet private var hintLabel: UILabel!
    @IBOutlet private var codeTextField: TextField!
    @IBOutlet private var errorLabel: UILabel!
    private var emailAddress: String
    private var completion: () -> Void
    
    init(emailAddress: String, completion: @escaping () -> Void) {
        self.emailAddress = emailAddress
        self.completion = completion
        super.init(nibName: "ConfirmationCodeView", bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let plainHint = "Enter the confirmation code we’ve sent to <email>"
        let font = hintLabel.font!
        let formattedHint = NSMutableAttributedString(string: plainHint, attributes: [NSAttributedString.Key.font: font])
        let placeholderRange = (plainHint as NSString).range(of: "<email>")
        formattedHint.replaceCharacters(in: placeholderRange, with: NSAttributedString(string: emailAddress, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize:  font.pointSize)]))
        hintLabel.attributedText = formattedHint
        
        errorLabel.isHidden = true
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.convert(keyboardFrameInWindow, from: nil).minY
        self.view.layoutMargins.bottom = max(keyboardTopOffset, 0)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction private func returnToPreviousStep() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func proceedToNextStep() {
        self.view.endEditing(true)
        
        let confirmationCode = codeTextField.text
        if let errorMessage = validate(code: confirmationCode) {
            codeTextField.indicatesError = true
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            return
        }
        codeTextField.indicatesError = false
        
        #warning("Verify code and proceed")
    }
    
    // This function performs input validation and returns an error message if any
    private func validate(code: String?) -> String? {
        if code == nil || code!.count == 0 {
            return "Please enter the confirmation code"
        }
        return nil
    }
}
