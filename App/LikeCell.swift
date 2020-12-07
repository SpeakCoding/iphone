import UIKit


class LikeCell: UITableViewCell {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var postImageView: AsynchronousImageView!
    @IBOutlet private var dateLabel: UILabel!
    var like: Like!
    
    func setLike(_ like: Like) {
        self.like = like
        
        self.profilePictureView.showImageAsynchronously(imageURL: like.user.profilePictureURL)
        self.userNameLabel.text = like.user.userName
        self.dateLabel.text = like.date.stringRepresentation
        self.postImageView.showImageAsynchronously(imageURL: like.post.images?.first?.url)
    }
}
