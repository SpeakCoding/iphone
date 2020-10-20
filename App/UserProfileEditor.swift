import UIKit


class UserProfileEditor: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private var avatarView: AvatarView!
    @IBOutlet private var nameField: TextField!
    @IBOutlet private var bioField: TextView!
    private var completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
        super.init(nibName: "UserProfileEditor", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = User.current!
        if let avatarURL = currentUser.profilePictureURL {
            self.avatarView.showImageAsynchronously(imageURL: avatarURL)
        }
        self.nameField.text = currentUser.userName
        self.bioField.text = currentUser.bio
    }
    
    @IBAction func setAvatar() {
        self.presentImagePicker { (image: UIImage) in
            self.avatarView.image = image
        }
    }
    
    @IBAction func save() {
        self.view.isUserInteractionEnabled = false
        #warning("Upload the avatar first")
        let avatarURL: URL? = nil
        ServerAPI.shared.updateProfile(name: self.nameField.text, bio: self.bioField.text, avatarURL: avatarURL) { (user: User?, error: Error?) in
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
}
