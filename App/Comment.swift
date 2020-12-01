import Foundation


class Comment: ModelObject {
    
    var date: Date!
    var user: User!
    var text: String!
    
    required init(id: Int) {
        super.init(id: id)
    }
    
    convenience init(date: Date, user: User, text: String) {
        self.init(id: 0)
        self.date = date
        self.user = user
        self.text = text
    }
}
