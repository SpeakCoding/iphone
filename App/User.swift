import Foundation


class User: ModelObject {
    
    var name: String
    var avatarURL: URL?
    var bio: String?
    
    init(userName: String) {
        name = userName
    }
    
    static var current: User? = nil
}
