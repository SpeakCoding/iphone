import Foundation


class ModelObject: Equatable {
    
    var id: Int = 0
    
    required init(id: Int) {
        self.id = id
    }
    
    static func == (lhs: ModelObject, rhs: ModelObject) -> Bool {
        lhs.id == rhs.id
    }
    
    private static var instanceStore = [String: NSMapTable <NSNumber, ModelObject>]()
    
    class func instance<T: ModelObject>(withID id: Int) -> T {
        let myClassName = NSStringFromClass(self)
        var instancesOfMyClass = instanceStore[myClassName]
        if instancesOfMyClass == nil {
            instancesOfMyClass = NSMapTable(keyOptions: NSPointerFunctions.Options.copyIn, valueOptions: NSPointerFunctions.Options.weakMemory)
            instanceStore[myClassName] = instancesOfMyClass!
        }
        
        if let existingInstance = instancesOfMyClass!.object(forKey: NSNumber(integerLiteral: id)) {
            return existingInstance as! T
        }
        
        let newInstance = self.init(id: id)
        instancesOfMyClass!.setObject(newInstance, forKey: NSNumber(integerLiteral: id))
        return newInstance as! T
    }
    
    class func purgeCachedInstances() {
        instanceStore.removeAll()
    }
}
