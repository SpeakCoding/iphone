import Foundation


class Like {
    
    var date: Date
    var user: User
    var post: Post

    init(date: Date, user: User, post: Post) {
        self.date = date
        self.user = user
        self.post = post
    }
}
