import UIKit


class UserProfileEditorController: UIViewController, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var nameField: TextField!
    @IBOutlet private var bioField: TextField!
    private var completion: (Bool) -> Void
    private var newProfilePicture: UIImage?
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init(nibName: "UserProfileEditorController", bundle: nil)
        self.title = "Edit profile"
        
        // Don't allow cancelling when signing up
        if User.current!.userName.count > 0 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
            self.navigationItem.leftBarButtonItem!.tintColor = UIColor.black
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nameField.background = nil
        self.bioField.background = nil
        
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
    
    @objc func cancel() {
        self.completion(false)
    }
    
    @objc func save() {
        let username = self.nameField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        if username.count == 0 {
            self.report(error: NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "User name is required"]))
            return
        }
        let bio = self.bioField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        self.view.isUserInteractionEnabled = false
        func processProfileUpdateRequestResult(user: User?, error: Error?) {
            self.view.isUserInteractionEnabled = true
            if user != nil {
                self.completion(true)
            } else {
                self.report(error: error)
            }
        }
        ServerAPI.shared.updateUser(name: username, bio: bio, profilePicture: self.newProfilePicture, completion: processProfileUpdateRequestResult)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
