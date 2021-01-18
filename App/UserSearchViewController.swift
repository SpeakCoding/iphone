import UIKit


class UserSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private var searchResults = [User]()
    private var lookupRequestTask: URLSessionDataTask?
    private var searchBar: UISearchBar!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var placeholderView: UIView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var tableViewBottomOffset: NSLayoutConstraint!
    
    init() {
        self.searchBar = UISearchBar(frame: CGRect.zero)
        super.init(nibName: "UserSearchView", bundle: nil)
        
        self.searchBar.placeholder = "Search for a person"
        self.searchBar.showsCancelButton = true
        self.searchBar.delegate = self
        self.searchBar.sizeToFit()
        self.navigationItem.titleView = self.searchBar
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "User cell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.placeholderView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.searchBar.becomeFirstResponder()
        if let selection = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selection, animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "User cell", for: indexPath) as! UserCell
        tableViewCell.setUser(self.searchResults[indexPath.row])
        return tableViewCell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userProfileViewer = UserProfileViewController(user: self.searchResults[indexPath.row])
        self.navigationController?.pushViewController(userProfileViewer, animated: true)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.cancelSearchTasks()
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.cancelSearchTasks()
        if searchText.count > 0 {
            self.perform(#selector(performSearch), with: searchText, afterDelay: 0.25)
        } else {
            self.placeholderView.isHidden = true
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.cancelSearchTasks()
        let searchText = self.searchBar.text ?? ""
        if searchText.count > 0 {
            performSearch(searchText: searchText)
        } else {
            self.placeholderView.isHidden = true
        }
    }
    
    private func cancelSearchTasks() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.lookupRequestTask?.cancel()
        self.lookupRequestTask = nil
    }
    
    @objc func performSearch(searchText: String) {
        self.placeholderView.isHidden = false
        self.placeholderLabel.isHidden = true
        self.activityIndicator.startAnimating()
        func processUserLookupRequestResult(matchingUsers: [User]?, error: Error?) {
            if matchingUsers != nil {
                self.searchResults = matchingUsers!
                self.tableView.reloadData()
                self.placeholderView.isHidden = matchingUsers!.count > 0
                self.placeholderLabel.text = "Nobody found"
                self.placeholderLabel.isHidden = false
                self.activityIndicator.stopAnimating()
            }
            
            if error != nil {
                if (error! as NSError).code != NSURLErrorCancelled {
                    self.placeholderLabel.text = (error! as NSError).localizedDescription
                    self.placeholderLabel.isHidden = false
                    self.activityIndicator.stopAnimating()
                }
            }
        }
        self.lookupRequestTask = ServerAPI.shared.findUsers(searchText: searchText, completion: processUserLookupRequestResult)
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.convert(keyboardFrameInWindow, from: nil).minY
        self.tableViewBottomOffset.constant = max(keyboardTopOffset, 0)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
