import Foundation


class User: ModelObject {
    
    var name: String
    var avatar: Image?
    var bio: String?
    
    init(userName: String) {
        name = userName
    }
    
    static var current: User? = nil
}
