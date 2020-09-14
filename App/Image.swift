import Foundation


class Image: Codable {
    
    var url: URL
    var tags = [Tag]()
    
    init(url: URL) {
        self.url = url
    }
    
    required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(url: URL(string: try values.decode(String.self, forKey: .url))!)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url.absoluteString, forKey: .url)
    }
    
    private enum CodingKeys: String, CodingKey {
        case url
    }
}
