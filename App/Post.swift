import Foundation


class Post: ModelObject {
    
    var date: Date
    var user: User
    var caption: String
    var images: [Image]?
    var video: Video?
    var comments = [Comment]()
    var likes = [Like]()
    
    init(creationDate: Date, author: User, text: String, images: [Image]?, video: Video?) {
        date = creationDate
        user = author
        caption = text
        self.images = images
        self.video = video
    }
}
