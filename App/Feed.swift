import Foundation


class Feed {
    
    var posts: [Post]
    
    init() {
        self.posts = Cache.shared.fetchAllPosts()
    }
}
