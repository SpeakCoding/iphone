import UIKit


class UserProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet private var profilePictureView: ProfilePictureView!
    @IBOutlet private var postCountLabel: UILabel!
    @IBOutlet private var followerCountLabel: UILabel!
    @IBOutlet private var followedCountLabel: UILabel!
    @IBOutlet private var userNameLabel: UILabel!
    @IBOutlet private var bioLabel: UILabel!
    @IBOutlet private var followButton: UIButton!
    @IBOutlet private var editProfileButton: UIButton!
    @IBOutlet private var postsViewModeControl: SegmentedControl!
    @IBOutlet private var gridView: UICollectionView!
    @IBOutlet private var placeholderLabel: UILabel!
    private var user: User
    private var posts = [Post]()

    init(user: User) {
        self.user = user
        super.init(nibName: "UserProfileView", bundle: nil)
        
        if user == User.current {
            NotificationCenter.default.addObserver(self, selector: #selector(newPostHasBeenCreated), name: Notification.Name.NewPostNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(postHasBeenDeleted), name: Notification.Name.PostDeletedNotification, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.user == User.current {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "button-bookmark-off"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(showSavedPosts))
            self.followButton.isHidden = true
        } else {
            self.editProfileButton.isHidden = true
            self.followButton.setTitleColor(UIColor.white, for: UIControl.State.selected)
            self.followButton.setTitleColor(UIColor.white, for: [UIControl.State.selected, UIControl.State.highlighted])
            self.followButton.setTitle("Unfollow", for: UIControl.State.selected)
            self.followButton.setTitle("Unfollow", for: [UIControl.State.selected, UIControl.State.highlighted])
        }
        
        self.displayUserInformation()
        self.refreshUserInformation()
        
        self.gridView.register(PostTileCell.self, forCellWithReuseIdentifier: "Post cell")
        let cellWidth = UIScreen.main.bounds.size.width / 3.0
        let layout = self.gridView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        
        self.postsViewModeControl.addSegment(with: UIImage(named: "icon-grid"))
        self.postsViewModeControl.addSegment(with: UIImage(named: "icon-tag"))
        self.postsViewModeControl.selectedSegmentIndex = 0
        self.setPostsViewMode()
    }
    
    private func displayUserInformation() {
        self.navigationItem.title = self.user.userName
        self.profilePictureView.showImageAsynchronously(imageURL: self.user.profilePictureURL)
        self.postCountLabel.text = "\(self.user.numberOfPosts)"
        self.followerCountLabel.text = "\(self.user.numberOfFollowers)"
        self.followedCountLabel.text = "\(self.user.numberOfFollowees)"
        self.updateFollowButtonState()
        self.userNameLabel.text = self.user.userName
        self.bioLabel.text = self.user.bio
    }
    
    private func refreshUserInformation() {
        ServerAPI.shared.getUser(id: self.user.id) { (user: User?, error: Error?) in
            if user != nil {
                self.user = user!
                self.displayUserInformation()
            } else {
                self.report(error: error)
            }
        }
    }
    
    private func updateFollowButtonState() {
        let selected = self.user.isFollowed
        self.followButton.isSelected = selected
        self.followButton.setBackgroundImage(UIImage(named: selected ? "small-button-on" : "small-button-off"), for: UIControl.State.normal)
    }
    
    private func setDisplayedPosts(posts: [Post]) {
        self.posts = posts
        self.gridView.reloadData()
        self.placeholderLabel.isHidden = (posts.count > 0)
    }
    
    private func refreshPosts() {
        if self.postsViewModeControl.selectedSegmentIndex == 0 {
            ServerAPI.shared.getPostsOf(user: user) { (posts: [Post]?, error: Error?) in
                if posts != nil {
                    self.setDisplayedPosts(posts: posts!)
                } else {
                    self.report(error: error)
                }
            }
        } else {
            ServerAPI.shared.getPostsWithTaggedUser(user: user) { (posts: [Post]?, error: Error?) in
                if posts != nil {
                    self.setDisplayedPosts(posts: posts!)
                } else {
                    self.report(error: error)
                }
            }
        }
    }
    
    @IBAction private func setPostsViewMode() {
        if self.postsViewModeControl.selectedSegmentIndex == 0 {
            self.setDisplayedPosts(posts: Cache.shared.fetchPostsMadeBy(user: user))
        } else {
            self.setDisplayedPosts(posts: Cache.shared.fetchPostsWithTagged(user: user))
        }
        self.refreshPosts()
    }
    
    @IBAction private func toggleFollow() {
        self.user.toggleFollowed()
        self.updateFollowButtonState()
        
        ServerAPI.shared.updateUserFollowed(user: self.user) { (user: User?, error: Error?) in
            if user != nil {
                NotificationCenter.default.post(name: Notification.Name.FeedUpdatedNotification, object: nil)
            }
            if error != nil {
                self.report(error: error)
                self.user.toggleFollowed()
            }
            self.displayUserInformation()
        }
    }
    
    @IBAction private func editProfile() {
        let profileEditor = UserProfileEditorController() {
            self.user = User.current!
            self.displayUserInformation()
            self.dismiss(animated: true, completion: nil)
        }
        self.present(profileEditor, animated: true, completion: nil)
    }
    
    @IBAction private func showFollowers() {
        let userListViewController = UserListViewController(mode: UserListMode.followers, user: self.user)
        self.navigationController?.pushViewController(userListViewController, animated: true)
    }
    
    @IBAction private func showFollowees() {
        let userListViewController = UserListViewController(mode: UserListMode.followees, user: self.user)
        self.navigationController?.pushViewController(userListViewController, animated: true)
    }
    
    @objc private func showSavedPosts() {
        let postsViewController = PostsViewController(posts: Cache.shared.fetchSavedPosts()) { (completion: @escaping ([Post]?, Error?) -> Void) in
            ServerAPI.shared.getSavedPosts(completion: completion)
        }
        postsViewController.title = "Saved posts"
        postsViewController.placeholderText = "No saved posts"
        self.navigationController?.pushViewController(postsViewController, animated: true)
    }
    
    @objc private func newPostHasBeenCreated(notification: NSNotification) {
        if self.isViewLoaded {
            self.posts.insert(notification.object as! Post, at: 0)
            self.placeholderLabel.isHidden = true
            self.gridView.reloadData()
            self.displayUserInformation()
        }
    }
    
    @objc private func postHasBeenDeleted(notification: NSNotification) {
        if self.isViewLoaded {
            if let postIndex = self.posts.firstIndex(of: notification.object as! Post) {
                self.posts.remove(at: postIndex)
                self.placeholderLabel.isHidden = (self.posts.count > 0)
                self.gridView.reloadData()
                self.displayUserInformation()
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Post cell", for: indexPath) as! PostTileCell
        cell.imageView.showImageAsynchronously(imageURL: self.posts[indexPath.item].images?.first?.url)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let postsViewController = PostsViewController(posts: self.posts, refreshClosure: nil)
        postsViewController.title = "Posts"
        postsViewController.selectedPostIndex = indexPath.item
        self.navigationController?.pushViewController(postsViewController, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}


extension Notification.Name {
    public static let FeedUpdatedNotification = NSNotification.Name("Feed updated")
}
