import Foundation


struct Point {
    var x: Double
    var y: Double
}

class Tag {
    
    var user: User
    var point: Point
    
    init(taggedUser: User, point: Point) {
        self.user = taggedUser
        self.point = point
    }
}
