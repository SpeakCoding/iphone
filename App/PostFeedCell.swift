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
    weak var viewController: UIViewController?
    
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
        let userProfileViewer = UserProfileViewController(user: self.post.user)
        self.viewController?.navigationController?.pushViewController(userProfileViewer, animated: true)
    }
    
    @IBAction private func toggleLike() {
        self.post.toggleLike()
        self.likeButton.isSelected = self.post.isLiked
        self.likeCountLabel.text = "\(self.post.numberOfLikes) likes"
        
        let thePostToUpdate = self.post!
        ServerAPI.shared.updatePostLike(self.post, completion: { (updatedPost: Post?, error: Error?) in
            if error != nil {
                self.viewController?.report(error: error)
                thePostToUpdate.toggleLike()
            }
            if self.post == thePostToUpdate {
                self.setPost(thePostToUpdate)
            }
        })
    }
    
    @IBAction private func toggleSaved() {
        self.post.toggleSaved()
        self.bookmarkButton.isSelected = self.post.isSaved
        
        let thePostToUpdate = self.post!
        ServerAPI.shared.updatePostSaved(self.post, completion: { (updatedPost: Post?, error: Error?) in
            if error != nil {
                self.viewController?.report(error: error)
                thePostToUpdate.toggleSaved()
            }
            if self.post == thePostToUpdate {
                self.setPost(thePostToUpdate)
            }
        })
    }
    
    @IBAction private func addComment() {
        #warning("Not implemented")
    }
    
    @IBAction private func showAllComments() {
        #warning("Not implemented")
    }
}
