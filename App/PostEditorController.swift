import UIKit


class PostEditorController: UIViewController, UITextViewDelegate {
    
    private var post: Post
    private var image: UIImage?
    private var completion: (Post?) -> Void
    private var tags: [Tag]
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var userLocationLabel: UILabel!
    @IBOutlet private var postImageView: AsynchronousImageView!
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var textViewHeight: NSLayoutConstraint!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var scrollViewBottomOffset: NSLayoutConstraint!
    
    init(post: Post, cachedPostImage: UIImage?, completion: @escaping (Post?) -> Void) {
        self.post = post
        self.image = cachedPostImage
        self.completion = completion
        self.tags = post.tags
        super.init(nibName: "PostEditorController", bundle: nil)
        self.title = "Edit post"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancelEditing))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(saveChanges))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        self.textView.contentInset = UIEdgeInsets.zero
        
        self.textView.text = self.post.caption
        if self.image != nil {
            self.postImageView.image = self.image
        } else {
            self.postImageView.showImageAsynchronously(imageURL: self.post.images?.first?.url)
        }
        self.profilePictureView.showImageAsynchronously(imageURL: self.post.user.profilePictureURL)
        self.userNameLabel.text = self.post.user.userName
        self.userLocationLabel.text = self.post.location
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.textView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update the text view height whenever the view's size changes
        self.textViewDidChange(self.textView)
    }
    
    internal func textViewDidChange(_ textView: UITextView) {
        let textViewHeightToFitContent = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
        if textViewHeightToFitContent == self.textViewHeight.constant {
            return
        }
        let shouldScrollToBottom = (textViewHeightToFitContent > self.textViewHeight.constant)
        self.textViewHeight.constant = textViewHeightToFitContent
        if shouldScrollToBottom {
            self.scrollView.layoutIfNeeded()
            self.scrollView.scrollRectToVisible(self.textView.frame, animated: true)
        }
    }
    
    @IBAction private func tagPeople() {
        let userTagger = TagEditorController(image: self.postImageView.image!, tags: self.tags) { (tags: [Tag]) in
            self.tags = tags
            self.navigationController?.popToViewController(self, animated: true)
        }
        self.navigationController?.pushViewController(userTagger, animated: true)
    }
    
    @objc private func cancelEditing() {
        self.completion(nil)
    }
    
    @objc private func saveChanges() {
        self.post.caption = self.textView.text
        self.post.tags = self.tags
        func processPostUpdateRequestResult(updatedPost: Post?, error: Error?) {
            if updatedPost != nil {
                self.completion(updatedPost!)
            } else {
                self.report(error: error)
            }
        }
        ServerAPI.shared.updatePost(self.post, image: self.postImageView.image!, completion: processPostUpdateRequestResult)
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.convert(keyboardFrameInWindow, from: nil).minY
        self.scrollViewBottomOffset.constant = max(keyboardTopOffset, 0)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
