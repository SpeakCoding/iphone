import UIKit


class PostFeedCell: UITableViewCell {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var userLocationLabel: UILabel!
    @IBOutlet private var postImageView: AsynchronousImageView!
    @IBOutlet private var likeButton: UIButton!
    @IBOutlet private var commentButton: UIButton!
    @IBOutlet private var bookmarkButton: UIButton!
    @IBOutlet private var likeCountLabel: UILabel!
    @IBOutlet private var captionLabel: UILabel!
    @IBOutlet private var commentCountLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    weak var actionDelegate: PostFeedCellActionDelegate?
    
    var post: Post!
    func setPost(_ newPost: Post) {
        self.post = newPost
        
        self.profilePictureView.showImageAsynchronously(imageURL: newPost.user.profilePictureURL)
        self.postImageView.showImageAsynchronously(imageURL: newPost.images?.first?.url)
        
        self.userNameLabel.text = newPost.user.userName
        self.userLocationLabel.text = newPost.location
        self.likeButton.isSelected = newPost.isLiked
        self.likeCountLabel.text = "\(newPost.numberOfLikes) likes"
        self.bookmarkButton.isSelected = newPost.isSaved
        self.captionLabel.text = newPost.caption
        if newPost.numberOfComments > 0 {
            self.commentCountLabel.text = "View all \(newPost.numberOfComments) comments"
            self.commentCountLabel.isHidden = false
        } else {
            self.commentCountLabel.isHidden = true
        }
        self.dateLabel.text = newPost.date.stringRepresentation
    }
    
    @IBAction private func showUserProfile() {
        self.actionDelegate?.showUserProfile(post.user)
    }
    
    @IBAction private func toggleLike() {
        self.actionDelegate?.toggleLike(postFeedCell: self)
        self.likeButton.isSelected = self.post.isLiked
        self.likeCountLabel.text = "\(self.post.numberOfLikes) likes"
    }
    
    @IBAction private func toggleSaved() {
        self.actionDelegate?.toggleSaved(postFeedCell: self)
        self.bookmarkButton.isSelected = self.post.isSaved
    }
    
    @IBAction private func addComment() {
        self.actionDelegate?.addComment(postFeedCell: self)
    }
    
    @IBAction private func showAllComments() {
        self.actionDelegate?.showAllComments(postFeedCell: self)
    }
}


protocol PostFeedCellActionDelegate : class {
    func showUserProfile(_ user: User)
    func toggleLike(postFeedCell: PostFeedCell)
    func toggleSaved(postFeedCell: PostFeedCell)
    func addComment(postFeedCell: PostFeedCell)
    func showAllComments(postFeedCell: PostFeedCell)
}
