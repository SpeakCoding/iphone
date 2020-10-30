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
        current = Cache.shared.fetchCurrentUser()
    }
    
    /**
     Set the current user and update the cache
     */
    class func setCurrentUser(_ user: User?) {
        current = user
        if user != nil {
            Cache.shared.update(user: user!)
        }
    }
}
