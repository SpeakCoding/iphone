import UIKit


class UserCell: UITableViewCell {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var userBioLabel: UILabel!
    
    func setUser(_ user: User) {
        self.profilePictureView.showImageAsynchronously(imageURL: user.profilePictureURL)
        self.userNameLabel.text = user.userName
        self.userBioLabel.text = user.bio
    }
}
