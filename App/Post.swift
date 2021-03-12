import Foundation


class Post: ModelObject {
    
    var date: Date!
    var user: User!
    var caption: String!
    var images: [Image]?
    var video: Video?
    var location: String?
    var tags = [Tag]()
    var likes = [Like]()
    var comments = [Comment]()
    var numberOfLikes = 0
    var isLiked = false
    var isSaved = false
    var likerFollowee: User?
    
    required init(id: Int) {
        super.init(id: id)
    }
    
    convenience init(creationDate: Date, author: User, postCaption: String, postImages: [Image]?, postVideo: Video?, postLocation: String?) {
        self.init(id: 0)
        self.date = creationDate
        self.user = author
        self.caption = postCaption
        self.images = postImages
        self.video = postVideo
        self.location = postLocation
    }
    
    func toggleLike(completion: @escaping ((Error?) -> Void)) {
        let wasLiked = self.isLiked
        let formerNumberOfLikes = self.numberOfLikes
        if self.isLiked {
            self.isLiked = false
            self.numberOfLikes -= 1
        } else {
            self.isLiked = true
            self.numberOfLikes += 1
        }
        Cache.shared.update(post: self)
        
        func processUpdatePostRequestResult(error: Error?) {
            if error != nil {
                self.isLiked = wasLiked
                self.numberOfLikes = formerNumberOfLikes
            }
            Cache.shared.update(post: self)
            completion(error)
        }
        ServerAPI.shared.updatePostLike(self, completion: processUpdatePostRequestResult)
    }
    
    func toggleSaved(completion: @escaping ((Error?) -> Void)) {
        let wasSaved = self.isSaved
        self.isSaved = !self.isSaved
        Cache.shared.update(post: self)
        
        func processUpdatePostRequestResult(error: Error?) {
            if error != nil {
                self.isSaved = wasSaved
            }
            Cache.shared.update(post: self)
            completion(error)
        }
        ServerAPI.shared.updatePostSaved(self, completion: processUpdatePostRequestResult)
    }
    
    func update(newCaption: String, newTags: [Tag], completion: @escaping ((Error?) -> Void)) {
        func processPostUpdateRequestResult(error: Error?) {
            if (error == nil) {
                Cache.shared.update(post: self)
            }
            completion(error)
        }
        ServerAPI.shared.updatePost(self, newCaption: newCaption, newTags: newTags, completion: processPostUpdateRequestResult)
    }
    
    func delete(completion: @escaping ((Error?) -> Void)) {
        func processDeletePostRequestResult(error: Error?) {
            if error == nil {
                Cache.shared.delete(post: self)
                if let currentUser = User.current {
                    currentUser.numberOfPosts -= 1
                    Cache.shared.update(user: currentUser)
                }
            }
            completion(error)
        }
        ServerAPI.shared.deletePost(self, completion: processDeletePostRequestResult)
    }
    
    func getUsersWhoLiked(completion: @escaping (([User]?, Error?) -> Void)) {
        ServerAPI.shared.getUsersWhoLiked(post: self, completion: completion)
    }
}
