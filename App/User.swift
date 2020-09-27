import Foundation


class User: ModelObject {
    
    var name: String
    var avatarURL: URL?
    var bio: String?
    
    init(userName: String) {
        self.name = userName
    }
    
    static var current: User? = nil {
        didSet {
            #warning("Refactor with 'current' column in DB")
            UserDefaults.standard.set(current?.id, forKey: "Current user ID")
        }
    }
}
