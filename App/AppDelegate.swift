import UIKit
import Amplitude


enum TabBarItemTag: Int {
    case home
    case search
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
        self.window!.tintColor = UIColor(named: "sc-blue")
        if User.current == nil {
            self.showLoginView()
        } else {
            self.setupTabsView()
        }
        self.window!.makeKeyAndVisible()
        
        let amplitude = Amplitude.instance()
        amplitude.trackingSessionEvents = true
        amplitude.initializeApiKey("ac02c1be6e17c79c7dc63418252d9a29")
        amplitude.trackingSessionEvents = true
        amplitude.logEvent("appstart")
        
        return true
    }
    
    func showLoginView() {
        self.tabBarController = nil
        
        let loginViewController = LoginViewController(emailAddress: nil, completion: self.setupTabsView)
        let loginFlowNavigationController = UINavigationController(rootViewController: loginViewController)
        loginFlowNavigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        loginFlowNavigationController.isNavigationBarHidden = true
        self.window!.rootViewController = loginFlowNavigationController
    }
    
    private func setupTabsView() {
        // Set up view controllers behind the tab bar items
        let homeTabViewController = UINavigationController(rootViewController: FeedViewController())
        homeTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-home"), selectedImage: UIImage(named: "tab-bar-item-home-selected"))
        homeTabViewController.tabBarItem.tag = TabBarItemTag.home.rawValue
        
        let usersSearchViewController = UINavigationController(rootViewController: UsersSearchViewController())
        usersSearchViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-search"), selectedImage: UIImage(named: "tab-bar-item-search-selected"))
        usersSearchViewController.tabBarItem.tag = TabBarItemTag.search.rawValue
        
        let newPostTabViewController = UIViewController(nibName: nil, bundle: nil)
        newPostTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-post"), selectedImage: UIImage(named: "tab-bar-item-post-selected"))
        newPostTabViewController.tabBarItem.tag = TabBarItemTag.newPost.rawValue
        
        let likedPostsTabViewController = UINavigationController(rootViewController: LikesViewController())
        likedPostsTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-likes"), selectedImage: UIImage(named: "tab-bar-item-likes-selected"))
        likedPostsTabViewController.tabBarItem.tag = TabBarItemTag.likedPosts.rawValue
        
        let profileTabViewController = UINavigationController(rootViewController: UserProfileViewController(user: User.current!))
        profileTabViewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab-bar-item-profile"), selectedImage: UIImage(named: "tab-bar-item-profile-selected"))
        profileTabViewController.tabBarItem.tag = TabBarItemTag.profile.rawValue
        
        // Set up the tab bar controller and display it in the app's window
        self.tabBarController = UITabBarController(nibName: nil, bundle: nil)
        self.tabBarController.viewControllers = [homeTabViewController, usersSearchViewController, newPostTabViewController, likedPostsTabViewController, profileTabViewController]
        self.tabBarController.delegate = self
        self.window!.rootViewController = self.tabBarController
    }
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == TabBarItemTag.newPost.rawValue {
            // The new post tab cannot actually be selected
            tabBarController.presentImagePicker(completion: nil)
            return false
        }
        if tabBarController.selectedViewController == viewController {
            // The tab is already selected, scroll to top if possible
            if let scrollView = self.findScrollViewToScrollToTop(in: viewController.view!) {
                scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.adjustedContentInset.top), animated: true)
                // Prevent the navigation controller from popping to root
                return false
            }
        }
        return true
    }
    
    private func findScrollViewToScrollToTop(in view: UIView) -> UIScrollView? {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                if scrollView.scrollsToTop && scrollView.contentOffset.y > -scrollView.adjustedContentInset.top {
                    return scrollView
                }
            }
            if let scrollView = findScrollViewToScrollToTop(in: subview) {
                return scrollView
            }
        }
        return nil
    }
}
