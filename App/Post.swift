import Foundation


class Post: Codable {
    
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
        #warning("Not quite implemented")
//        id = try values.decode(Int.self, forKey: .id)
        let dateString = try values.decode(String.self, forKey: .date)
        let date = ISO8601DateFormatter().date(from: dateString)!
        let user = try values.decode(User.self, forKey: .user)
        let text = try values.decode(String.self, forKey: .text)
        let images = try values.decode([Image].self, forKey: .images)
        self.init(date: date, author: user, text: text, images: images, video: nil)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        #warning("Not quite implemented")
        try container.encode(ISO8601DateFormatter().string(from: date), forKey: .date)
        try container.encode(text, forKey: .text)
    }
    
    private enum CodingKeys: String, CodingKey {
        case date
        case user
        case text
        case images
        case video
    }
}
