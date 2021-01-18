import UIKit


class CommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tableViewBottomOffset: NSLayoutConstraint!
    @IBOutlet private var postDetailsHeaderView: UIView!
    @IBOutlet private var postAuthorProfilePictureView: ProfilePictureView!
    @IBOutlet private var captionLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var accessoryView: UIView!
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var textField: CommentTextField!
    private var post: Post
    private var comments: [Comment]
    
    init(post: Post) {
        self.post = post
        self.comments = post.comments
        super.init(nibName: "CommentsView", bundle: nil)
        self.title = "Comments"
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.postAuthorProfilePictureView.showImageAsynchronously(imageURL: self.post.user.profilePictureURL)
        self.dateLabel.text = self.post.date.stringRepresentation
        let text = NSMutableAttributedString(string: self.post.user.userName.appending(" "), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)])
        text.append(NSAttributedString(string: self.post.caption, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)]))
        self.captionLabel.attributedText = text
        self.postDetailsHeaderView.frame.size = self.postDetailsHeaderView.systemLayoutSizeFitting(CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat.greatestFiniteMagnitude), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
        self.tableView.tableHeaderView = self.postDetailsHeaderView
        
        self.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "Comment cell")
        self.profilePictureView.showImageAsynchronously(imageURL: User.current?.profilePictureURL)
        self.textField.background = UIImage(named: "comment-field")
        self.textField.postButton.addTarget(self, action: #selector(sendComment), for: UIControl.Event.touchUpInside)
        self.textField.postButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selection = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selection, animated: true)
        }
    }
    
    override var inputAccessoryView: UIView? {
        get { self.accessoryView }
    }
    
    override var canBecomeFirstResponder: Bool {
        get { true }
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            self.textField.becomeFirstResponder()
        }
        return result
    }
    
    @IBAction private func textFieldTextDidChange() {
        let commentText = (self.textField.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.textField.postButton.isEnabled = commentText.count > 0
    }
    
    @objc private func sendComment() {
        let commentText = (self.textField.text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if commentText.count == 0 {
            return
        }
        
        let comment = Comment(date: Date(), user: User.current!, text: commentText)
        func processCommentCreationRequestResult(newComment: Comment?, error: Error?) {
            if newComment != nil {
                let insertedIndexPath = IndexPath(row: self.comments.count, section: 0)
                self.comments.append(newComment!)
                self.tableView.insertRows(at: [insertedIndexPath], with: UITableView.RowAnimation.automatic)
                self.tableView.scrollToRow(at: insertedIndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
                NotificationCenter.default.post(name: Notification.Name.NewCommentNotification, object: self.post)
            } else {
                self.report(error: error)
            }
        }
        ServerAPI.shared.createComment(comment, to: self.post, completion: processCommentCreationRequestResult)
        self.textField.text = ""
        self.textField.postButton.isEnabled = false
    }
    
    func replyTo(comment: Comment) {
        self.textField.text = "@" + comment.user.userName + " " + (self.textField.text ?? "")
        self.textField.postButton.isEnabled = true
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "Comment cell", for: indexPath) as! CommentCell
        tableViewCell.setComment(self.comments[indexPath.row])
        tableViewCell.viewController = self
        return tableViewCell
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendComment()
        return false
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.convert(keyboardFrameInWindow, from: nil).minY
        self.tableViewBottomOffset.constant = max(keyboardTopOffset, 0)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}


class CommentTextField: UITextField {
    
    var postButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpInternals()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpInternals()
    }
    
    private func setUpInternals() {
        postButton = UIButton(type: UIButton.ButtonType.custom)
        postButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        postButton.setTitle("Post", for: UIControl.State.normal)
        postButton.setTitleColor(UIColor(named: "sc-blue"), for: UIControl.State.normal)
        postButton.setTitleColor(UIColor(named: "sc-blue")!.withAlphaComponent(0.4), for: UIControl.State.disabled)
        postButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        postButton.sizeToFit()
        self.rightView = postButton
        self.rightViewMode = UITextField.ViewMode.always
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        rect.origin.x = 16
        rect.size.width = bounds.maxX - rect.origin.x - self.postButton.frame.width
        return rect
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.maxX - self.postButton.frame.width, y: 0, width: self.postButton.frame.width, height: bounds.height)
    }
}


extension Notification.Name {
    public static let NewCommentNotification = NSNotification.Name("New comment created")
}
