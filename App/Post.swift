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
    
    init(creationDate: Date, author: User, postCaption: String, postImages: [Image]?, postVideo: Video?, postLocation: String?) {
        time = creationDate
        user = author
        caption = postCaption
        images = postImages
        video = postVideo
        location = postLocation
    }
}
