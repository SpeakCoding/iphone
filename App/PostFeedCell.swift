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
    @IBOutlet private var postTextLabel: UILabel!
    @IBOutlet private var commentCountLabel: UILabel!
    @IBOutlet private var postDateLabel: UILabel!
    weak var actionDelegate: PostFeedViewController?
    
    var post: Post!
    func setPost(_ newPost: Post) {
        self.post = newPost
        
        self.profilePictureView.showImageAsynchronously(imageURL: newPost.user.profilePictureURL)
        self.postImageView.showImageAsynchronously(imageURL: newPost.images?.first?.url)
        
        self.userNameLabel.text = newPost.user.userName
        self.userLocationLabel.text = newPost.location
        self.likeButton.isSelected = newPost.isLiked
        self.bookmarkButton.isSelected = false
        self.likeCountLabel.text = "\(newPost.numberOfLikes) likes"
        self.postTextLabel.text = newPost.caption
        if newPost.numberOfComments > 0 {
            self.commentCountLabel.text = "View all \(newPost.numberOfComments) comments"
            self.commentCountLabel.isHidden = false
        } else {
            self.commentCountLabel.isHidden = true
        }
        self.postDateLabel.text = newPost.date.stringRepresentation
    }
    
    func updateLike() {
        self.likeButton.isSelected = self.post.isLiked
        self.likeCountLabel.text = "\(self.post.numberOfLikes) likes"
    }
    
    @IBAction private func showUserProfile() {
        self.actionDelegate?.showUserProfile(post.user)
    }
    
    @IBAction private func toggleLike() {
        self.actionDelegate?.toggleLike(post: post)
    }
    
    @IBAction private func addComment() {
        self.actionDelegate?.addComment(post: post)
    }
    
    @IBAction private func toggleBookmark() {
        self.actionDelegate?.toggleBookmark(post: post)
    }
    
    @IBAction private func showAllComments() {
        self.actionDelegate?.showAllComments(post: post)
    }
}
