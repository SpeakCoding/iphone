import Foundation


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
    
    
    /**
     Get a batch of `Post` objects in the feed after the last `Post` object we received earlier.
     This method is supposed to be called repeatedly as the user scrolls the feed
     until they reach the last `Post`.
     */
    func getFeedPosts(startPostIndex: UInt, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: .GET, endpoint: "/posts", authorized: false, parameters: nil)
        performRequest(request: request) { (posts: [Post]?, response: HTTPURLResponse?, error: Error?) in
            completion(posts, error)
        }
    }
    
    func getPostsOf(user: User, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: .GET, endpoint: "/users/\(user.id)/posts", authorized: false, parameters: nil)
        performRequest(request: request) { (posts: [Post]?, response: HTTPURLResponse?, error: Error?) in
            completion(posts, error)
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
    
    #warning("Real API URL is not known yet")
    private let baseURLString = "mock://api.example.com"
    private var session: URLSession
    
    private init() {
        // It is always a good idea to provide a meaningful 'User-Agent' HTTP header value
        let appInfoDictionary = Bundle.main.infoDictionary!
        let appName = appInfoDictionary[kCFBundleNameKey as String]!
        let appVersion = appInfoDictionary["CFBundleShortVersionString"]!
        let userAgentString = "\(appName)/\(appVersion) iOS/\(ProcessInfo().operatingSystemVersionString)"
        
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.networkServiceType = .default
        config.allowsCellularAccess = true
        config.connectionProxyDictionary = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as [NSObject : AnyObject]?
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.httpShouldUsePipelining = true
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.httpAdditionalHeaders = ["User-Agent": userAgentString, "Accept": "application/json"]
        config.httpMaximumConnectionsPerHost = 1
        config.httpCookieStorage = nil
        config.urlCache = nil
        #warning("Remove the mock")
        config.protocolClasses = [MockURLProtocol.self]
        
        let sessionDelegateQueue = OperationQueue()
        sessionDelegateQueue.name = "API.HTTP"
        sessionDelegateQueue.maxConcurrentOperationCount = 1
        
        session = URLSession(configuration: config, delegate: nil, delegateQueue: sessionDelegateQueue)
    }
    
    /**
     Compose a URLRequest object
     */
    private func makeRequest(method: HTTPMethod, endpoint: String, authorized: Bool, parameters: [String: AnyObject]?) -> URLRequest {
        guard let url = URL(string: baseURLString + endpoint) else {
            fatalError("Invalid endpoint: \(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let json = parameters {
            request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authorized {
            #warning("Authorized requests are not implemented")
//            request.setValue("BEARER \(accessToken!)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    /**
     Perform a network request and process a server's response
     */
    private func performRequest<T: Decodable>(request: URLRequest, completion: @escaping ((T?, HTTPURLResponse?, Error?) -> Void)) {
        let task = session.dataTask(with: request) { (jsonData: Data?, response: URLResponse?, requestError: Error?) in
            var reportedError = requestError
            var json: T?
            if requestError == nil && jsonData != nil {
                do {
                    try json = JSONDecoder().decode(T.self, from: jsonData!)
                } catch {
                    print("Could not decode JSON: \(error)")
                    reportedError = error
                }
            }
            DispatchQueue.main.async {
                completion(json, response as? HTTPURLResponse, reportedError)
            }
        }
        task.resume()
    }
}
