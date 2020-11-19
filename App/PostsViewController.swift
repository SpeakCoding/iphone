import UIKit


class PostsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, PostFeedCellActionDelegate {
    
    var placeholderText: String?
    private var posts = [Post]()
    private var refreshClosure: (@escaping ([Post]?, Error?) -> Void) -> Void
    private var gridView: UICollectionView?
    private var tableView: UITableView?
    private var placeholderLabel: UILabel?
    
    init(posts: [Post], refreshClosure: @escaping (@escaping ([Post]?, Error?) -> Void) -> Void) {
        self.posts = posts
        self.refreshClosure = refreshClosure
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.displayPosts()
        self.refreshClosure({ (posts: [Post]?, error: Error?) in
            if posts != nil {
                self.posts = posts!
                self.displayPosts()
            }
        })
    }
    
    private func displayPosts() {
        if self.posts.count > 0 {
            if gridView != nil {
                gridView!.reloadData()
                return
            }
            if tableView != nil {
                tableView!.reloadData()
                return
            }
            
            let cellWidth = UIScreen.main.bounds.size.width / 3.0
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            
            gridView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            gridView!.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
            gridView!.register(PostTileCell.self, forCellWithReuseIdentifier: "Post cell")
            gridView!.dataSource = self
            gridView!.delegate = self
            gridView!.backgroundColor = UIColor.white
            self.view.addSubview(gridView!)
            
            placeholderLabel?.removeFromSuperview()
            placeholderLabel = nil
        } else {
            gridView?.removeFromSuperview()
            gridView = nil
            tableView?.removeFromSuperview()
            tableView = nil
            
            if placeholderLabel != nil {
                return
            }
            
            placeholderLabel = UILabel(frame: CGRect.zero)
            placeholderLabel!.font = UIFont.systemFont(ofSize: 16)
            placeholderLabel!.textColor = UIColor.placeholderText
            placeholderLabel!.text = placeholderText
            placeholderLabel!.sizeToFit()
            self.view.addSubview(placeholderLabel!)
            
            placeholderLabel!.translatesAutoresizingMaskIntoConstraints = false
            placeholderLabel!.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            placeholderLabel!.centerYAnchor.constraint(equalTo: self.view.topAnchor, constant: UIScreen.main.bounds.size.height / 3).isActive = true
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
        tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView!.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        tableView!.register(UINib(nibName: "PostFeedCell", bundle: nil), forCellReuseIdentifier: "Post cell")
        tableView!.estimatedRowHeight = 503
        tableView!.dataSource = self
        tableView!.delegate = self
        self.view.addSubview(tableView!)
        tableView!.layoutIfNeeded()
        tableView!.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: false)
        
        gridView?.removeFromSuperview()
        gridView = nil
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCell = tableView.dequeueReusableCell(withIdentifier: "Post cell", for: indexPath) as! PostFeedCell
        postCell.setPost(self.posts[indexPath.row])
        postCell.actionDelegate = self
        return postCell
    }
    
    // MARK: - PostFeedCellActionDelegate
    
    func showUserProfile(_ user: User) {
        let userProfileViewer = UserProfileViewController(user: user)
        self.navigationController?.pushViewController(userProfileViewer, animated: true)
    }
    
    func toggleLike(postFeedCell: PostFeedCell) {
        let post = postFeedCell.post!
        post.toggleLike()
        
        ServerAPI.shared.updatePostLike(post, completion: { (updatedPost: Post?, error: Error?) in
            if error != nil {
                self.report(error: error)
                post.toggleLike()
            }
            if postFeedCell.post == post {
                postFeedCell.setPost(post)
            } else {
                // The table view has reused the post feed cell for another post while the network request was in progress
                if let postIndex = self.posts.firstIndex(of: post) {
                    self.tableView?.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: UITableView.RowAnimation.none)
                }
            }
        })
    }
    
    func toggleSaved(postFeedCell: PostFeedCell) {
        let post = postFeedCell.post!
        post.toggleSaved()
        
        ServerAPI.shared.updatePostSaved(post, completion: { (updatedPost: Post?, error: Error?) in
            if error != nil {
                self.report(error: error)
                post.toggleSaved()
            }
            if postFeedCell.post == post {
                postFeedCell.setPost(post)
            } else {
                // The table view has reused the post feed cell for another post while the network request was in progress
                if let postIndex = self.posts.firstIndex(of: post) {
                    self.tableView?.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: UITableView.RowAnimation.none)
                }
            }
        })
    }
    
    func addComment(postFeedCell: PostFeedCell) {
        #warning("Not implemented")
    }
    
    func showAllComments(postFeedCell: PostFeedCell) {
        #warning("Not implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
