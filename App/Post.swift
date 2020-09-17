import Foundation


class Post: ModelObject {
    
    var date: Date
    var user: User
    var text: String
    var images: [Image]?
    var video: Video?
    var comments = [Comment]()
    var likes = [Like]()
    
    init(date: Date, author: User, text: String, images: [Image]?, video: Video?) {
        self.date = date
        self.user = author
        self.text = text
        self.images = images
        self.video = video
    }
}
