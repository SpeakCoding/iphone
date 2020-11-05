import UIKit


class PostComposerViewController: UIViewController {
    
    private var image: UIImage
    private var completion: (_ newPost: Post) -> Void
    private var tags = [Tag]()
    @IBOutlet private var postImageView: UIImageView!
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var locationField: TextField!
    
    init(image: UIImage, completion: @escaping (_ newPost: Post) -> Void) {
        self.image = image
        self.completion = completion
        super.init(nibName: "PostComposerView", bundle: nil)
        self.title = "New post"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: UIBarButtonItem.Style.plain, target: self, action: #selector(createNewPost))
        self.navigationItem.rightBarButtonItem!.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.postImageView.image = self.image
        
        self.textView.textContainerInset = UIEdgeInsets.zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.textView.becomeFirstResponder()
    }
    
    @objc func textViewDidChange(_ textView: UITextView) {
        let textHasBeenEntered = textView.text.count > 0
        self.navigationItem.rightBarButtonItem!.isEnabled = textHasBeenEntered
    }
    
    @IBAction private func tagPeople() {
        let userTagger = UserTaggingViewController(image: self.image, tags: self.tags) { (tags: [Tag]) in
            self.tags = tags
            self.navigationController?.popToViewController(self, animated: true)
        }
        self.navigationController?.pushViewController(userTagger, animated: true)
    }
    
    @objc private func createNewPost() {
        let shareButton = self.navigationItem.rightBarButtonItem!
        let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        spinner.startAnimating()
        
        let location = self.locationField.text
        let newPost = Post(creationDate: Date(), author: User.current!, postCaption: self.textView.text, postImages: nil, postVideo: nil, postLocation: location)
        ServerAPI.shared.createPost(newPost, image: self.image) { (createdPost: Post?, error: Error?) in
            spinner.stopAnimating()
            self.navigationItem.rightBarButtonItem = shareButton
            if createdPost != nil {
                NotificationCenter.default.post(name: Notification.Name.NewPostNotification, object: createdPost)
                self.completion(createdPost!)
            } else {
                self.report(error: error)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension Notification.Name {
    public static let NewPostNotification = NSNotification.Name("New post notification")
}
