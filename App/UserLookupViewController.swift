import UIKit


class UserLookupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    private var completion: (User?) -> Void
    private var searchResults = [User]()
    private var lookupRequestTask: URLSessionDataTask?
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var placeholderView: UIView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    init(completion: @escaping (User?) -> Void) {
        self.completion = completion
        super.init(nibName: "UserLookupView", bundle: nil)
        self.modalPresentationStyle = .fullScreen
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
        self.cancelSearchTasks()
        self.completion(self.searchResults[indexPath.row])
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.cancelSearchTasks()
        self.completion(nil)
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
        self.lookupRequestTask = ServerAPI.shared.findUsers(searchText: searchText) { (matchingUsers: [User]?, error: Error?) in
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
                return
            }
        }
    }
    
    @objc private func keyboardWillChangeFrame(notification: Notification) {
        let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let keyboardFrameInWindow = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTopOffset = self.view.bounds.maxY - self.view.safeAreaInsets.bottom - self.view.convert(keyboardFrameInWindow, from: nil).minY
        self.view.layoutMargins.bottom = max(keyboardTopOffset, 0)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
