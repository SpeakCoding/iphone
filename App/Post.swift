import Foundation


class Post: ModelObject {
    
    var time: Date
    var user: User
    var caption: String
    var images: [Image]?
    var video: Video?
    var location: String?
    var likes = [Like]()
    var comments = [Comment]()
    var likeCount = 0
    var isLiked = false
    
    init(creationDate: Date, author: User, postCaption: String, postImages: [Image]?, postVideo: Video?, postLocation: String?) {
        self.time = creationDate
        self.user = author
        self.caption = postCaption
        self.images = postImages
        self.video = postVideo
        self.location = postLocation
    }
}
