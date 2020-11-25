import Foundation


class User: ModelObject {
    
    var userName: String
    var profilePictureURL: URL?
    var bio: String?
    var numberOfPosts = 0
    var numberOfFollowers = 0
    var numberOfFollowees = 0
    var isFollower = false
    var isFollowed = false
    
    init(userName: String) {
        self.userName = userName
    }
    
    func toggleFollowed() {
        if self.isFollowed {
            self.isFollowed = false
            self.numberOfFollowers -= 1
        } else {
            self.isFollowed = true
            self.numberOfFollowers += 1
        }
        Cache.shared.update(user: self)
    }
    
    static var current: User?
    
    /**
     Initialize the current user from the cache on app launch
     */
    class func initCurrentUser() {
        let currentUserID = UserDefaults.standard.integer(forKey: "current user ID")
        if currentUserID != 0 {
            current = Cache.shared.fetchUser(id: currentUserID)
            if current == nil {
                current = User(userName: "")
                current!.id = currentUserID
                ServerAPI.shared.getUser(id: currentUserID, completion: {_,_ in })
            }
        }
    }
    
    /**
     Set the current user and update the cache
     */
    class func setCurrentUser(_ user: User?) {
        current = user
        if user != nil {
            UserDefaults.standard.set(user!.id, forKey: "current user ID")
            Cache.shared.update(user: user!)
        }
    }
}
