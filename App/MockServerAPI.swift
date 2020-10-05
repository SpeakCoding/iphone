import Foundation


class MockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == "mock"
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        var data: Data
        var response: URLResponse
        
        let requestURL = self.request.url!
        if requestURL.pathExtension == "jpg" {
            let fileURL = Bundle.main.url(forResource: requestURL.lastPathComponent, withExtension: "", subdirectory: "TestData")!
            let fileData = try? Data(contentsOf: fileURL)
            if fileData != nil {
                data = fileData!
                response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
            } else {
                data = Data()
                response = HTTPURLResponse(url: requestURL, statusCode: 404, httpVersion: "1.1", headerFields: nil)!
            }
        } else {
            var json: Any
            switch requestURL.path {
            case "/users.json" where request.httpMethod == "POST", "/users/authenticate.json" where request.httpMethod == "POST":
                var bodyData = request.httpBody
                if bodyData == nil && request.httpBodyStream != nil {
                    bodyData = Data()
                    let bufferSize = 1024
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                    defer {
                        buffer.deallocate()
                    }
                    let stream = request.httpBodyStream!
                    stream.open()
                    defer {
                        stream.close()
                    }
                    while stream.hasBytesAvailable {
                        let bytesRead = stream.read(buffer, maxLength: bufferSize)
                        if bytesRead <= 0 {
                            break
                        }
                        bodyData!.append(buffer, count: bytesRead)
                    }
                }
                json = signUp(jsonData: bodyData!)
            case "/posts" where request.httpMethod == "GET":
                json = getPosts()
            default:
                if let objectIDs = matchRoute(pattern: "/users/:user_id.json", path: requestURL.path) {
                    json = getUser(userIdentifier: objectIDs["user_id"]!)
                    break
                }
                if let objectIDs = matchRoute(pattern: "/users/:user_id/posts.json", path: requestURL.path) {
                    json = getPostsOfUser(userIdentifier: objectIDs["user_id"]!)
                    break
                }
                
                json = []
            }
            data = try! JSONSerialization.data(withJSONObject: json, options: [])
            response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
    }
    
    override func stopLoading() {
    }
    
    // MARK: -
    
    private func matchRoute(pattern: String, path: String) -> [String: Int]? {
        // Parse routes in format "/users/:user_id/posts/:post_id"
        // and construct a regular expression like "/users/([0-9]+)/posts/([0-9]+)",
        // storing identifier placeholders in an array like ["user_id", "post_id"].
        guard pattern.starts(with: "/") else {
            fatalError("The pattern must start with '/'")
        }
        
        var regexPattern = "^"
        var placeholders = [String]()
        for component in pattern.components(separatedBy: "/") {
            if component == "" {
                // An empty component comes before the leading '/'
                continue
            }
            regexPattern.append("/")
            if component.starts(with: ":") {
                regexPattern.append("([0-9]+)")
                
                var placeholder = component
                placeholder.removeFirst(1)
                if component.hasSuffix(".json") {
                    placeholder.removeLast(5)
                    regexPattern.append("\\.json")
                }
                placeholders.append(placeholder)
            } else {
                regexPattern.append(contentsOf: component)
            }
        }
        regexPattern.append("$")
        
        let regex = try! NSRegularExpression(pattern: regexPattern)
        if let result = regex.firstMatch(in: path, options: [], range: NSRange(location: 0, length: path.count)) {
            // The range at index 0 corresponds to the whole regex, the rest are capture groups
            if result.numberOfRanges > 1 {
                var identifierTable = [String: Int]()
                for rangeIndex in 1..<result.numberOfRanges {
                    identifierTable[placeholders[rangeIndex - 1]] = Int((path as NSString).substring(with: result.range(at: rangeIndex)))
                }
                return identifierTable
            }
        }
        return nil
    }
    
    private func signUp(jsonData: Data) -> Any {
        if (try? JSONSerialization.jsonObject(with: jsonData, options: [])) as? [String: [String: String]] != nil {
            let userID = 123
            var user = users[userID]!
            user["id"] = userID
            return [
                "data": user,
                "meta": ["authentication_token": "test-access-token"]
            ]
        }
        return []
    }
    
    private func getPosts() -> Any {
        var result = [[String: Any]]()
        for (postID, userID) in userIDByPostID {
            var user = users[userID]!
            user["id"] = userID
            var post = encodePost(postID: postID)
            post["user"] = user
            result.append(post)
        }
        result.sort { (a, b) -> Bool in
            (a["created_at"] as! TimeInterval) > (b["created_at"] as! TimeInterval)
        }
        return ["data": result]
    }
    
    private func getPostsOfUser(userIdentifier: Int) -> Any {
        var result = [[String: Any]]()
        for (postID, userID) in userIDByPostID where userID == userIdentifier {
            var user = users[userID]!
            user["id"] = userID
            var post = encodePost(postID: postID)
            post["user"] = user
            result.append(post)
        }
        result.sort { (a, b) -> Bool in
            (a["created_at"] as! TimeInterval) > (b["created_at"] as! TimeInterval)
        }
        return ["data": result]
    }
    
    private func getUser(userIdentifier: Int) -> Any {
        var user = users[userIdentifier]
        if user != nil {
            user!["id"] = userIdentifier
            return ["data": user]
        }
        return []
    }
    
    // MARK: -
    
    private func encodePost(postID: Int) -> [String: Any] {
        var post = posts[postID]!
        post["created_at"] = ISO8601DateFormatter().date(from: post["date"] as! String)!.timeIntervalSince1970
        post["date"] = nil
        post["id"] = postID
        return post
    }
    
    private let userIDByPostID = [1: 1, 2: 2, 3: 2, 4: 3, 5: 4, 6: 2, 7: 5, 8: 6, 9: 4, 10: 7, 11: 8, 12: 9, 13: 2, 14: 10, 15: 3, 16: 2, 17: 5, 18: 3, 19: 2, 20: 7]
    private let posts: [Int: [String: Any]] = [
        1: ["date": "2020-09-01T12:30:07Z",
            "location": "Art gallery",
            "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
            "image": "mock://sc.com/pic.1.jpg",
            "liked": false,
            "likes_count": 0
        ],
        2: ["date": "2020-08-25T22:57:07Z",
            "location": "New York",
            "description": "Megapolis, here I come! 🤲😻❤️",
            "image": "mock://sc.com/pic.2.jpg",
            "liked": true,
            "likes_count": 2
        ],
        3: ["date": "2020-08-20T20:20:07Z",
            "location": "Hawaii",
            "description": "Such a beautiful night on a beach with friends, wine and dogs!",
            "image": "mock://sc.com/pic.3.jpg",
            "liked": false,
            "likes_count": 0
        ],
        4: ["date": "2020-08-15T12:40:07Z",
            "location": "Abandoned house basement",
            "description": "I made a cool wallpaper. Gonna sell it for a billion bucks at Sotheby's. OK, just donate something please.",
            "image": "mock://sc.com/pic.4.jpg",
            "liked": false,
            "likes_count": 0
        ],
        5: ["date": "2020-08-10T15:50:07Z",
            "location": "Alps",
            "description": "I went skiing on a hot summer night hoping to see a Big Foot or a Small Paw. Shot this instead.",
            "image": "mock://sc.com/pic.5.jpg",
            "liked": false,
            "likes_count": 0
        ],
        6: ["date": "2020-08-05T23:54:07Z",
            "description": "Happy New Year everyone!",
            "image": "mock://sc.com/pic.6.jpg",
            "liked": false,
            "likes_count": 0
        ],
        7: ["date": "2020-07-31T12:46:07Z",
            "location": "Pacific Ocean, Somewhere",
            "description": "I bought myself an island on Craigslist after getting rich on r/WallstreetBets.",
            "image": "mock://sc.com/pic.7.jpg",
            "liked": false,
            "likes_count": 0
        ],
        8: ["date": "2020-07-26T13:12:07Z",
            "location": "Springfield",
            "description": "This was the best picnic this week, BBQ FTW!",
            "image": "mock://sc.com/pic.8.jpg",
            "liked": false,
            "likes_count": 0
        ],
        9: ["date": "2020-07-21T09:24:07Z",
            "location": "National Park",
            "description": "Walking my dog in the park in the morning",
            "image": "mock://sc.com/pic.9.jpg",
            "liked": false,
            "likes_count": 0
        ],
        10: ["date": "2020-07-11T13:31:07Z",
             "location": "In the woods",
             "description": "I was hunting with my grandfather for my 19th birthday about a year ago and we both watched a deer slam its head into a rock shatter its head. We saved a bunch of them bullets.",
             "image": "mock://sc.com/pic.10.jpg",
             "liked": false,
             "likes_count": 0
        ],
        11: ["date": "2020-07-06T15:10:07Z",
             "description": "Comrades, I got my PhD in Photoshop!",
             "image": "mock://sc.com/pic.11.jpg",
             "liked": false,
             "likes_count": 0
        ],
        12: ["date": "2020-07-01T14:40:07Z",
             "location": "Pray, Wisconsin",
             "description": "I love driving my van in the middle of nowhere until I run out of gas. Then I go looking for another van. Movin' is livin' ✊🏿",
             "image": "mock://sc.com/pic.12.jpg",
             "liked": false,
             "likes_count": 0
        ],
        13: ["date": "2020-06-25T02:16:07Z",
             "location": "Backyard",
             "description": "I stitched together 65535 images of the Milky Way to create the most detailed photograph of our galaxy I have ever created. Enjoy!",
             "image": "mock://sc.com/pic.13.jpg",
             "liked": false,
             "likes_count": 0
        ],
        14: ["date": "2020-06-20T12:21:07Z",
             "location": "GPS error, code -11793",
             "description": "Help! I lost my way, somebody please extract geo tags from this photo and tell me where I am! PLEASE!!!",
             "image": "mock://sc.com/pic.14.jpg",
             "liked": false,
             "likes_count": 0
        ],
        15: ["date": "2020-06-15T11:06:07Z",
             "location": "Andes",
             "description": "Alps are great! This is Alps, right?",
             "image": "mock://sc.com/pic.15.jpg",
             "liked": false,
             "likes_count": 0
        ],
        16: ["date": "2020-06-10T14:37:07Z",
             "location": "Bratislava",
             "description": "Chilling in Bratislava…",
             "image": "mock://sc.com/pic.16.jpg",
             "liked": false,
             "likes_count": 0
        ],
        17: ["date": "2020-06-09T16:49:07Z",
             "location": "Paris",
             "description": "This is my new office. The plaza is mine too. Actually, I got the whole city at a discount, that's why it looks a bit empty.",
             "image": "mock://sc.com/pic.17.jpg",
             "liked": false,
             "likes_count": 0
        ],
        18: ["date": "2020-06-06T14:51:07Z",
             "location": "Rome",
             "description": "The best view of the Eye Fall tower you can get",
             "image": "mock://sc.com/pic.18.jpg",
             "liked": false,
             "likes_count": 0
        ],
        19: ["date": "2020-06-02T10:20:07Z",
             "location": "Hilton",
             "description": "What a view outside my hotel room! I ❤️ it!",
             "image": "mock://sc.com/pic.19.jpg",
             "liked": false,
             "likes_count": 0
        ],
        20: ["date": "2020-06-01T16:26:07Z",
             "location": "Košice",
             "description": "Košice is incredibly beautiful in June!",
             "image": "mock://sc.com/pic.20.jpg",
             "liked": false,
             "likes_count": 0
        ]
    ]
    private let users: [Int: [String: Any]] = [
        1: ["full_name": "Albert Johnson", "portrait": "mock://sc.com/avatar.1.jpg", "email": "a.johnson@example.com", "bio": "My name is Albert, but I'm not Einstein",
            "posts_count": 1
        ],
        2: ["full_name": "Beth Lee", "portrait": "mock://sc.com/avatar.2.jpg", "email": "bethlee@example.com", "bio": "Photographer, blogger",
            "posts_count": 6
        ],
        3: ["full_name": "David Charter", "portrait": "mock://sc.com/avatar.3.jpg", "email": "charter@example.com",
            "posts_count": 3
        ],
        4: ["full_name": "Mary Goldsmith", "portrait": "mock://sc.com/avatar.4.jpg", "email": "mary@example.com",
            "posts_count": 2
        ],
        5: ["full_name": "Simon Rochester", "portrait": "mock://sc.com/avatar.5.jpg", "email": "junior.janitor@bighedgefund.com", "bio": "Aspiring quadrillionaire",
            "posts_count": 2
        ],
        6: ["full_name": "Chau Nguyen", "portrait": "mock://sc.com/avatar.6.jpg", "email": "chau@example.com",
            "posts_count": 1
        ],
        7: ["full_name": "Peter Waters", "portrait": "mock://sc.com/avatar.7.jpg", "email": "pw@example.com",
            "posts_count": 2
        ],
        8: ["full_name": "Tiffany MacDowell", "portrait": "mock://sc.com/avatar.8.jpg", "email": "tiff@example.com",
            "posts_count": 1
        ],
        9: ["full_name": "Robert Stoughton", "portrait": "mock://sc.com/avatar.9.jpg", "email": "rob@example.com",
            "posts_count": 1
        ],
        10: ["full_name": "Kate Benedict", "portrait": "mock://sc.com/avatar.10.jpg", "email": "kate@example.com",
             "posts_count": 1
        ],
        123: ["full_name": "John Doe", "portrait": "mock://sc.com/avatar.1.jpg", "email": "john@doe.com",
              "posts_count": 1
        ],
    ]
}
