import UIKit


enum UserListMode {
    case followers
    case followees
}

class UserListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    private var mode: UserListMode
    private var user: User
    private var users = [User]()
    private var filteredUsers: [User]?
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var placeholderLabel: UILabel!
    private var searchBar: UISearchBar?
    
    init(mode: UserListMode, user: User) {
        self.mode = mode
        self.user = user
        super.init(nibName: "UserListView", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "UserCell+FollowButton", bundle: nil), forCellReuseIdentifier: "User cell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.rowHeight = 64
        
        self.placeholderLabel.isHidden = true
        switch self.mode {
        case .followers:
            self.title = "Followers"
            ServerAPI.shared.getFollowers(user: self.user, completion: self.displayAllUsers)
        case .followees:
            self.title = "Following"
            ServerAPI.shared.getFollowees(user: self.user, completion: self.displayAllUsers)
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
