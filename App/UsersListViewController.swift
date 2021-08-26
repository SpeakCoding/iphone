import UIKit


class UsersListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    private var users = [User]()
    private var filteredUsers: [User]?
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var placeholderLabel: UILabel!
    private var searchBar: UISearchBar?
    
    init() {
        super.init(nibName: "UsersListView", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "UserCellView+FollowButton", bundle: nil), forCellReuseIdentifier: "user")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.placeholderLabel.isHidden = true
        
        self.getUsers()
    }
    
    internal func getUsers() {
        fatalError("Concrete subclasses must override this function")
    }
    
    internal func processUsersRequestResult(users: [User]?, error: Error?) {
        if users != nil {
            self.users = users!
            self.tableView.reloadData()
            self.updatePlaceholderVisibility()
            
            if self.placeholderLabel.isHidden && self.searchBar == nil {
                self.searchBar = UISearchBar(frame: CGRect.zero)
                self.searchBar!.placeholder = "User name"
                self.searchBar!.sizeToFit()
                self.searchBar!.delegate = self
                self.tableView.tableHeaderView = self.searchBar!
            }
        } else {
            self.report(error: error)
        }
    }
    
    private var displayedUsers: [User] {
        get { self.filteredUsers ?? self.users }
    }
    
    private func updatePlaceholderVisibility() {
        let hasUsersToDisplay = (self.displayedUsers.count > 0)
        self.placeholderLabel.isHidden = hasUsersToDisplay
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.displayedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! UserCellView
        tableViewCell.setUser(self.displayedUsers[indexPath.row])
        return tableViewCell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userProfileViewer = UserProfileViewController(user: self.displayedUsers[indexPath.row])
        self.navigationController?.pushViewController(userProfileViewer, animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            let lowercaseSearchText = searchText.lowercased()
            var matchingUsers = [User]()
            for user in self.users {
                if user.userName.lowercased().contains(lowercaseSearchText) {
                    matchingUsers.append(user)
                }
            }
        } else {
            self.filteredUsers = nil
        }
        self.tableView.reloadData()
        self.updatePlaceholderVisibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selection = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selection, animated: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}


class FollowersListViewController: UsersListViewController {
    private var user: User
    
    init(user: User) {
        self.user = user
        super.init()
        self.title = "Followers"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func getUsers() {
        self.user.getFollowers(completion: processUsersRequestResult)
    }
}


class FolloweesListViewController: UsersListViewController {
    private var user: User
    
    init(user: User) {
        self.user = user
        super.init()
        self.title = "Following"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func getUsers() {
        self.user.getFollowees(completion: processUsersRequestResult)
    }
}


class PostLikersListViewController: UsersListViewController {
    private var post: Post
    
    init(post: Post) {
        self.post = post
        super.init()
        self.title = "Likes"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func getUsers() {
        self.post.getUsersWhoLiked(completion: processUsersRequestResult)
    }
}
