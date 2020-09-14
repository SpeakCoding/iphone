import Foundation


class User: ModelObject, Codable {
    
    var name: String
    var avatar: Image?
    var profilePicture: Image?
    
    init(name: String) {
        self.name = name
    }
    
    static var current: User? = nil
    
    required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decode(String.self, forKey: .name)
        self.init(name: name)
        avatar = try values.decode(Image.self, forKey: .avatar)
        id = try values.decode(Int.self, forKey: .id)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(id, forKey: .id)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatar
    }
}
