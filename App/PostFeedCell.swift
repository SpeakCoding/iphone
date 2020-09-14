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
    weak var actionDelegate: PostFeedCellDelegate?
    
    var post: Post! {
        didSet {
            posterAvatarView.showImageAsynchronously(image: post.user.avatar)
            postImageView.showImageAsynchronously(image: post.images?.first)
            
            #warning("Not quite implemented")
            posterNameLabel.text = post.user.name
            posterLocationLabel.isHidden = true
            likeButton.isSelected = false
            bookmarkButton.isSelected = false
            likeCountLabel.text = "\(0) likes"
            postTextLabel.text = post.text
            commentCountLabel.text = "View all \(0) comments"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            postDateLabel.text = dateFormatter.string(from: post.date)
        }
    }
    
    @IBAction private func showUserProfile() {
        actionDelegate?.showUserProfile(post.user)
    }
    
    @IBAction private func toggleLike() {
        actionDelegate?.toggleLike(post: post)
    }
    
    @IBAction private func addComment() {
        actionDelegate?.addComment(post: post)
    }
    
    @IBAction private func toggleBookmark() {
        actionDelegate?.toggleBookmark(post: post)
    }
    
    @IBAction private func showAllComments() {
        actionDelegate?.showAllComments(post: post)
    }
}


protocol PostFeedCellDelegate: AnyObject {
    func showUserProfile(_ user: User)
    func toggleLike(post: Post)
    func addComment(post: Post)
    func toggleBookmark(post: Post)
    func showAllComments(post: Post)
}
