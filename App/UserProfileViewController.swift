import UIKit


class UserProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet private var avatarView: AvatarView!
    @IBOutlet private var postCountLabel: UILabel!
    @IBOutlet private var followerCountLabel: UILabel!
    @IBOutlet private var followedCountLabel: UILabel!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var followButton: UIButton!
    @IBOutlet private var editProfileButton: UIButton!
    @IBOutlet private var gridView: UICollectionView!
    @IBOutlet private var placeholderLabel: UILabel!
    private var user: User
    private var posts = [Post]()

    init(user: User) {
        self.user = user
        super.init(nibName: "UserProfileView", bundle: nil)
        self.navigationItem.title = user.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #warning("Not implemented")
        avatarView.showImageAsynchronously(image: user.avatar)
        postCountLabel.text = "\(0)"
        followerCountLabel.text = "\(0)"
        followedCountLabel.text = "\(0)"
        userNameLabel.text = user.name
        
        if user == User.current {
            followButton.isHidden = true
        } else {
            editProfileButton.isHidden = true
            followButton.setTitleColor(UIColor.white, for: .selected)
            followButton.setTitleColor(UIColor.white, for: [.selected, .highlighted])
            followButton.setTitle("Unfollow", for: .selected)
            followButton.setTitle("Unfollow", for: [.selected, .highlighted])
        }
        
        gridView.register(PostTileCell.self, forCellWithReuseIdentifier: "Post cell")
        let cellWidth = UIScreen.main.bounds.size.width / 3.0
        let layout = gridView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        
        ServerAPI.shared.getPostsOf(user: user) { (posts: [Post]?, error: Error?) in
            if let posts = posts {
                if posts.count > 0 {
                    self.posts.append(contentsOf: posts)
                    self.placeholderLabel.isHidden = true
                    self.gridView.reloadData()
                    return
                }
            }
            self.placeholderLabel.isHidden = false
        }
    }
    
    @IBAction private func toggleFollow() {
        #warning("Not implemented")
        followButton.isSelected = !followButton.isSelected
        followButton.setBackgroundImage(UIImage(named: followButton.isSelected ? "small-button-on" : "small-button-off"), for: .normal)
    }
    
    @IBAction private func editProfile() {
        #warning("Not implemented")
    }
    
    // MARK: - UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Post cell", for: indexPath) as! PostTileCell
        cell.imageView.showImageAsynchronously(image: posts[indexPath.item].images?.first)
        return cell
    }
}


fileprivate class PostTileCell: UICollectionViewCell {
    
    var imageView: AsynchronousImageView
    
    override init(frame: CGRect) {
        imageView = AsynchronousImageView(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        super.init(frame: frame)
        self.contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = self.contentView.bounds
    }
}
