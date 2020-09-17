import Foundation


class User: ModelObject {
    
    var name: String
    var avatar: Image?
    var profilePicture: Image?
    
    init(name: String) {
        self.name = name
    }
    
    static var current: User? = nil
}
