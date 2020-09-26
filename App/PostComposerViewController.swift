import UIKit


class PostComposerViewController: UIViewController {
    
    private var image: UIImage
    private var completion: (_ newPost: Post) -> Void
    @IBOutlet private var postImageView: UIImageView!
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    
    init(image: UIImage , completion: @escaping (_ newPost: Post) -> Void) {
        self.image = image
        self.completion = completion
        super.init(nibName: "PostComposerView", bundle: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(createNewPost))
        self.navigationItem.rightBarButtonItem!.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postImageView.image = image
        
        textView.textContainerInset = .zero
        placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: textView.contentInset.left + textView.textContainer.lineFragmentPadding).isActive = true
        placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: textView.contentInset.top).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.becomeFirstResponder()
    }
    
    @objc func textViewDidChange(_ textView: UITextView) {
        let textHasBeenEntered = textView.text.count > 0
        placeholderLabel.isHidden = textHasBeenEntered
        self.navigationItem.rightBarButtonItem!.isEnabled = textHasBeenEntered
    }
    
    @IBAction private func tagPeople() {
        #warning("Tagging people is not implemented")
    }
    
    @objc private func createNewPost() {
        let shareButton = self.navigationItem.rightBarButtonItem!
        let spinner = UIActivityIndicatorView(style: .medium)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        spinner.startAnimating()
        
        #warning("Get location")
        let newPost = Post(creationDate: Date(), author: User.current!, postCaption: textView.text, postImages: nil, postVideo: nil, postLocation: nil)
        ServerAPI.shared.create(post: newPost) { (createdPost: Post?, error: Error?) in
            spinner.stopAnimating()
            self.navigationItem.rightBarButtonItem = shareButton
            if createdPost != nil {
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
