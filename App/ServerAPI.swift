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
    
    
    func signUp(emailAddress: String, password: String, completion: @escaping ((User?, Error?) -> Void)) {
        let requestParameters = ["user": ["email": emailAddress, "password": password]]
        let request = makeRequest(method: .POST, endpoint: "/users.json", authorized: false, parameters: requestParameters)
        performRequest(request: request) { (authResponse: APIResult<User>?, response: HTTPURLResponse?, error: Error?) in
            if let authResponse = authResponse {
                self.accessToken = authResponse.metadata?["authentication_token"]
                completion(authResponse.data, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func logIn(emailAddress: String, password: String, completion: @escaping ((User?, Error?) -> Void)) {
        let requestParameters = ["user": ["email": emailAddress, "password": password]]
        let request = makeRequest(method: .POST, endpoint: "/users/authenticate.json", authorized: false, parameters: requestParameters)
        performRequest(request: request) { (authResponse: APIResult<User>?, response: HTTPURLResponse?, error: Error?) in
            if let authResponse = authResponse {
                self.accessToken = authResponse.metadata?["authentication_token"]
                completion(authResponse.data, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Get a batch of `Post` objects in the feed after the last `Post` object we received earlier.
     This method is supposed to be called repeatedly as the user scrolls the feed
     until they reach the last `Post`.
     */
    func getFeedPosts(startPostIndex: UInt, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: .GET, endpoint: "/posts", authorized: false, parameters: nil)
        performRequest(request: request) { (posts: APIResult<[Post]>?, response: HTTPURLResponse?, error: Error?) in
            completion(posts?.data, error)
        }
    }
    
    func getPostsOf(user: User, completion: @escaping (([Post]?, Error?) -> Void)) {
        let request = makeRequest(method: .GET, endpoint: "/users/\(user.id)/posts", authorized: false, parameters: nil)
        performRequest(request: request) { (posts: APIResult<[Post]>?, response: HTTPURLResponse?, error: Error?) in
            completion(posts?.data, error)
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
    
    private let baseURLString: String
    private var session: URLSession
    private var accessToken: String? {
        didSet {
            UserDefaults.standard.set(accessToken, forKey: "access token")
        }
    }
    
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
        if ProcessInfo().arguments.contains("mock-api") {
            config.protocolClasses = [MockURLProtocol.self]
            baseURLString = "mock://api.example.com"
        } else {
            baseURLString = "http://130.193.56.58:3000"
        }
        
        let sessionDelegateQueue = OperationQueue()
        sessionDelegateQueue.name = "API.HTTP"
        sessionDelegateQueue.maxConcurrentOperationCount = 1
        
        session = URLSession(configuration: config, delegate: nil, delegateQueue: sessionDelegateQueue)
        
        accessToken = UserDefaults.standard.string(forKey: "access token")
    }
    
    /**
     Compose a URLRequest object
     */
    private func makeRequest(method: HTTPMethod, endpoint: String, authorized: Bool, parameters: [String: Any]?) -> URLRequest {
        guard let url = URL(string: baseURLString + endpoint) else {
            fatalError("Invalid endpoint: \(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let json = parameters {
            request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authorized && accessToken != nil {
            request.setValue(accessToken!, forHTTPHeaderField: "Authentication-Token")
        }
        return request
    }
    
    /**
     Perform a network request and process a server's response
     */
    private func performRequest<T: Decodable>(request: URLRequest, completion: @escaping ((APIResult<T>?, HTTPURLResponse?, Error?) -> Void)) {
        let task = session.dataTask(with: request) { (jsonData: Data?, urlResponse: URLResponse?, requestError: Error?) in
            var reportedError = requestError
            var result: APIResult<T>?
            if requestError == nil && jsonData != nil {
                do {
                    if let rawJSON = try? JSONSerialization.jsonObject(with: jsonData!, options: []) {
                        if let formattedJSONData = try? JSONSerialization.data(withJSONObject: rawJSON, options: [.prettyPrinted, .withoutEscapingSlashes]) {
                            if let formattedJSONString = String(data: formattedJSONData, encoding: .utf8) {
                                print("\(request.httpMethod!) \(request.url!) returned status code \((urlResponse as! HTTPURLResponse).statusCode) \(formattedJSONString)")
                            }
                        }
                    }
                    
                    let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: jsonData!)
                    if let nonErrorResult = apiResponse.result {
                        result = nonErrorResult
                    } else {
                        reportedError = apiResponse.error
                    }
                } catch {
                    print("Could not decode JSON: \(error)")
                    reportedError = error
                }
            }
            DispatchQueue.main.async {
                completion(result, urlResponse as? HTTPURLResponse, reportedError)
            }
        }
        task.resume()
    }
    
    /**
     These structures represent a server response.
     */
    struct APIResponse<T: Decodable>: Decodable {
        var data: T?
        var metadata: [String: String]?
        var error: Error?
        
        var result: APIResult<T>? {
            get {
                if let data = self.data {
                    return APIResult(data: data, metadata: metadata)
                }
                return nil
            }
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            if let data = try? values.decode(T.self, forKey: .data) {
                self.data = data
            } else {
                let errors = try? values.decode([APIError].self, forKey: .errors)
                self.error = NSError(domain: "API", code: 1, userInfo: [NSLocalizedDescriptionKey: errors?.first?.detail ?? "Unknown"])
            }
            self.metadata = try? values.decode([String: String].self, forKey: .metadata)
        }
        
        private enum CodingKeys: String, CodingKey {
            case data
            case metadata = "meta"
            case errors
        }
    }
    
    struct APIResult<T: Decodable>: Decodable {
        var data: T
        var metadata: [String: String]?
    }
    
    struct APIError: Decodable {
        var detail: String
        var source: [String: String]?
    }
}
