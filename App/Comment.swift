import Foundation


class Comment {
    
    var date: Date
    var user: User
    var text: String
    var replies = [Comment]()
    
    init(date: Date, user: User, text: String) {
        self.date = date
        self.user = user
        self.text = text
    }
}
