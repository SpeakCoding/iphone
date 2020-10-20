import Foundation


class User: ModelObject {
    
    var userName: String
    var profilePictureURL: URL?
    var bio: String?
    var numberOfPosts = 0
    
    init(userName: String) {
        self.userName = userName
    }
    
    static var current: User? = {
        // Fetch the current user once, the first time User.current is accessed
        if Cache.enabled {
            return Cache.shared.fetchCurrentUser()
        } else {
            let currentUserID = UserDefaults.standard.integer(forKey: "Current user ID")
            if currentUserID != 0 {
                let currentUser = User(userName: "")
                currentUser.id = currentUserID
                return currentUser
            }
            return nil
        }
    }() {
        didSet {
            // Save the current user whenever it changes
            if Cache.enabled {
                if current != nil {
                    Cache.shared.update(user: current!)
                }
            } else {
                UserDefaults.standard.set(current?.id, forKey: "Current user ID")
            }
        }
    }
}
