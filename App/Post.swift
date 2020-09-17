import Foundation


class Post: ModelObject, Codable {
    
    var date: Date
    var user: User
    var text: String
    var images: [Image]?
    var video: Video?
    var comments = [Comment]()
    var likes = [Like]()
    
    init(date: Date, author: User, text: String, images: [Image]?, video: Video?) {
        self.date = date
        self.user = author
        self.text = text
        self.images = images
        self.video = video
    }
    
    required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let date = Date(timeIntervalSince1970: TimeInterval(try values.decode(Int.self, forKey: .date)))
        let user = try values.decode(User.self, forKey: .user)
        let text = try values.decode(String.self, forKey: .text)
        var images: [Image]?
        if let imageURL = URL(string: try values.decode(String.self, forKey: .image)) {
            images = [Image(url: imageURL)]
        }
        self.init(date: date, author: user, text: text, images: images, video: nil)
        id = try values.decode(Int.self, forKey: .id)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date.timeIntervalSince1970, forKey: .date)
        try container.encode(user, forKey: .user)
        try container.encode(text, forKey: .text)
        try container.encode(images?.first, forKey: .image)
        try container.encode(id, forKey: .id)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case date = "created_at"
        case user
        case text = "description"
        case image
//        case video
    }
}
