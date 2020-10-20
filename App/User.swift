import Foundation


class User: ModelObject {
    
    var userName: String
    var profilePictureURL: URL?
    var bio: String?
    var numberOfPosts = 0
    
    init(userName: String) {
        self.userName = userName
    }
    
    static var current: User?
    
    /**
     Initialize the current user from the cache on app launch
     */
    class func initCurrentUser() {
        if Cache.enabled {
            current = Cache.shared.fetchCurrentUser()
        } else {
            let currentUserID = UserDefaults.standard.integer(forKey: "Current user ID")
            if currentUserID != 0 {
                let currentUser = User(userName: "")
                currentUser.id = currentUserID
                current = currentUser
            }
        }
    }
    
    /**
     Set the current user and update the cache
     */
    class func setCurrentUser(_ user: User?) {
        current = user
        if Cache.enabled {
            if user != nil {
                Cache.shared.update(user: user!)
            }
        } else {
            UserDefaults.standard.set(user?.id, forKey: "Current user ID")
        }
    }
}
