import UIKit


class PostFeedViewController: UITableViewController {
    
    private var posts = [Post]()
    private var totalPostCount: Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "SpeakCoding"
        
        self.tableView.register(UINib(nibName: "PostFeedCell", bundle: nil), forCellReuseIdentifier: "Post cell")
        self.tableView.estimatedRowHeight = 503
        
        ServerAPI.shared.getFeedPosts(startPostIndex: 0) { (morePosts: [Post]?, error: Error?) in
            if let morePosts = morePosts {
                self.posts.append(contentsOf: morePosts)
                self.totalPostCount = self.posts.count
                self.tableView.reloadData()
            } else {
                self.report(error: error)
            }
        }
    }
    
    
    // MARK: - UITableViewDataSource
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if totalPostCount != nil {
            return posts.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postCell = tableView.dequeueReusableCell(withIdentifier: "Post cell", for: indexPath) as! PostFeedCell
        postCell.setPost(posts[indexPath.row])
        postCell.actionDelegate = self
        return postCell
    }
}


extension PostFeedViewController: PostFeedCellDelegate {
    func showUserProfile(_ user: User) {
        self.navigationController?.pushViewController(UserProfileViewController(user: user), animated: true)
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
