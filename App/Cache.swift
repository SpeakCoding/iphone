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
        self.database = SQLiteDatabase(filePath: databasePath)
        setUpDatabaseTables()
    }
    
    func reset() {
        self.database.close()
        try? FileManager().removeItem(atPath: self.database.databaseFilePath)
        setUpDatabaseTables()
    }
    
    private func setUpDatabaseTables() {
        guard self.database.open() else {
            print("Could not open the cache database")
            return
        }
        
        if !self.hasTable(tableName: "posts") {
            let query = """
            CREATE TABLE posts (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "date" REAL,
            "user_id" INTEGER,
            "caption" TEXT,
            "image_url" TEXT,
            "location" TEXT,
            "number_of_likes" INTEGER,
            "saved" INTEGER,
            "liked" INTEGER,
            "liker_followee_id" INTEGER,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (liker_followee_id) REFERENCES users(id)
            )
            """
            self.database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !self.hasTable(tableName: "feed") {
            let query = """
            CREATE TABLE feed (
            "post_id" INTEGER NOT NULL,
            "position" INTEGER NOT NULL,
            FOREIGN KEY (post_id) REFERENCES posts(id)
            )
            """
            self.database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !self.hasTable(tableName: "users") {
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
            self.database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !self.hasTable(tableName: "comments") {
            let query = """
            CREATE TABLE comments (
            "id" INTEGER PRIMARY KEY NOT NULL,
            "date" REAL,
            "text" TEXT,
            "post_id" INTEGER,
            "user_id" INTEGER,
            FOREIGN KEY (post_id) REFERENCES posts(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
            )
            """
            self.database.executeUpdate(sqlQuery: query, values: nil)
        }
        
        if !self.hasTable(tableName: "tags") {
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
            self.database.executeUpdate(sqlQuery: query, values: nil)
        }
    }
    
    private func hasTable(tableName: String) -> Bool {
        let result = self.database.executeQuery(sqlQuery: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", parameters: [tableName])
        return result.first!["count(*)"] as! Int > 0
    }
    
    func update(post: Post) {
        assert(post.id != 0)
        update(user: post.user)
        if post.likerFollowee != nil {
            update(user: post.likerFollowee!)
        }
        self.database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO posts (id) VALUES (?)", values: [post.id])
        self.database.executeUpdate(sqlQuery: "UPDATE posts SET date=?,user_id=?,caption=?,image_url=?,location=?,number_of_likes=?,liked=?,saved=?,liker_followee_id=? WHERE id=?", values: [post.date.timeIntervalSinceReferenceDate, post.user.id, post.caption, post.images?.first?.url.absoluteString, post.location, post.numberOfLikes, post.isLiked, post.isSaved, post.likerFollowee?.id, post.id])
        update(tags: post.tags, post: post)
        for comment in post.comments {
            update(comment: comment, post: post)
        }
    }
    
    func update(user: User) {
        assert(user.id != 0)
        self.database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO users (id) VALUES (?)", values: [user.id])
        self.database.executeUpdate(sqlQuery: "UPDATE users SET user_name=?,profile_picture_url=?,bio=?,number_of_posts=?,followers_count=?,followees_count=?,is_follower=?,is_followed=? WHERE id=?", values: [user.userName, user.profilePictureURL?.absoluteString, user.bio, user.numberOfPosts, user.numberOfFollowers, user.numberOfFollowees, user.isFollower, user.isFollowed, user.id])
    }
    
    func update(tags: [Tag], post: Post) {
        assert(post.id != 0)
        if tags.count > 0 {
            for tag in tags {
                assert(tag.user.id != 0)
                self.database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO tags (post_id,user_id) VALUES (?,?)", values: [post.id, tag.user.id])
                self.database.executeUpdate(sqlQuery: "UPDATE tags SET left=?,top=? WHERE post_id=? AND user_id=?", values: [tag.point.x, tag.point.y, post.id, tag.user.id])
            }
        } else {
            self.database.executeUpdate(sqlQuery: "DELETE FROM tags WHERE post_id=?", values: [post.id])
        }
    }
    
    func update(comment: Comment, post: Post) {
        assert(comment.id != 0)
        assert(post.id != 0)
        update(user: comment.user)
        self.database.executeUpdate(sqlQuery: "INSERT OR IGNORE INTO comments (id) VALUES (?)", values: [comment.id])
        self.database.executeUpdate(sqlQuery: "UPDATE comments SET date=?,user_id=?,post_id=?,text=? WHERE id=?", values: [comment.date.timeIntervalSinceReferenceDate, comment.user.id, post.id, comment.text, comment.id])
    }
    
    func update(feed: Feed) {
        // Wrapping a lot of SQLite updates in a transaction results in much better performance.
        // For example, updating a 100 post feed is about 10 times faster when in a single transaction.
        self.database.commitTransaction {
            self.database.executeUpdate(sqlQuery: "DELETE FROM feed", values: nil)
            for (postIndex, post) in feed.posts.enumerated() {
                update(post: post)
                self.database.executeUpdate(sqlQuery: "INSERT INTO feed (post_id,position) VALUES (?,?)", values: [post.id, postIndex])
            }
        }
    }
    
    func fetchPost(id: Int) -> Post? {
        if let matchingPostInfo = self.database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE id=?", parameters: [id]).first {
            return Post.instance(withSQLRow: matchingPostInfo)
        }
        return nil
    }
    
    func fetchUser(id: Int) -> User? {
        if let matchingUserInfo = self.database.executeQuery(sqlQuery: "SELECT * FROM users WHERE id=?", parameters: [id]).first {
            return User.instance(withSQLRow: matchingUserInfo)
        }
        return nil
    }
    
    func fetchFeedPosts() -> [Post] {
        return self.database.executeQuery(sqlQuery: "SELECT * FROM posts INNER JOIN feed ON posts.id=feed.post_id ORDER BY feed.position ASC", parameters: nil).map { Post.instance(withSQLRow: $0) }
    }
    
    func fetchSavedPosts() -> [Post] {
        return self.database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE saved=1 ORDER BY id DESC", parameters: nil).map { Post.instance(withSQLRow: $0) }
    }
    
    func fetchPostsMadeBy(user: User) -> [Post] {
        return self.database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE user_id=? ORDER BY id DESC", parameters: [user.id]).map { Post.instance(withSQLRow: $0) }
    }
    
    func fetchPostsWithTagged(user: User) -> [Post] {
        return self.database.executeQuery(sqlQuery: "SELECT * FROM posts WHERE EXISTS (SELECT post_id,user_id FROM tags WHERE post_id=posts.id AND user_id=?) ORDER BY id DESC", parameters: [user.id]).map { Post.instance(withSQLRow: $0) }
    }
    
    func fetchCommments(post: Post) -> [Comment] {
        return self.database.executeQuery(sqlQuery: "SELECT * FROM comments WHERE post_id=? ORDER BY date ASC", parameters: [post.id]).map { Comment.instance(withSQLRow: $0) }
    }
    
    func delete(post: Post) {
        self.database.executeUpdate(sqlQuery: "DELETE FROM posts WHERE id=?", values: [post.id])
    }
}


// MARK: - Decoding Model Objects from SQLite Rows


extension User {
    class func instance(withSQLRow row: [String: Any?]) -> User {
        let user: User = self.instance(withID: row["id"] as! Int)
        user.userName = (row["user_name"] as! String)
        if let pictureURI = row["profile_picture_url"] as? String {
            user.profilePictureURL = URL(string: pictureURI)
        }
        user.bio = row["bio"] as? String
        user.numberOfPosts = row["number_of_posts"] as! Int
        user.numberOfFollowers = row["followers_count"] as! Int
        user.numberOfFollowees = row["followees_count"] as! Int
        user.isFollower = (row["is_follower"] as! Int) != 0
        user.isFollowed = (row["is_followed"] as! Int) != 0
        return user
    }
}


extension Post {
    class func instance(withSQLRow row: [String: Any?]) -> Post {
        let post: Post = self.instance(withID: row["id"] as! Int)
        post.date = Date(timeIntervalSinceReferenceDate: row["date"] as! TimeInterval)
        post.user = Cache.shared.fetchUser(id: row["user_id"] as! Int)!
        post.caption = (row["caption"] as! String)
        if let imageURI = row["image_url"] as? String {
            if let imageURL = URL(string: imageURI) {
                post.images = [Image(url: imageURL)]
            }
        } else {
            post.images = nil
        }
        post.location = row["location"] as? String
        post.numberOfLikes = row["number_of_likes"] as! Int
        post.isLiked = (row["liked"] as! Int) != 0
        post.isSaved = (row["saved"] as! Int) != 0
        post.comments = Cache.shared.fetchCommments(post: post)
        if let likerFolloweeID = row["liker_followee_id"] as? Int {
            post.likerFollowee = Cache.shared.fetchUser(id: likerFolloweeID)
        }
        return post
    }
}


extension Comment {
    class func instance(withSQLRow row: [String: Any?]) -> Comment {
        let comment: Comment = self.instance(withID: row["id"] as! Int)
        comment.date = Date(timeIntervalSinceReferenceDate: row["date"] as! TimeInterval)
        comment.user = Cache.shared.fetchUser(id: row["user_id"] as! Int)!
        comment.text = (row["text"] as! String)
        return comment
    }
}
