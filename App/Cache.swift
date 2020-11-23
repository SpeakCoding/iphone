import Foundation


class Cache {
    
    static let shared = Cache()
    
    private var database: SQLiteDatabase
    
    init() {
        let cachesURL = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!
        let databasePath = cachesURL.appendingPathComponent("AppCache.sqlite").path
        if ProcessInfo().arguments.contains("clear-cache") {
            try? FileManager().removeItem(atPath: databasePath)
        }
        if !FileManager().fileExists(atPath: cachesURL.path) {
            try? FileManager().createDirectory(at: cachesURL, withIntermediateDirectories: true, attributes: nil)
        }
        database = SQLiteDatabase(filePath: databasePath)
        while true {
            guard database.open() else {
                print("Could not open the cache database at \(databasePath)")
                return
            }
            
            // Make sure the database version which we store in the "user_version" pragma is up-to-date
            let currentDatabaseVersion = 3
            let onDiskDatabaseVersion = database.executeQuery(sqlQuery: "PRAGMA user_version", parameters: nil).first!["user_version"] as! Int
            print("The cache database is version \(onDiskDatabaseVersion) at \(databasePath)")
            if onDiskDatabaseVersion == currentDatabaseVersion {
                break
            }
            
            if onDiskDatabaseVersion == 0 && !hasTable(tableName: "posts") {
                // The database has just been created, the "user_version" pragma is not set yet
                database.executeUpdate(sqlQuery: "PRAGMA user_version = \(currentDatabaseVersion)", values: nil)
                break
            }
            
            // The database schema is outdated, delete and recreate the database
            database.close()
            try? FileManager().removeItem(atPath: databasePath)
        }
        
        if !hasTable(tableName: "posts") {
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
            "saved" INTEGER,
            "liked" INTEGER
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !hasTable(tableName: "feed") {
            let query = """
            CREATE TABLE feed (
            "post_id" INTEGER NOT NULL,
            "position" INTEGER NOT NULL,
            FOREIGN KEY (post_id) REFERENCES posts(id)
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !hasTable(tableName: "users") {
            let query = """
            CREATE TABLE users (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "user_name" TEXT,
            "profile_picture_url" TEXT,
            "bio" TEXT,
            "number_of_posts" INTEGER,
            "followers_count" INTEGER,
            "followees_count" INTEGER,
            "is_follower" INTEGER,
            "is_followed" INTEGER
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        /*
        if !hasTable(tableName: "likes") {
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
        */
        if !hasTable(tableName: "comments") {
            let query = """
            CREATE TABLE comments (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "date" REAL,
            "text" TEXT,
            "user_id" INTEGER,
            "post_id" INTEGER
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !hasTable(tableName: "tags") {
            let query = """
            CREATE TABLE tags (
            "post_id" INTEGER NOT NULL,
            "user_id" INTEGER NOT NULL,
            "top" REAL,
            "left" REAL,
            FOREIGN KEY (post_id) REFERENCES posts(id),
            FOREIGN KEY (user_id) REFERENCES users(id),
            UNIQUE (post_id, user_id)
            )
            """
            database.executeUpdate(sqlQuery: query, values: nil)
        }
    }
    
    private func hasTable(tableName: String) -> Bool {
        let result = database.executeQuery(sqlQuery: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", parameters: [tableName])
        return result.first!["count(*)"] as! Int > 0
    }
    
    func update(post: Post) {
        assert(post.id != 0)
        update(user: post.user)
        database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO posts (id) VALUES (?)", values: [post.id])
        database.executeUpdate(sqlQuery: "UPDATE posts SET date=?,user_id=?,caption=?,image_url=?,location=?,number_of_likes=?,number_of_comments=?,liked=?,saved=? WHERE id=?", values: [post.date.timeIntervalSinceReferenceDate, post.user.id, post.caption, post.images?.first?.url.absoluteString, post.location, post.numberOfLikes, post.numberOfComments, post.isLiked, post.isSaved, post.id])
        update(tags: post.tags, post: post)
        for comment in post.comments {
            update(comment: comment, post: post)
        }
    }
    
    func update(user: User) {
        assert(user.id != 0)
        database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO users (id) VALUES (?)", values: [user.id])
        database.executeUpdate(sqlQuery: "UPDATE users SET user_name=?,profile_picture_url=?,bio=?,number_of_posts=?,followers_count=?,followees_count=?,is_follower=?,is_followed=? WHERE id=?", values: [user.userName, user.profilePictureURL?.absoluteString, user.bio, user.numberOfPosts, user.numberOfFollowers, user.numberOfFollowees, user.isFollower, user.isFollowed, user.id])
    }
    
    func update(tags: [Tag], post: Post) {
        assert(post.id != 0)
        if tags.count > 0 {
            for tag in tags {
                assert(tag.user.id != 0)
                database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO tags (post_id,user_id) VALUES (?,?)", values: [post.id, tag.user.id])
                database.executeUpdate(sqlQuery: "UPDATE tags SET left=?,top=? WHERE post_id=? AND user_id=?", values: [tag.point.x, tag.point.y, post.id, tag.user.id])
            }
        } else {
            database.executeUpdate(sqlQuery: "DELETE FROM tags WHERE post_id=?", values: [post.id])
        }
    }
    
    func update(comment: Comment, post: Post) {
        assert(comment.id != 0)
        assert(post.id != 0)
        database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO comments (id) VALUES (?)", values: [comment.id])
        database.executeUpdate(sqlQuery: "UPDATE comments SET date=?,user_id=?,post_id=?,text=? WHERE id=?", values: [comment.date.timeIntervalSinceReferenceDate, comment.user.id, post.id, comment.text, comment.id])
    }
    
    func update(feed: Feed) {
        // Wrapping a lot of SQLite updates in a transaction results in much better performance.
        // For example, updating a 100 post feed is about 10 times faster when in a single transaction.
        database.commitTransaction {
            database.executeUpdate(sqlQuery: "DELETE from feed", values: nil)
            for (postIndex, post) in feed.posts.enumerated() {
                update(post: post)
                database.executeUpdate(sqlQuery: "INSERT INTO feed (post_id,position) VALUES (?,?)", values: [post.id, postIndex])
            }
        }
    }
    
    func fetchPost(id: Int) -> Post? {
        if let matchingPost = database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE id=?", parameters: [id]).first {
            return Post(row: matchingPost)
        }
        return nil
    }
    
    func fetchUser(id: Int) -> User? {
        if let matchingUser = database.executeQuery(sqlQuery: "SELECT * FROM users WHERE id=?", parameters: [id]).first {
            return User(row: matchingUser)
        }
        return nil
    }
    
    func fetchFeedPosts() -> [Post] {
        return database.executeQuery(sqlQuery: "SELECT * FROM posts INNER JOIN feed ON posts.id=feed.post_id ORDER BY feed.position ASC", parameters: nil).map { Post(row: $0) }
    }
    
    func fetchSavedPosts() -> [Post] {
        return database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE saved=1 ORDER BY id DESC", parameters: nil).map { Post(row: $0) }
    }
    
    func fetchPostsMadeBy(user: User) -> [Post] {
        return database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE user_id=? ORDER BY id DESC", parameters: [user.id]).map { Post(row: $0) }
    }
    
    func fetchPostsWithTagged(user: User) -> [Post] {
        return database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE EXISTS (SELECT post_id,user_id FROM tags WHERE post_id=posts.id AND user_id=?) ORDER BY id DESC", parameters: [user.id]).map { Post(row: $0) }
    }
    
    func fetchCommments(post: Post) -> [Comment] {
        return database.executeQuery(sqlQuery: "SELECT * FROM comments WHERE post_id=? ORDER BY date ASC", parameters: [post.id]).map { Comment(row: $0) }
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
        self.numberOfFollowers = row["followers_count"] as! Int
        self.numberOfFollowees = row["followees_count"] as! Int
        self.isFollower = (row["is_follower"] as! Int) != 0
        self.isFollowed = (row["is_followed"] as! Int) != 0
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
        self.isSaved = (row["saved"] as! Int) != 0
        self.comments = Cache.shared.fetchCommments(post: self)
    }
}


extension Comment {
    convenience init(row: [String: Any?]) {
        let date = Date(timeIntervalSinceReferenceDate: row["date"] as! TimeInterval)
        let user = Cache.shared.fetchUser(id: row["user_id"] as! Int)!
        let text = row["text"] as! String
        self.init(date: date, user: user, text: text)
        self.id = row["id"] as! Int
    }
}
