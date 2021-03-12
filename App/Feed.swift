import Foundation


class Feed {
    
    var posts: [Post]
    
    init() {
        self.posts = Cache.shared.fetchFeedPosts()
    }
    
    func getPosts(completion: @escaping ((Error?) -> Void)) {
        func processFeedRequestResult(posts: [Post]?, error: Error?) {
            if posts != nil {
                self.posts = posts!
                Cache.shared.update(feed: self)
            }
            completion(error)
        }
        ServerAPI.shared.getFeedPosts(feed: self, completion: processFeedRequestResult)
    }
}
