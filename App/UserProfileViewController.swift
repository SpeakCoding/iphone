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
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "button-ellipsis"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(showOptions))
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
            self.followButton.isHidden = true
        } else {
            self.editProfileButton.isHidden = true
            self.followButton.setTitleColor(UIColor.white, for: UIControl.State.selected)
            self.followButton.setTitleColor(UIColor.white, for: [UIControl.State.selected, UIControl.State.highlighted])
            self.followButton.setTitle("Unfollow", for: UIControl.State.selected)
            self.followButton.setTitle("Unfollow", for: [UIControl.State.selected, UIControl.State.highlighted])
        }
        
        self.displayUserInformation()
        self.updateUserInformation()
        
        self.gridView.register(PostTileView.self, forCellWithReuseIdentifier: "post")
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
    
    private func updateUserInformation() {
        func processUserRequestResult(user: User?, error: Error?) {
            if user != nil {
                self.user = user!
                self.displayUserInformation()
            } else {
                self.report(error: error)
            }
        }
        ServerAPI.shared.getUser(id: self.user.id, completion: processUserRequestResult)
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
    
    private func updatePosts() {
        func processPostsRequestResult(posts: [Post]?, error: Error?) {
            if posts != nil {
                self.setDisplayedPosts(posts: posts!)
            } else {
                self.report(error: error)
            }
        }
        if self.postsViewModeControl.selectedSegmentIndex == 0 {
            self.user.getPosts(completion: processPostsRequestResult)
        } else {
            self.user.getPostsWhereTagged(completion: processPostsRequestResult)
        }
    }
    
    @IBAction private func setPostsViewMode() {
        if self.postsViewModeControl.selectedSegmentIndex == 0 {
            self.setDisplayedPosts(posts: Cache.shared.fetchPostsMadeBy(user: user))
        } else {
            self.setDisplayedPosts(posts: Cache.shared.fetchPostsWithTagged(user: user))
        }
        self.updatePosts()
    }
    
    @IBAction private func toggleFollow() {
        func processUserUpdateRequestResult(error: Error?) {
            if error != nil {
                self.report(error: error)
            } else {
                NotificationCenter.default.post(name: Notification.Name.FeedUpdatedNotification, object: nil)
            }
            self.displayUserInformation()
        }
        self.user.toggleFollowed(completion: processUserUpdateRequestResult)
        self.updateFollowButtonState()
    }
    
    @IBAction private func editProfile() {
        func handleUserProfileUpdate(profileUpdated: Bool) {
            if profileUpdated {
                self.displayUserInformation()
            }
            self.dismiss(animated: true, completion: nil)
        }
        let profileEditor = UserProfileEditorController(completion: handleUserProfileUpdate)
        let navigationController = UINavigationController(rootViewController: profileEditor)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction private func showAllPostsAsList() {
        if self.posts.count > 0 {
            self.showAllPostsAsList(preselectedPostIndex: 0)
        }
    }
    
    private func showAllPostsAsList(preselectedPostIndex: Int) {
        let postsViewController = UserPostsViewController(posts: self.posts, refreshClosure: nil)
        postsViewController.title = "Posts"
        postsViewController.selectedPostIndex = preselectedPostIndex
        self.navigationController?.pushViewController(postsViewController, animated: true)
    }
    
    @IBAction private func showFollowers() {
        let usersListViewController = UsersListViewController(UserKind.followers(self.user))
        self.navigationController?.pushViewController(usersListViewController, animated: true)
    }
    
    @IBAction private func showFollowees() {
        let usersListViewController = UsersListViewController(UserKind.followees(self.user))
        self.navigationController?.pushViewController(usersListViewController, animated: true)
    }
    
    @objc private func showOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "Show Saved Posts", style: UIAlertAction.Style.default, handler: showSavedPosts))
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertAction.Style.default, handler: confirmLogout))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showSavedPosts(_: UIAlertAction) {
        let postsViewController = UserPostsViewController(posts: Cache.shared.fetchSavedPosts(), refreshClosure: { (completion: @escaping ([Post]?, Error?) -> Void) in
            ServerAPI.shared.getSavedPosts(completion: completion)
        })
        postsViewController.title = "Saved posts"
        postsViewController.placeholderText = "No saved posts"
        self.navigationController?.pushViewController(postsViewController, animated: true)
    }
    
    private func confirmLogout(_: UIAlertAction) {
        let alert = UIAlertController(title: "Are you sure you want to log out?", message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertAction.Style.destructive, handler: logout))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func logout(_: UIAlertAction) {
        func processLogOutRequestResult(error: Error?) {
            if error != nil {
                self.report(error: error)
            } else {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.showLoginView()
                User.setCurrentUser(nil)
                ModelObject.purgeCachedInstances()
                Cache.shared.reset()
            }
        }
        ServerAPI.shared.logOut(completion: processLogOutRequestResult)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: indexPath) as! PostTileView
        cell.imageView.showImageAsynchronously(imageURL: self.posts[indexPath.item].images?.first?.url)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.showAllPostsAsList(preselectedPostIndex: indexPath.item)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}


extension Notification.Name {
    public static let FeedUpdatedNotification = NSNotification.Name("Feed updated")
}
