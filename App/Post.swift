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
    var numberOfComments = 0
    var isLiked = false
    
    init(creationDate: Date, author: User, postCaption: String, postImages: [Image]?, postVideo: Video?, postLocation: String?) {
        self.date = creationDate
        self.user = author
        self.caption = postCaption
        self.images = postImages
        self.video = postVideo
        self.location = postLocation
    }
}
