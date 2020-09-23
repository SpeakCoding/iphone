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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.text = emailAddress
        errorLabel.isHidden = true
    }
    
    // This function is called when the Log In button is pressed
    @IBAction private func logIn() {
        self.view.endEditing(true)
        
        let emailAddress = emailTextField.text
        if let errorMessage = validate(emailAddress: emailAddress) {
            emailTextField.indicatesError = true
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            return
        }
        emailTextField.indicatesError = false
        
        let password = passwordTextField.text
        if let errorMessage = validate(password: password) {
            passwordTextField.indicatesError = true
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            return
        }
        passwordTextField.indicatesError = false
        
        self.view.isUserInteractionEnabled = false
        errorLabel.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ServerAPI.shared.logIn(emailAddress: emailAddress!, password: password!) { (user: User?, error: Error?) in
                if let user = user {
                    User.current = user
                    self.completion()
                } else {
                    self.report(error: error)
                }
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
}
