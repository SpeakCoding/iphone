import Foundation


class Image {
    
    var url: URL
    var tags = [Tag]()
    
    init(url: URL) {
        self.url = url
    }
}
