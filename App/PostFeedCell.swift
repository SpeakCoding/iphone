import UIKit


class PostFeedCell: UITableViewCell {
    
    @IBOutlet private var posterAvatarView: AvatarView!
    @IBOutlet private var posterNameLabel: UILabel!
    @IBOutlet private var posterLocationLabel: UILabel!
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
        
        self.posterAvatarView.showImageAsynchronously(imageURL: newPost.user.avatarURL)
        self.postImageView.showImageAsynchronously(imageURL: newPost.images?.first?.url)
        
        self.posterNameLabel.text = newPost.user.name
        self.posterLocationLabel.text = newPost.location
        self.likeButton.isSelected = newPost.isLiked
        self.bookmarkButton.isSelected = false
        self.likeCountLabel.text = "\(newPost.numberOfLikes) likes"
        self.postTextLabel.text = newPost.caption
        self.commentCountLabel.text = "View all \(newPost.numberOfComments) comments"
        self.postDateLabel.text = newPost.time.stringRepresentation
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
