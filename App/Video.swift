import Foundation


class Video {
    
    var url: URL
    var tags = [Tag]()
    
    init(url: URL) {
        self.url = url
    }
}
