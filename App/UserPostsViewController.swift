import UIKit


class UserPostsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var placeholderText: String?
    var selectedPostIndex: Int?
    private var posts = [Post]()
    private var refreshClosure: ((@escaping ([Post]?, Error?) -> Void) -> Void)?
    private var gridView: UICollectionView?
    private var tableView: UITableView?
    private var placeholderLabel: UILabel?
    private var shouldDisplaySelectedPostAfterLayout = false
    
    init(posts: [Post], refreshClosure: ((@escaping ([Post]?, Error?) -> Void) -> Void)?) {
        self.posts = posts
        self.refreshClosure = refreshClosure
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postHasBeenDeleted), name: Notification.Name.PostDeletedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newCommentHasBeenCreated), name: Notification.Name.NewCommentNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        if self.selectedPostIndex != nil {
            /*
             In order to display a specific post, we have to scroll the table view to its representing cell's offset.
             Since cell heights depend on the screen width, their offsets also depend on the screen width.
             That means we have to let the table view layout its cells before we can scroll it to a specific cell.
             To do this we set a flag and check it in viewDidLayoutSubviews() to finally call displayPostsAsList().
            */
            self.shouldDisplaySelectedPostAfterLayout = true
        } else {
            self.updateDisplayedPosts()
        }
        
        if let refreshClosure = self.refreshClosure {
            refreshClosure({ (posts: [Post]?, error: Error?) in
                if posts != nil {
                    self.posts = posts!
                    self.updateDisplayedPosts()
                }
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.shouldDisplaySelectedPostAfterLayout {
            if self.selectedPostIndex != nil {
                self.displayPostsAsList()
            }
            self.shouldDisplaySelectedPostAfterLayout = false
        }
    }
    
    private func updateDisplayedPosts() {
        if self.posts.count > 0 {
            if self.gridView != nil {
                self.gridView!.reloadData()
                return
            }
            if self.tableView != nil {
                self.tableView!.reloadData()
                return
            }
            
            let cellWidth = UIScreen.main.bounds.size.width / 3.0
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            
            self.gridView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            self.gridView!.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
            self.gridView!.register(PostTileCell.self, forCellWithReuseIdentifier: "Post cell")
            self.gridView!.dataSource = self
            self.gridView!.delegate = self
            self.gridView!.backgroundColor = UIColor.white
            self.view.addSubview(self.gridView!)
            
            self.placeholderLabel?.removeFromSuperview()
            self.placeholderLabel = nil
        } else {
            self.gridView?.removeFromSuperview()
            self.gridView = nil
            self.tableView?.removeFromSuperview()
            self.tableView = nil
            
            if self.placeholderLabel != nil {
                return
            }
            
            self.placeholderLabel = UILabel(frame: CGRect.zero)
            self.placeholderLabel!.font = UIFont.systemFont(ofSize: 16)
            self.placeholderLabel!.textColor = UIColor.placeholderText
            self.placeholderLabel!.text = self.placeholderText
            self.placeholderLabel!.sizeToFit()
            self.view.addSubview(self.placeholderLabel!)
            
            self.placeholderLabel!.translatesAutoresizingMaskIntoConstraints = false
            self.placeholderLabel!.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            self.placeholderLabel!.centerYAnchor.constraint(equalTo: self.view.topAnchor, constant: UIScreen.main.bounds.size.height / 3).isActive = true
        }
    }
    
    private func displayPostsAsList() {
        self.tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        self.tableView!.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        self.tableView!.register(UINib(nibName: "PostFeedCell", bundle: nil), forCellReuseIdentifier: "Post cell")
        self.tableView!.estimatedRowHeight = 503
        self.tableView!.dataSource = self
        self.tableView!.delegate = self
        self.view.addSubview(self.tableView!)
        self.tableView!.layoutIfNeeded()
        self.tableView!.scrollToRow(at: IndexPath(row: self.selectedPostIndex!, section: 0), at: UITableView.ScrollPosition.top, animated: false)
    }
    
    @objc private func postHasBeenDeleted(notification: NSNotification) {
        if self.isViewLoaded {
            if let postIndex = self.posts.firstIndex(of: notification.object as! Post) {
                self.posts.remove(at: postIndex)
                self.updateDisplayedPosts()
            }
        }
    }
    
    @objc private func newCommentHasBeenCreated(notification: NSNotification) {
        if self.tableView != nil {
            let post = notification.object as! Post
            if let postIndex = self.posts.firstIndex(of: post) {
                self.tableView!.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: UITableView.RowAnimation.none)
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
        self.selectedPostIndex = indexPath.item
        self.displayPostsAsList()
        self.gridView?.removeFromSuperview()
        self.gridView = nil
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCell = tableView.dequeueReusableCell(withIdentifier: "Post cell", for: indexPath) as! PostFeedCell
        postCell.setPost(self.posts[indexPath.row])
        postCell.viewController = self
        return postCell
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
