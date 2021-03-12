import UIKit


class UserCellView: UITableViewCell {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var userBioLabel: UILabel!
    @IBOutlet private var followButton: UIButton?
    var user: User!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let followButton = self.followButton {
            followButton.setBackgroundImage(UIImage(named: "small-button-on"), for: UIControl.State.selected)
            followButton.setBackgroundImage(UIImage(named: "small-button-on"), for: [UIControl.State.selected, UIControl.State.highlighted])
            followButton.setTitleColor(UIColor.white, for: UIControl.State.selected)
            followButton.setTitleColor(UIColor.white, for: [UIControl.State.selected, UIControl.State.highlighted])
            followButton.setTitle("Unfollow", for: UIControl.State.selected)
            followButton.setTitle("Unfollow", for: [UIControl.State.selected, UIControl.State.highlighted])
        }
    }
    
    func setUser(_ user: User) {
        self.user = user
        
        self.profilePictureView.showImageAsynchronously(imageURL: user.profilePictureURL)
        self.userNameLabel.text = user.userName
        self.userBioLabel.text = user.bio
        if let followButton = self.followButton {
            followButton.isSelected = user.isFollowed
            followButton.isEnabled = (user != User.current)
            followButton.alpha = (followButton.isEnabled ? 1 : 0.4)
        }
    }
    
    @IBAction func toggleFollow() {
        let theUserToUpdate = self.user!
        func processUserUpdateRequestResult(error: Error?) {
            if error != nil {
                if self.user == theUserToUpdate {
                    self.followButton?.isSelected = self.user.isFollowed
                }
            } else {
                NotificationCenter.default.post(name: Notification.Name.FeedUpdatedNotification, object: nil)
            }
        }
        self.user.toggleFollowed(completion: processUserUpdateRequestResult)
        self.followButton?.isSelected = self.user.isFollowed
    }
}
