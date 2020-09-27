import Foundation


class ModelObject: Equatable {
    
    var id: Int = 0
    
    static func == (lhs: ModelObject, rhs: ModelObject) -> Bool {
        lhs.id == rhs.id
    }
}
