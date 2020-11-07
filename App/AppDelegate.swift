import UIKit


enum TabBarItemTag: Int {
    case home
    case newPost
    case likedPosts
    case profile
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {
    
    var window: UIWindow?
    var tabBarController: UITabBarController!
    
    override init() {
        super.init()
        if ProcessInfo().arguments.contains("reset-all") {
            UserDefaults.standard.removeObject(forKey: "current user ID")
            UserDefaults.standard.removeObject(forKey: "access token")
            let cachesURL = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!
            try? FileManager().removeItem(atPath: cachesURL.path)
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        User.initCurrentUser()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        if User.current == nil {
            let loginViewController = LoginViewController(emailAddress: nil) {
                self.setupUI()
                self.window!.rootViewController = self.tabBarController
            }
            let loginFlowNavigationController = UINavigationController(rootViewController: loginViewController)
            loginFlowNavigationController.modalPresentationStyle = .fullScreen
            loginFlowNavigationController.isNavigationBarHidden = true
            self.window!.rootViewController = loginFlowNavigationController
        } else {
            self.setupUI()
            self.window!.rootViewController = self.tabBarController
        }
        self.window!.makeKeyAndVisible()
        
        return true
    }
    
    private func setupUI() {
        // Set up view controllers behind the tab bar items
        let homeTabViewController = UINavigationController(rootViewController: PostFeedViewController())
        homeTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-home"), selectedImage: UIImage(named: "tab-bar-item-home-selected"))
        homeTabViewController.tabBarItem.tag = TabBarItemTag.home.rawValue
        
        let newPostTabViewController = UIViewController(nibName: nil, bundle: nil)
        newPostTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-post"), selectedImage: UIImage(named: "tab-bar-item-post-selected"))
        newPostTabViewController.tabBarItem.tag = TabBarItemTag.newPost.rawValue
        
        let likedPostsTabViewController = UINavigationController(rootViewController: LikedPostsViewController())
        likedPostsTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-likes"), selectedImage: UIImage(named: "tab-bar-item-likes-selected"))
        likedPostsTabViewController.tabBarItem.tag = TabBarItemTag.likedPosts.rawValue
        
        let profileTabViewController = UINavigationController(rootViewController: UserProfileViewController(user: User.current!))
        profileTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-profile"), selectedImage: UIImage(named: "tab-bar-item-profile-selected"))
        profileTabViewController.tabBarItem.tag = TabBarItemTag.profile.rawValue
        
        // Set up the tab bar controller and display it in the app's window
        self.tabBarController = UITabBarController(nibName: nil, bundle: nil)
        self.tabBarController.viewControllers = [homeTabViewController, newPostTabViewController, likedPostsTabViewController, profileTabViewController]
        self.tabBarController.delegate = self
    }
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == TabBarItemTag.newPost.rawValue {
            // The new post tab cannot actually be selected
            tabBarController.presentImagePicker(completion: nil)
            return false
        }
        return true
    }
}
