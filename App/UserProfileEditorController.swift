import UIKit


class UserProfileEditorController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var nameField: TextField!
    @IBOutlet private var bioField: TextView!
    private var completion: () -> Void
    private var newProfilePicture: UIImage?
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init(nibName: "UserProfileEditorController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = User.current!
        if let profilePictureURL = currentUser.profilePictureURL {
            self.profilePictureView.showImageAsynchronously(imageURL: profilePictureURL)
        }
        self.nameField.text = currentUser.userName
        self.bioField.text = currentUser.bio
    }
    
    @IBAction func changeProfilePicture() {
        self.presentImagePicker { (image: UIImage) in
            self.profilePictureView.image = image
            self.newProfilePicture = image
        }
    }
    
    @IBAction func save() {
        self.view.isUserInteractionEnabled = false
        ServerAPI.shared.updateProfile(name: self.nameField.text, bio: self.bioField.text, profilePicture: self.newProfilePicture) { (user: User?, error: Error?) in
            self.view.isUserInteractionEnabled = true
            if user != nil {
                self.completion()
            } else {
                self.report(error: error)
            }
        }
    }
    
    // This is called when the user swipes down to dismiss the login flow view controller after signing up
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        self.completion()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
