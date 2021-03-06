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
        self.user.toggleFollowed()
        self.followButton?.isSelected = self.user.isFollowed
        
        let theUserToUpdate = self.user!
        func processUserUpdateRequestResult(user: User?, error: Error?) {
            if user != nil {
                NotificationCenter.default.post(name: Notification.Name.FeedUpdatedNotification, object: nil)
            }
            if error != nil {
                theUserToUpdate.toggleFollowed()
                if self.user == theUserToUpdate {
                    self.followButton?.isSelected = self.user.isFollowed
                }
            }
        }
        ServerAPI.shared.updateUserFollowed(user: self.user, completion: processUserUpdateRequestResult)
    }
}
