import Foundation


class Comment: ModelObject {
    
    var date: Date
    var user: User
    var text: String
    
    init(date: Date, user: User, text: String) {
        self.date = date
        self.user = user
        self.text = text
    }
}
