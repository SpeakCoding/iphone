import UIKit


class UserProfileEditor: UIViewController {
    
    @IBOutlet private var avatarView: AvatarView!
    @IBOutlet private var nameField: TextField!
    @IBOutlet private var bioField: TextView!
    private var user: User
    private var completion: (_ user: User) -> Void
    
    init(user: User, completion: @escaping (_ user: User) -> Void) {
        self.user = user
        self.completion = completion
        super.init(nibName: "UserProfileEditor", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let avatarURL = self.user.avatarURL {
            self.avatarView.showImageAsynchronously(imageURL: avatarURL)
        }
        self.nameField.text = self.user.name
        self.bioField.text = self.user.bio
    }
    
    @IBAction func setAvatar() {
        
    }
    
    @IBAction func save() {
        self.view.isUserInteractionEnabled = false
        #warning("Upload the avatar first")
        let avatarURL = self.user.avatarURL
        ServerAPI.shared.updateProfile(name: self.nameField.text, bio: self.bioField.text, avatarURL: avatarURL) { (user: User?, error: Error?) in
             self.view.isUserInteractionEnabled = true
            if user != nil {
                self.completion(user!)
            } else {
                self.report(error: error)
            }
        }
    }
}
