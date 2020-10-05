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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initCacheDatabase()
        
        // Set up view controllers behind the tab bar items
        let homeTabViewController = UINavigationController(rootViewController: PostFeedViewController())
        homeTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-home"), selectedImage: UIImage(named: "tab-bar-item-home-selected"))
        homeTabViewController.tabBarItem.tag = TabBarItemTag.home.rawValue
        
        let newPostTabViewController = UIViewController(nibName: nil, bundle: nil)
        newPostTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-post"), selectedImage: UIImage(named: "tab-bar-item-post-selected"))
        newPostTabViewController.tabBarItem.tag = TabBarItemTag.newPost.rawValue
        
        let likedPostsTabViewController = UINavigationController(nibName: nil, bundle: nil)
        likedPostsTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-likes"), selectedImage: UIImage(named: "tab-bar-item-likes-selected"))
        likedPostsTabViewController.tabBarItem.tag = TabBarItemTag.likedPosts.rawValue
        
        let profileTabViewController = UINavigationController(nibName: nil, bundle: nil)
        profileTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-profile"), selectedImage: UIImage(named: "tab-bar-item-profile-selected"))
        profileTabViewController.tabBarItem.tag = TabBarItemTag.profile.rawValue
        
        // Set up the tab bar controller and display it in the app's window
        self.tabBarController = UITabBarController(nibName: nil, bundle: nil)
        self.tabBarController.viewControllers = [homeTabViewController, newPostTabViewController, likedPostsTabViewController, profileTabViewController]
        self.tabBarController.delegate = self
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = self.tabBarController
        self.window!.makeKeyAndVisible()
        
        return true
    }
    
    private func initCacheDatabase() {
        #warning("Not implemented")
        
        #warning("Fetch current user from DB")
        let currentUserID = UserDefaults.standard.integer(forKey: "Current user ID")
        if currentUserID != 0 {
            let currentUser = User(userName: "")
            currentUser.id = currentUserID
            User.current = currentUser
        }
    }
    
    func presentLoginFlow(completion: @escaping () -> Void) {
        let loginViewController = LoginViewController(emailAddress: nil, completion: completion)
        let loginFlowNavigationController = UINavigationController(rootViewController: loginViewController)
        loginFlowNavigationController.isNavigationBarHidden = true
        self.tabBarController.present(loginFlowNavigationController, animated: true, completion: nil)
    }
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        switch TabBarItemTag(rawValue: viewController.tabBarItem.tag) {
        case .home, .none:
            // Display the post feed to both authorized users and anonymous ones
            return true
            
        case .newPost:
            // The tab cannot be actually selected.
            // Instead ask the user to log in before they can select the image source.
            if User.current != nil {
                tabBarController.presentImagePicker(completion: nil)
            } else {
                self.presentLoginFlow(completion: {
                    tabBarController.dismiss(animated: true) {
                        tabBarController.presentImagePicker(completion: nil)
                    }
                })
            }
            return false
            
        case .likedPosts:
            // The user has to log in to see their liked posts
            let navigationController = viewController as! UINavigationController
            let rootViewController = navigationController.viewControllers.first
            if User.current != nil {
                if rootViewController == nil {
                    navigationController.pushViewController(LikedPostsViewController(), animated: false)
                }
                return true
            }
            
            self.presentLoginFlow(completion: {
                navigationController.setViewControllers([LikedPostsViewController()], animated: false)
                tabBarController.selectedIndex = TabBarItemTag.likedPosts.rawValue
                tabBarController.dismiss(animated: true, completion: nil)
            })
            return false
            
        case .profile:
            // The user has to log in to see their profile
            let navigationController = viewController as! UINavigationController
            let rootViewController = navigationController.viewControllers.first
            if let currentUser = User.current {
                if rootViewController == nil {
                    navigationController.pushViewController(UserProfileViewController(user: currentUser), animated: false)
                }
                return true
            }
            
            self.presentLoginFlow(completion: {
                navigationController.setViewControllers([UserProfileViewController(user: User.current!)], animated: false)
                tabBarController.selectedIndex = TabBarItemTag.profile.rawValue
                tabBarController.dismiss(animated: true, completion: nil)
            })
            return false
        }
    }
}
