import UIKit
import MobileCoreServices


enum TabBarItemTag: Int {
    case home
    case newPost
    case likedPosts
    case profile
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var window: UIWindow?

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
        let tabBarViewController = UITabBarController(nibName: nil, bundle: nil)
        tabBarViewController.viewControllers = [homeTabViewController, newPostTabViewController, likedPostsTabViewController, profileTabViewController]
        tabBarViewController.delegate = self
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = tabBarViewController
        self.window!.makeKeyAndVisible()
        
        replaceLoginViewControllers()
        return true
    }
    
    private func initCacheDatabase() {
        #warning("Remove test code")
        /*
        let path = "/users/123/posts/9"
        // Parse routes in format "/users/:user_id/posts/:post_id"
        // and construct a regular expression like "/users/([0-9]+)/posts/([0-9]+)",
        // storing identifier placeholders in an array like ["user_id", "post_id"].
        var pattern = "/users/:user_id/posts/:post_id"
        guard pattern.starts(with: "/") else {
            fatalError("The pattern must start with '/'")
        }
        pattern.replaceSubrange(pattern.range(of: "/")!, with: "")
        
        var regexPattern = ""
        var placeholders = [String]()
        for component in pattern.components(separatedBy: "/") {
            print("Component = \"\(component)\"")
            regexPattern.append("/")
            if component.starts(with: ":") {
                regexPattern.append("([0-9]+)")
                let placeholder = String(component[component.index(component.startIndex, offsetBy: 1)...])
                placeholders.append(placeholder)
            } else {
                regexPattern.append(contentsOf: component)
            }
        }
        print("Regex = \(regexPattern), placeholders = \(placeholders)")
        
        let regex = try! NSRegularExpression(pattern: regexPattern)
        let result = regex.firstMatch(in: path, options: [], range: NSRange(location: 0, length: path.count))
        // The range at index 0 corresponds to the whole regex, the rest are capture groups
        if result!.numberOfRanges > 1 {
            var identifierTable = [String: Int]()
            for rangeIndex in 1..<result!.numberOfRanges {
                identifierTable[placeholders[rangeIndex - 1]] = Int((path as NSString).substring(with: result!.range(at: rangeIndex)))
            }
            print("Matched: \(identifierTable)")
        }
        */
        
//        print("\(NSHomeDirectory())")
//        let cachesURL = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!
//        let dbPath = cachesURL.appendingPathComponent("AppCache.sqlite").path
//        try? FileManager().removeItem(atPath: dbPath)
//        let db = SQLiteDatabase(filePath: dbPath)
//        if db.open() {
//            let query1 = """
//            CREATE TABLE users (
//            "id" INTEGER PRIMARY KEY NOT NULL,
//            "name" TEXT,
//            "height" REAL
//            )
//            """
//            db.executeUpdate(sqlQuery: query1, values: nil)
//            db.executeUpdate(sqlQuery: "INSERT INTO users (id,name,height) VALUES (?,?,?)", values: [123, "John Doe", 175.5])
//            db.executeUpdate(sqlQuery: "INSERT INTO users (id,name,height) VALUES (?,?,?)", values: [456, "Jon Snow", 180.5])
//            db.executeUpdate(sqlQuery: "INSERT INTO users (id,name,height) VALUES (?,?,?)", values: [789, "Ann Glow", 178.1])
//            let allUsers = db.executeQuery(sqlQuery: "SELECT * FROM users", parameters: nil)
//            print("All users: \(allUsers)")
//            let jon = db.executeQuery(sqlQuery: "SELECT id,name FROM users WHERE id=?", parameters: [456])
//            print("Jon only: \(jon)")
//            db.close()
//        }
//        try? FileManager().removeItem(atPath: dbPath)
//        let _ = Post(date: Date(), author: User(name: "Jon"), text: "Hello world!", images: nil, video: nil)
    }
    
    private func replaceLoginViewControllers() {
        let tabBarController = self.window!.rootViewController! as! UITabBarController
        for navigationController in tabBarController.viewControllers! where navigationController is UINavigationController {
            let navigationController = navigationController as! UINavigationController
            if let rootViewController = navigationController.viewControllers.first {
                if rootViewController is LoginViewController {
                    switch navigationController.tabBarItem.tag {
                    case TabBarItemTag.likedPosts.rawValue:
                        navigationController.setViewControllers([LikedPostsViewController()], animated: false)
                    case TabBarItemTag.profile.rawValue:
                        navigationController.setViewControllers([UserProfileViewController(user: User.current!)], animated: false)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func showImagePickerSourceSelection() {
        let cameraIsAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let libraryIsAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        if cameraIsAvailable || libraryIsAvailable {
            // Show the image picker/camera immediately if only one of them is available
            if cameraIsAvailable && !libraryIsAvailable {
                showImagePicker(source: .camera)
                return
            }
            if libraryIsAvailable && !cameraIsAvailable {
                showImagePicker(source: .photoLibrary)
                return
            }
            
            // Ask the user what to show, the image picker or the camera
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { (UIAlertAction) in
                self.showImagePicker(source: .camera)
            }))
            alert.addAction(UIAlertAction(title: "Upload from library", style: .default, handler: { (UIAlertAction) in
                self.showImagePicker(source: .photoLibrary)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            let tabBarController = self.window!.rootViewController!
            tabBarController.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: nil, message: "Sorry neither the camera nor the photo library is available.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            let tabBarController = self.window!.rootViewController!
            tabBarController.present(alert, animated: true, completion: nil)
        }
    }
    
    private func showImagePicker(source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = source
        imagePicker.mediaTypes = [kUTTypeImage as String]
        if source == .camera {
            imagePicker.cameraCaptureMode = .photo
        }
        imagePicker.modalPresentationStyle = .fullScreen
        imagePicker.delegate = self
        let tabBarController = self.window!.rootViewController!
        tabBarController.present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let vc = PhotoPickerPreviewController(image: image) { (newPost: Post) in
            print("New post: \(newPost)")
            picker.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        picker.pushViewController(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
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
                self.showImagePickerSourceSelection()
            } else {
                let loginViewController = LoginViewController(completion: {
                    if User.current != nil {
                        self.replaceLoginViewControllers()
                        tabBarController.dismiss(animated: true) {
                            self.showImagePickerSourceSelection()
                        }
                    }
                })
                tabBarController.present(loginViewController, animated: true, completion: nil)
            }
            return false
            
        case .likedPosts:
            // The user has to log in to see their liked posts
            let navigationController = viewController as! UINavigationController
            if let rootViewController = navigationController.viewControllers.first {
                if User.current != nil && rootViewController is LoginViewController {
                    navigationController.setViewControllers([LikedPostsViewController()], animated: false)
                }
            } else {
                if User.current != nil {
                    navigationController.pushViewController(LikedPostsViewController(), animated: false)
                } else {
                    navigationController.pushViewController(LoginViewController(completion: {
                        if User.current != nil {
                            navigationController.setViewControllers([LikedPostsViewController()], animated: true)
                        }
                    }), animated: false)
                }
            }
            return true
            
        case .profile:
            // The user has to log in to see their profile
            let navigationController = viewController as! UINavigationController
            if let rootViewController = navigationController.viewControllers.first {
                if let currentUser = User.current, rootViewController is LoginViewController {
                    navigationController.setViewControllers([UserProfileViewController(user: currentUser)], animated: false)
                }
            } else {
                if let currentUser = User.current {
                    navigationController.pushViewController(UserProfileViewController(user: currentUser), animated: false)
                } else {
                    navigationController.pushViewController(LoginViewController(completion: {
                        if let currentUser = User.current {
                            navigationController.setViewControllers([UserProfileViewController(user: currentUser)], animated: true)
                        }
                    }), animated: false)
                }
            }
            return true
        }
    }
}
