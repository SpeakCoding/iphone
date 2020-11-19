import UIKit


class LoginViewController: UIViewController {
    
    @IBOutlet private var emailTextField: TextField!
    @IBOutlet private var passwordTextField: TextField!
    @IBOutlet private var errorLabel: UILabel!
    private var emailAddress: String?
    private var completion: () -> Void
    
    init(emailAddress: String?, completion: @escaping () -> Void) {
        self.emailAddress = emailAddress
        self.completion = completion
        super.init(nibName: "LoginView", bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailTextField.text = self.emailAddress
        self.errorLabel.isHidden = true
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.convert(keyboardFrameInWindow, from: nil).minY
        var layoutMargins = self.view.layoutMargins
        layoutMargins.top = 0
        layoutMargins.bottom = max(keyboardTopOffset, 0)
        self.view.layoutMargins = layoutMargins
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    // This function is called when the Sign Up button is pressed
    @IBAction private func signUp() {
        self.navigationController?.setViewControllers([SignupViewController(emailAddress: self.emailTextField.text, completion: self.completion)], animated: true)
    }
    
    // This function is called when the Log In button is pressed
    @IBAction private func logIn() {
        self.view.endEditing(true)
        
        let emailAddress = self.emailTextField.text
        if let errorMessage = validate(emailAddress: emailAddress) {
            self.emailTextField.indicatesError = true
            self.errorLabel.text = errorMessage
            self.errorLabel.isHidden = false
            return
        }
        self.emailTextField.indicatesError = false
        
        let password = self.passwordTextField.text
        if let errorMessage = validate(password: password) {
            self.passwordTextField.indicatesError = true
            self.errorLabel.text = errorMessage
            self.errorLabel.isHidden = false
            return
        }
        self.passwordTextField.indicatesError = false
        
        self.errorLabel.isHidden = true
        self.view.isUserInteractionEnabled = false
        ServerAPI.shared.logIn(emailAddress: emailAddress!, password: password!) { (user: User?, error: Error?) in
            self.view.isUserInteractionEnabled = true
            if user != nil {
                self.completion()
            } else {
                self.report(error: error)
            }
        }
    }
    
    // These functions perform input validation and return an error message if any
    private func validate(emailAddress: String?) -> String? {
        if emailAddress == nil || emailAddress!.count == 0 {
            return "Please enter your email address"
        }
        if emailAddress!.count < 6 || !emailAddress!.contains("@") {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    private func validate(password: String?) -> String? {
        if password == nil || password!.count == 0 {
            return "Please enter your password"
        }
        if password!.count < 3 {
            return "A password must contain at least 3 characters"
        }
        return nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
