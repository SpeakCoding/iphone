import Foundation


class Post: ModelObject {
    
    var date: Date
    var user: User
    var caption: String
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
    
    init(creationDate: Date, author: User, postCaption: String, postImages: [Image]?, postVideo: Video?, postLocation: String?) {
        self.date = creationDate
        self.user = author
        self.caption = postCaption
        self.images = postImages
        self.video = postVideo
        self.location = postLocation
    }
    
    func toggleLike() {
        if self.isLiked {
            self.isLiked = false
            self.numberOfLikes -= 1
        } else {
            self.isLiked = true
            self.numberOfLikes += 1
        }
        Cache.shared.update(post: self)
    }
    
    func toggleSaved() {
        self.isSaved = !self.isSaved
        Cache.shared.update(post: self)
    }
}
