import UIKit


class PostFeedViewController: UITableViewController {
    
    private var feed = Feed()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "SpeakCoding"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        tableView.register(UINib(nibName: "PostFeedCell", bundle: nil), forCellReuseIdentifier: "Post cell")
        tableView.estimatedRowHeight = 503
        
        ServerAPI.shared.getFeedPosts(startPostIndex: 0) { (posts: [Post]?, error: Error?) in
            if let posts = posts {
                self.feed.posts.append(contentsOf: posts)
                self.tableView.reloadData()
            } else {
                self.report(error: error)
            }
        }
    }
    
    
    // MARK: - UITableViewDataSource
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCell = tableView.dequeueReusableCell(withIdentifier: "Post cell", for: indexPath) as! PostFeedCell
        postCell.setPost(feed.posts[indexPath.row])
        postCell.actionDelegate = self
        return postCell
    }
}


extension PostFeedViewController: PostFeedCellDelegate {
    func showUserProfile(_ user: User) {
        navigationController?.pushViewController(UserProfileViewController(user: user), animated: true)
    }
    
    func toggleLike(post: Post) {
        #warning("Not implemented")
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
