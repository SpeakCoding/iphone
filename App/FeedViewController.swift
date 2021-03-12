import UIKit


class FeedViewController: UITableViewController {
    
    private var feed = Feed()
    
    init() {
        super.init(style: UITableView.Style.plain)
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "feed-logo"))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(feedHasBeenUpdated), name: Notification.Name.NewPostNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(feedHasBeenUpdated), name: Notification.Name.PostDeletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(feedHasBeenUpdated), name: Notification.Name.FeedUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newCommentHasBeenCreated), name: Notification.Name.NewCommentNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "PostFeedView", bundle: nil), forCellReuseIdentifier: "post")
        self.tableView.estimatedRowHeight = PostFeedView.estimatedHeight
        self.tableView.separatorInset = UIEdgeInsets.zero
        
        let refreshControl = UIRefreshControl(frame: CGRect.zero)
        refreshControl.addTarget(self, action: #selector(updateFeedPosts), for: UIControl.Event.valueChanged)
        refreshControl.layer.zPosition = -1
        self.refreshControl = refreshControl
        
        if self.feed.posts.count == 0 {
            self.refreshControl!.beginRefreshing()
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        }
        self.updateFeedPosts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updateFeedPosts() {
        func processFeedRequestResult(error: Error?) {
            self.refreshControl!.endRefreshing()
            if error == nil {
                self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
                self.tableView.reloadData()
            }
        }
        self.feed.getPosts(completion: processFeedRequestResult)
    }
    
    @objc private func feedHasBeenUpdated(notification: NSNotification) {
        self.updateFeedPosts()
    }
    
    @objc private func newCommentHasBeenCreated(notification: NSNotification) {
        let post = notification.object as! Post
        if let postIndex = self.feed.posts.firstIndex(of: post) {
            self.tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: UITableView.RowAnimation.none)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.feed.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCell = tableView.dequeueReusableCell(withIdentifier: "post", for: indexPath) as! PostFeedView
        postCell.setPost(self.feed.posts[indexPath.row])
        postCell.viewController = self
        return postCell
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
