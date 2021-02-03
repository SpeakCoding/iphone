import UIKit


class LikesViewController: UITableViewController {
    
    private var likes = [Like]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Likes"
        self.tableView.register(UINib(nibName: "LikeCell", bundle: nil), forCellReuseIdentifier: "Like cell")
        self.tableView.rowHeight = 62
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        let refreshControl = UIRefreshControl(frame: CGRect.zero)
        refreshControl.addTarget(self, action: #selector(updateLikes), for: UIControl.Event.valueChanged)
        refreshControl.layer.zPosition = -1
        self.refreshControl = refreshControl
        
        self.refreshControl!.beginRefreshing()
        self.updateLikes()
    }
    
    @objc private func updateLikes() {
        func processLikesRequestResult(likes: [Like]?, error: Error?) {
            self.refreshControl!.endRefreshing()
            if likes != nil {
                self.likes = likes!
                self.tableView.reloadData()
            }
        }
        ServerAPI.shared.getLikes(user: User.current!, completion: processLikesRequestResult)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.likes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let likeCell = tableView.dequeueReusableCell(withIdentifier: "Like cell", for: indexPath) as! LikeCell
        likeCell.setLike(self.likes[indexPath.row])
        return likeCell
    }
}
