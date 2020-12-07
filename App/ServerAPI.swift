import UIKit


/**
 This class represents our server.
 It performs network requests on your behalf, **encapsulating** all the technical details
 like serializing/deserializing objects for transfer over the internet
 and using the **API endpoints** implemented on the server for particular tasks.
 Whenever you want to get data from the server (e.g. the feed of posts)
 or to send data to the server (e.g. create a new post for other users to see),
 you communicate with a **shared** instance of this class.
 There is only one instance of `ServerAPI` in the app because we don't need any more.
 Such a programming pattern is called a **singleton**.
 Since all network communication is **asynchronous**
 (a network request involves sending some data to a remote computer, waiting for a response
 and then either receiving a response or timing out if the server doesn't respond in time),
 all the request methods require an additional argument, a **closure** which will be called
 when a response from the server is received and processed.
 */
class ServerAPI {
    
    static let shared = ServerAPI()
    
    func signUp(emailAddress: String, password: String, completion: @escaping ((User?, Error?) -> Void)) {
        let requestParameters = ["user": ["email": emailAddress, "password": password]]
        let request = makeRequest(method: HTTPMethod.POST, endpoint: "/users.json", authorized: false, parameters: requestParameters)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSON = result as? [String: Any] {
                self.accessToken = metadata?["authentication_token"]
                UserDefaults.standard.set(self.accessToken, forKey: "access token")
                
                let currentUser = User.instance(withJSON: userJSON)
                User.setCurrentUser(currentUser)
                completion(currentUser, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func logIn(emailAddress: String, password: String, completion: @escaping ((User?, Error?) -> Void)) {
        let requestParameters = ["user": ["email": emailAddress, "password": password]]
        let request = makeRequest(method: HTTPMethod.POST, endpoint: "/users/authenticate.json", authorized: false, parameters: requestParameters)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSON = result as? [String: Any] {
                self.accessToken = metadata?["authentication_token"]
                UserDefaults.standard.set(self.accessToken, forKey: "access token")
                
                let currentUser = User.instance(withJSON: userJSON)
                User.setCurrentUser(currentUser)
                completion(currentUser, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updateProfile(name: String?, bio: String?, profilePicture: UIImage?, completion: @escaping ((User?, Error?) -> Void)) {
        var userInfo = [String: String]()
        if name != nil {
            userInfo["full_name"] = name!
        }
        if bio != nil {
            userInfo["bio"] = bio!
        }
        if profilePicture != nil {
            if let imageBase64String = profilePicture!.jpegData(compressionQuality: 0.7)?.base64EncodedString() {
                let imageDataURI = "data:image/jpeg;base64,".appending(imageBase64String)
                userInfo["portrait"] = imageDataURI
            }
        }
        let requestParameters = ["user": userInfo]
        let request = makeRequest(method: HTTPMethod.PUT, endpoint: "/users/\(User.current!.id).json", authorized: true, parameters: requestParameters)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSON = result as? [String: Any] {
                let updatedUser = User.instance(withJSON: userJSON)
                User.setCurrentUser(updatedUser)
                completion(updatedUser, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getUser(id: Int, completion: @escaping ((User?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/users/\(id).json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSON = result as? [String: Any] {
                let user = User.instance(withJSON: userJSON)
                Cache.shared.update(user: user)
                completion(user, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updateUserFollowed(user: User, completion: @escaping ((User?, Error?) -> Void)) {
        let endpoint: String
        if user.isFollowed {
            endpoint = "/users/\(user.id)/follow.json"
        } else {
            endpoint = "/users/\(user.id)/unfollow.json"
        }
        let request = makeRequest(method: HTTPMethod.POST, endpoint: endpoint, authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSON = result as? [String: Any] {
                let user = User.instance(withJSON: userJSON)
                Cache.shared.update(user: user)
                completion(user, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getFollowers(user: User, completion: @escaping (([User]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/users/\(user.id)/followers.json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSONs = result as? [[String: Any]] {
                let users = userJSONs.map { (userJSON) -> User in
                    let user = User.instance(withJSON: userJSON)
                    Cache.shared.update(user: user)
                    return user
                }
                completion(users, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getFollowees(user: User, completion: @escaping (([User]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/users/\(user.id)/followees.json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSONs = result as? [[String: Any]] {
                let users = userJSONs.map { (userJSON) -> User in
                    let user = User.instance(withJSON: userJSON)
                    Cache.shared.update(user: user)
                    return user
                }
                completion(users, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func findUsers(searchText: String, completion: @escaping (([User]?, Error?) -> Void)) -> URLSessionDataTask {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/users/search.json?query=\(searchText)", authorized: true, parameters: nil)
        return performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSONs = result as? [[String: Any]] {
                let users = userJSONs.map { (userJSON) -> User in
                    let user = User.instance(withJSON: userJSON)
                    Cache.shared.update(user: user)
                    return user
                }
                completion(users, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getFeedPosts(feed: Feed, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/posts", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSONs = result as? [[String: Any]] {
                let posts = postJSONs.map { (postJSON) -> Post in
                    Post.instance(withJSON: postJSON)
                }
                feed.posts = posts
                Cache.shared.update(feed: feed)
                completion(posts, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getSavedPosts(completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/posts/saved.json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSONs = result as? [[String: Any]] {
                let posts = postJSONs.map { (postJSON) -> Post in
                    let post = Post.instance(withJSON: postJSON)
                    Cache.shared.update(post: post)
                    return post
                }
                completion(posts, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getPostsOf(user: User, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/users/\(user.id)/posts.json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSONs = result as? [[String: Any]] {
                let posts = postJSONs.map { (postJSON) -> Post in
                    let post = Post.instance(withJSON: postJSON)
                    Cache.shared.update(post: post)
                    return post
                }
                completion(posts, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getPostsWithTaggedUser(user: User, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/posts/tagged.json?user_id=\(user.id)", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSONs = result as? [[String: Any]] {
                let posts = postJSONs.map { (postJSON) -> Post in
                    let post = Post.instance(withJSON: postJSON)
                    Cache.shared.update(post: post)
                    return post
                }
                completion(posts, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getUsersWhoLiked(post: Post, completion: @escaping (([User]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/posts/\(post.id)/likers.json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let userJSONs = result as? [[String: Any]] {
                let users = userJSONs.map { (userJSON) -> User in
                    let user = User.instance(withJSON: userJSON)
                    Cache.shared.update(user: user)
                    return user
                }
                completion(users, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func createPost(_ post: Post, image: UIImage, completion: @escaping ((Post?, Error?) -> Void)) {
        guard let imageBase64String = image.jpegData(compressionQuality: 0.7)?.base64EncodedString() else {
            completion(nil, NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]))
            return
        }
        let requestParameters = ["post": [
            "location": post.location as Any,
            "caption": post.caption!,
            "image": "data:image/jpeg;base64,".appending(imageBase64String),
            "tags": post.tags.map { (tag) -> [String: Any] in
                return [
                    "user_id": tag.user.id,
                    "left": tag.point.x,
                    "top": tag.point.y
                ]
            }
            ]]
        let request = makeRequest(method: HTTPMethod.POST, endpoint: "/posts.json", authorized: true, parameters: requestParameters)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSON = result as? [String: Any] {
                let post = Post.instance(withJSON: postJSON)
                Cache.shared.update(post: post)
                completion(post, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updatePost(_ post: Post, image: UIImage, completion: @escaping ((Post?, Error?) -> Void)) {
        let requestParameters = ["post": [
            "caption": post.caption!,
            "tags": post.tags.map { (tag) -> [String: Any] in
                return [
                    "user_id": tag.user.id,
                    "left": tag.point.x,
                    "top": tag.point.y
                ]
            }
            ]]
        let request = makeRequest(method: HTTPMethod.PUT, endpoint: "/posts/\(post.id).json", authorized: true, parameters: requestParameters)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSON = result as? [String: Any] {
                let post = Post.instance(withJSON: postJSON)
                Cache.shared.update(post: post)
                completion(post, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func deletePost(_ post: Post, completion: @escaping ((Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.DELETE, endpoint: "/posts/\(post.id).json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if error == nil {
                Cache.shared.delete(post: post)
                if let currentUser = User.current {
                    currentUser.numberOfPosts -= 1
                    Cache.shared.update(user: currentUser)
                }
            }
            completion(error)
        }
    }
    
    func updatePostLike(_ post: Post, completion: @escaping ((Post?, Error?) -> Void)) {
        let endpoint: String
        if post.isLiked {
            endpoint = "/posts/\(post.id)/like.json"
        } else {
            endpoint = "/posts/\(post.id)/unlike.json"
        }
        let request = makeRequest(method: HTTPMethod.POST, endpoint: endpoint, authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSON = result as? [String: Any] {
                let post = Post.instance(withJSON: postJSON)
                Cache.shared.update(post: post)
                completion(post, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updatePostSaved(_ post: Post, completion: @escaping ((Post?, Error?) -> Void)) {
        let endpoint: String
        if post.isSaved {
            endpoint = "/posts/\(post.id)/save.json"
        } else {
            endpoint = "/posts/\(post.id)/unsave.json"
        }
        let request = makeRequest(method: HTTPMethod.POST, endpoint: endpoint, authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let postJSON = result as? [String: Any] {
                let post = Post.instance(withJSON: postJSON)
                Cache.shared.update(post: post)
                completion(post, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func createComment(_ comment: Comment, to post: Post, completion: @escaping ((Comment?, Error?) -> Void)) {
        let requestParameters = ["comment": ["post_id": post.id, "body": comment.text!]]
        let request = makeRequest(method: HTTPMethod.POST, endpoint: "/comments.json", authorized: true, parameters: requestParameters)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let commentJSON = result as? [String: Any] {
                let comment = Comment.instance(withJSON: commentJSON)
                Cache.shared.update(comment: comment, post: post)
                post.comments.append(comment)
                completion(comment, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func getLikes(user: User, completion: @escaping (([Like]?, Error?) -> Void)) {
        let request = makeRequest(method: HTTPMethod.GET, endpoint: "/users/\(user.id)/whats_new.json", authorized: true, parameters: nil)
        performRequest(request: request) { (result: Any?, metadata: [String : String]?, error: Error?) in
            if let likeJSONs = result as? [[String: Any]] {
                let likes = likeJSONs.map { (likeJSON) -> Like in
                    return Like(json: likeJSON)
                }
                completion(likes, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Private stuff
    
    /**
     HTTP methods, as defined in https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
     We only use some of them, the rest are provided for completeness' sake.
     */
    enum HTTPMethod: String {
        case OPTIONS
        case GET
        case HEAD
        case POST
        case PUT
        case DELETE
        case TRACE
        case CONNECT
        case PATCH
    }
    
    private let baseURLString = "http://130.193.44.149:3000"
    private var session: URLSession
    private var accessToken: String?
    
    private init() {
        self.session = ServerAPI.createURLSession()
        self.accessToken = UserDefaults.standard.string(forKey: "access token")
    }
    
    private class func createURLSession() -> URLSession {
        // It is always a good idea to provide a meaningful 'User-Agent' HTTP header value
        let appInfoDictionary = Bundle.main.infoDictionary!
        let appName = appInfoDictionary[kCFBundleNameKey as String]!
        let appVersion = appInfoDictionary["CFBundleShortVersionString"]!
        let userAgentString = "\(appName)/\(appVersion) iOS/\(ProcessInfo().operatingSystemVersionString)"
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.networkServiceType = URLRequest.NetworkServiceType.default
        configuration.allowsCellularAccess = true
        configuration.connectionProxyDictionary = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as [NSObject : AnyObject]?
        configuration.tlsMinimumSupportedProtocolVersion = tls_protocol_version_t.TLSv12
        configuration.httpShouldUsePipelining = true
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
        configuration.httpAdditionalHeaders = ["User-Agent": userAgentString, "Accept": "application/json"]
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        
        let sessionDelegateQueue = OperationQueue()
        sessionDelegateQueue.name = "API.HTTP"
        sessionDelegateQueue.maxConcurrentOperationCount = 1
        
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: sessionDelegateQueue)
    }
    
    /**
     Compose a URLRequest object
     */
    private func makeRequest(method: HTTPMethod, endpoint: String, authorized: Bool, parameters: [String: Any]?) -> URLRequest {
        guard let url = URL(string: self.baseURLString + endpoint) else {
            fatalError("Invalid endpoint: \(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let json = parameters {
            request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authorized && self.accessToken != nil {
            request.setValue(self.accessToken!, forHTTPHeaderField: "Authentication-Token")
        }
        return request
    }
    
    /**
     Perform a network request and process a server's response
     */
    @discardableResult private func performRequest(request: URLRequest, completion: @escaping ((_ data: Any?, _ metadata: [String: String]?, _ error: Error?) -> Void)) -> URLSessionDataTask {
        let task = self.session.dataTask(with: request) { (jsonData: Data?, urlResponse: URLResponse?, requestError: Error?) in
            var result: Any?
            var metadata: [String: String]?
            var reportedError = requestError
            if requestError == nil && jsonData != nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: jsonData!, options: [])
                    if let responseJSON = (json as? [String: Any]) {
                        result = responseJSON["data"]
                        metadata = responseJSON["meta"] as? [String: String]
                        if result == nil {
                            if let firstErrorInfo = (responseJSON["errors"] as? [[String: Any]])?.first {
                                reportedError = NSError(domain: "API", code: 1, userInfo: [NSLocalizedDescriptionKey: firstErrorInfo["detail"] as? String ?? "Unknown"])
                                print("⚠️ Request \(request.httpMethod!) \(request.url!.path) failed: \(firstErrorInfo)")
                            } else {
                                if let errorMessage = responseJSON["error"] as? String {
                                    reportedError = NSError(domain: "API", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                                    print("⚠️ Request \(request.httpMethod!) \(request.url!.path) failed: \(errorMessage)")
                                }
                            }
                        }
                    }
                } catch {
                    print("Could not decode JSON: \(error)")
                    reportedError = error
                }
            }
            DispatchQueue.main.async {
                completion(result, metadata, reportedError)
            }
        }
        task.resume()
        return task
    }
}


// MARK: - Model Object JSON Decoders


extension User {
    class func instance(withJSON json: [String: Any]) -> User {
        let user: User = self.instance(withID: json["id"] as! Int)
        user.userName = (json["full_name"] as! String)
        if let pictureURI = json["portrait"] as? String {
            user.profilePictureURL = URL(string: pictureURI)
        } else {
            user.profilePictureURL = nil
        }
        user.bio = json["bio"] as? String
        user.numberOfPosts = json["posts_count"] as! Int
        user.numberOfFollowers = json["followers_count"] as! Int
        user.numberOfFollowees = json["followees_count"] as! Int
        if let isFollower = json["is_follower"] as? Bool {
            user.isFollower = isFollower
        }
        if let isFollowed = json["is_followee"] as? Bool {
            user.isFollowed = isFollowed
        }
        return user
    }
}


extension Post {
    class func instance(withJSON json: [String: Any]) -> Post {
        let post: Post = self.instance(withID: json["id"] as! Int)
        post.date = Date(timeIntervalSince1970: TimeInterval(json["created_at"] as! Int))
        post.user = User.instance(withJSON: json["user"] as! [String : Any])
        post.caption = (json["caption"] as! String)
        if let imageURL = URL(string: json["image"] as! String) {
            post.images = [Image(url: imageURL)]
        } else {
            post.images = nil
        }
        post.location = json["location"] as? String
        if let tags = json["tags"] as? [[String: Any]] {
            post.tags = tags.map { Tag(json: $0) }
        } else {
            post.tags = []
        }
        if let comments = json["comments"] as? [[String: Any]] {
            post.comments = comments.map { Comment.instance(withJSON: $0) }
        } else {
            post.comments = []
        }
        if let likerFolloweeJSON = json["liker_followee"] as? [String : Any] {
            post.likerFollowee = User.instance(withJSON: likerFolloweeJSON)
        } else {
            post.likerFollowee = nil
        }
        post.numberOfLikes = json["likes_count"] as! Int
        post.isLiked = json["liked"] as! Bool
        post.isSaved = json["saved"] as! Bool
        return post
    }
}


extension Comment {
    class func instance(withJSON json: [String: Any]) -> Comment {
        let comment: Comment = self.instance(withID: json["id"] as! Int)
        comment.date = Date(timeIntervalSince1970: TimeInterval(json["created_at"] as! Int))
        comment.user = User.instance(withJSON: json["user"] as! [String : Any])
        comment.text = (json["body"] as! String)
        return comment
    }
}


extension Image {
    convenience init(json: [String: Any]) {
        let imageURI = json["url"] as! String
        self.init(url: URL(string: imageURI)!)
    }
}


extension Tag {
    convenience init(json: [String: Any]) {
        let user = User.instance(withJSON: json["user"] as! [String : Any])
        let point = Point(x: json["left"] as! Double, y: json["top"] as! Double)
        self.init(taggedUser: user, point: point)
    }
}


extension Like {
    convenience init(json: [String: Any]) {
        let date = Date(timeIntervalSince1970: TimeInterval(json["created_at"] as! Int))
        let user = User.instance(withJSON: json["user"] as! [String : Any])
        let post = Post.instance(withJSON: json["post"] as! [String : Any])
        self.init(date: date, user: user, post: post)
    }
}
