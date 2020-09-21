import Foundation


class User: ModelObject {
    
    var name: String
    var emailAddress: String
    var avatar: Image?
    var bio: String?
    
    init(name: String, emailAddress: String) {
        self.name = name
        self.emailAddress = emailAddress
    }
    
    static var current: User? = nil
}
