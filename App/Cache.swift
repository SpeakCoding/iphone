import Foundation


class Cache {
    
    static let shared = Cache()
    static let enabled = !ProcessInfo().arguments.contains("mock-api")
    
    private var database: SQLiteDatabase
    init() {
        let cachesURL = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!
        let databasePath = cachesURL.appendingPathComponent("AppCache.sqlite").path
        if ProcessInfo().arguments.contains("clear-cache") {
            try? FileManager().removeItem(atPath: databasePath)
        }
        database = SQLiteDatabase(filePath: databasePath)
        guard database.open() else {
            print("Could not open the cache database at \(databasePath)")
            return
        }
        print("The cache database is at \(databasePath)")
        
        if !hasTable(name: "posts") {
            let query = """
            CREATE TABLE posts (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "date" REAL,
            "user_id" INTEGER,
            "caption" TEXT,
            "image_url" TEXT,
            "location" TEXT,
            "number_of_likes" INTEGER,
            "number_of_comments" INTEGER,
            "liked" INTEGER
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !hasTable(name: "users") {
            let query = """
            CREATE TABLE users (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "user_name" TEXT,
            "profile_picture_url" TEXT,
            "bio" TEXT,
            "number_of_posts" INTEGER,
            "current" INTEGER DEFAULT 0
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !hasTable(name: "likes") {
            let query = """
            CREATE TABLE likes (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "date" REAL,
            "user_id" INTEGER,
            "post_id" INTEGER
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !hasTable(name: "comments") {
            let query = """
            CREATE TABLE comments (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "date" REAL,
            "text" TEXT,
            "user_id" INTEGER,
            "post_id" INTEGER,
            "parent_comment_id" INTEGER
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
    }
    
    private func hasTable(name: String) -> Bool {
        let result = database.executeQuery(sqlQuery: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", parameters: [name])
        return result.first!["count(*)"] as! Int > 0
    }
    
    func fetchPost(id: Int) -> Post? {
        if let matchingPost = database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE id=?", parameters: [id]).first {
            return Post(row: matchingPost)
        }
        return nil
    }
    
    func fetchAllPosts() -> [Post] {
        return database.executeQuery(sqlQuery: "SELECT * FROM posts ORDER BY date DESC", parameters: nil).map { Post(row: $0) }
    }
    
    func update(post: Post) {
        assert(post.id != 0)
        update(user: post.user)
        database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO posts (id) VALUES (?)", values: [post.id])
        database.executeUpdate(sqlQuery: "UPDATE posts SET date=?,user_id=?,caption=?,image_url=?,location=?,number_of_likes=?,number_of_comments=?,liked=? WHERE id=?", values: [post.date.timeIntervalSinceReferenceDate, post.user.id, post.caption, post.images?.first?.url.absoluteString, post.location, post.numberOfLikes, post.numberOfComments, post.isLiked, post.id])
    }
    
    func fetchUser(id: Int) -> User? {
        if let matchingUser = database.executeQuery(sqlQuery: "SELECT * FROM users WHERE id=?", parameters: [id]).first {
            return User(row: matchingUser)
        }
        return nil
    }
    
    func fetchCurrentUser() -> User? {
        if let matchingUser = database.executeQuery(sqlQuery: "SELECT * FROM users WHERE current=1", parameters: nil).first {
            return User(row: matchingUser)
        }
        return nil
    }
    
    func update(user: User) {
        assert(user.id != 0)
        database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO users (id) VALUES (?)", values: [user.id])
        database.executeUpdate(sqlQuery: "UPDATE users SET user_name=?,profile_picture_url=?,bio=?,number_of_posts=?,current=? WHERE id=?", values: [user.userName, user.profilePictureURL?.absoluteString, user.bio, user.numberOfPosts, user == User.current, user.id])
    }
}


// MARK: - Decoding Model Objects from SQLite Rows


extension User {
    convenience init(row: [String: Any?]) {
        let name = row["user_name"] as! String
        self.init(userName: name)
        self.id = row["id"] as! Int
        if let pictureURI = row["profile_picture_url"] as? String {
            self.profilePictureURL = URL(string: pictureURI)
        }
        self.bio = row["bio"] as? String
        self.numberOfPosts = row["number_of_posts"] as! Int
    }
}


extension Post {
    convenience init(row: [String: Any?]) {
        let date = Date(timeIntervalSinceReferenceDate: row["date"] as! TimeInterval)
        let user = Cache.shared.fetchUser(id: row["user_id"] as! Int)!
        let caption = row["caption"] as! String
        var images: [Image]?
        if let imageURI = row["image_url"] as? String {
            if let imageURL = URL(string: imageURI) {
                images = [Image(url: imageURL)]
            }
        }
        let location = row["location"] as? String
        self.init(creationDate: date, author: user, postCaption: caption, postImages: images, postVideo: nil, postLocation: location)
        self.id = row["id"] as! Int
        self.numberOfLikes = row["number_of_likes"] as! Int
        self.numberOfComments = row["number_of_comments"] as! Int
        self.isLiked = (row["liked"] as! Int) != 0
    }
}
