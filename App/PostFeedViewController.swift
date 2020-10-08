import UIKit


class PostFeedViewController: UITableViewController {
    
    private var feed = Feed()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "SpeakCoding"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        
        self.tableView.register(UINib(nibName: "PostFeedCell", bundle: nil), forCellReuseIdentifier: "Post cell")
        self.tableView.estimatedRowHeight = 503
        
        self.feed.posts = Cache.shared.fetchAllPosts()
        ServerAPI.shared.getFeedPosts(startPostIndex: 0) { (posts: [Post]?, error: Error?) in
            if let posts = posts {
                self.feed.posts = posts
                #warning("Paged loading is not implemented")
//                self.feed.posts.append(contentsOf: posts)
                self.tableView.reloadData()
            } else {
                self.report(error: error)
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
}


extension PostFeedViewController: PostFeedCellDelegate {
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
            ServerAPI.shared.unlikePost(post) { (updatedPost: Post?, error: Error?) in
                updatePost(updatedPost, error: error)
            }
        } else {
            ServerAPI.shared.likePost(post) { (updatedPost: Post?, error: Error?) in
                updatePost(updatedPost, error: error)
            }
        }
        
        func updatePost(_ updatedPost: Post?, error: Error?) {
            if updatedPost != nil {
                let postIndex = self.feed.posts.firstIndex(of: post)
                if postIndex != nil {
                    self.feed.posts[postIndex!] = updatedPost!
                    self.tableView.reloadRows(at: [IndexPath(row: postIndex!, section: 0)], with: UITableView.RowAnimation.automatic)
                }
            } else {
                self.report(error: error)
            }
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
}
