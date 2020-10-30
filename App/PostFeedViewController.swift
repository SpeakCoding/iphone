import UIKit


class PostFeedViewController: UITableViewController {
    
    private var feed = Feed()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "SpeakCoding"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        
        self.tableView.register(UINib(nibName: "PostFeedCell", bundle: nil), forCellReuseIdentifier: "Post cell")
        self.tableView.estimatedRowHeight = 503
        
        let refreshControl = UIRefreshControl(frame: CGRect.zero)
        refreshControl.addTarget(self, action: #selector(refreshFeedPosts), for: UIControl.Event.valueChanged)
        refreshControl.layer.zPosition = -1
        self.refreshControl = refreshControl
        
        self.feed.posts = Cache.shared.fetchAllPosts()
        self.refreshFeedPosts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(newPostHasBeenCreated), name: Notification.Name.NewPostNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func newPostHasBeenCreated(notification: NSNotification) {
        self.feed.posts.insert(notification.object as! Post, at: 0)
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableView.RowAnimation.automatic)
    }
    
    @objc private func refreshFeedPosts() {
        ServerAPI.shared.getFeedPosts() { (posts: [Post]?, error: Error?) in
            self.refreshControl!.endRefreshing()
            if let posts = posts {
                self.feed.posts = posts
                self.tableView.reloadData()
            }
        }
    }
    
    
    // MARK: - UITableViewDataSource
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.feed.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCell = tableView.dequeueReusableCell(withIdentifier: "Post cell", for: indexPath) as! PostFeedCell
        postCell.setPost(self.feed.posts[indexPath.row])
        postCell.actionDelegate = self
        return postCell
    }
    
    
    // MARK: - PostFeedCell Actions
    
    
    func showUserProfile(_ user: User) {
        self.navigationController?.pushViewController(UserProfileViewController(user: user), animated: true)
    }
    
    func toggleLike(post: Post) {
        // The user must be authorized to like/unlike posts
        if User.current == nil {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.presentLoginFlow {
                self.toggleLike(post: post)
            }
            return
        }
        
        if post.isLiked {
            ServerAPI.shared.unlikePost(post, completion: self.updatePostOrReportError)
        } else {
            ServerAPI.shared.likePost(post, completion: self.updatePostOrReportError)
        }
    }
    
    func addComment(post: Post) {
        #warning("Not implemented")
    }
    
    func toggleBookmark(post: Post) {
        #warning("Not implemented")
    }
    
    func showAllComments(post: Post) {
        #warning("Not implemented")
    }
    
    private func updatePostOrReportError(post: Post?, error: Error?) {
        if post != nil {
            if let postIndex = self.feed.posts.firstIndex(of: post!) {
                self.tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: UITableView.RowAnimation.automatic)
            }
        } else {
            self.report(error: error)
        }
    }
}
