import UIKit


class CommentCellView: UITableViewCell {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var commentTextLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    private var comment: Comment!
    weak var viewController: CommentsViewController?
    
    @IBAction private func reply() {
        self.viewController?.replyTo(comment: self.comment)
    }
    
    func setComment(_ comment: Comment) {
        self.comment = comment
        
        self.profilePictureView.showImageAsynchronously(imageURL: comment.user.profilePictureURL)
        
        let text = NSMutableAttributedString(string: comment.user.userName.appending(" "), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)])
        text.append(NSAttributedString(string: comment.text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)]))
        self.commentTextLabel.attributedText = text
        
        self.dateLabel.text = comment.date.stringRepresentation
    }
}
