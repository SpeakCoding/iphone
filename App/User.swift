import UIKit
import Amplitude


class User: ModelObject {
    
    var userName: String!
    var profilePictureURL: URL?
    var bio: String?
    var numberOfPosts = 0
    var numberOfFollowers = 0
    var numberOfFollowees = 0
    var isFollower = false
    var isFollowed = false
    
    required init(id: Int) {
        super.init(id: id)
    }
    
    convenience init(userName: String) {
        self.init(id: 0)
        self.userName = userName
    }
    
    func toggleFollowed(completion: @escaping ((Error?) -> Void)) {
        let wasFollowed = self.isFollowed
        let formerNumberOfFollowers = self.numberOfFollowers
        if self.isFollowed {
            self.isFollowed = false
            self.numberOfFollowers -= 1
        } else {
            self.isFollowed = true
            self.numberOfFollowers += 1
        }
        Cache.shared.update(user: self)
        
        func processUserUpdateRequestResult(error: Error?) {
            if error != nil {
                self.isFollowed = wasFollowed
                self.numberOfFollowers = formerNumberOfFollowers
            }
            Cache.shared.update(user: self)
            completion(error)
        }
        ServerAPI.shared.updateUserFollowed(user: self, completion: processUserUpdateRequestResult)
    }
    
    func getPosts(completion: @escaping (([Post]?, Error?) -> Void)) {
        ServerAPI.shared.getPostsOf(user: self, completion: completion)
    }
    
    func getPostsWhereTagged(completion: @escaping (([Post]?, Error?) -> Void)) {
        ServerAPI.shared.getPostsWithTaggedUser(user: self, completion: completion)
    }
    
    func getFollowers(completion: @escaping (([User]?, Error?) -> Void)) {
        ServerAPI.shared.getFollowers(user: self, completion: completion)
    }
    
    func getFollowees(completion: @escaping (([User]?, Error?) -> Void)) {
        ServerAPI.shared.getFollowees(user: self, completion: completion)
    }
    
    func getLikes(completion: @escaping (([Like]?, Error?) -> Void)) {
        ServerAPI.shared.getLikes(user: self, completion: completion)
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
                current = User.instance(withID: currentUserID)
                current!.userName = ""
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
            Amplitude.instance().setUserId(String(user!.id))
        } else {
            UserDefaults.standard.removeObject(forKey: "current user ID")
            Amplitude.instance().setUserId(nil)
        }
    }
}
