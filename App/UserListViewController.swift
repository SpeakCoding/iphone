import UIKit


enum UserKind {
    case followers(User)
    case followees(User)
    case likers(Post)
}

class UserListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    private var mode: UserKind
    private var users = [User]()
    private var filteredUsers: [User]?
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var placeholderLabel: UILabel!
    private var searchBar: UISearchBar?
    
    init(_ userKind: UserKind) {
        self.mode = userKind
        super.init(nibName: "UserListView", bundle: nil)
    }
    
    init(usersWhoLiked post: Post) {
        self.mode = UserKind.likers(post)
        super.init(nibName: "UserListView", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "UserCell+FollowButton", bundle: nil), forCellReuseIdentifier: "User cell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.placeholderLabel.isHidden = true
        switch self.mode {
        case .followers(let user):
            self.title = "Followers"
            ServerAPI.shared.getFollowers(user: user, completion: self.displayAllUsers)
        case .followees(let user):
            self.title = "Following"
            ServerAPI.shared.getFollowees(user: user, completion: self.displayAllUsers)
        case .likers(let post):
            self.title = "Likes"
            ServerAPI.shared.getUsersWhoLiked(post: post, completion: self.displayAllUsers)
        }
    }
    
    func displayAllUsers(users: [User]?, error: Error?) {
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
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "User cell", for: indexPath) as! UserCell
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
            self.filteredUsers = self.users.filter({ (user: User) -> Bool in
                return user.userName.lowercased().contains(searchText.lowercased())
            })
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
