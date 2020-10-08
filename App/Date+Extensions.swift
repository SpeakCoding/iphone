import Foundation


extension Date {
    private static var shortDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter
    }()
    
    var stringRepresentation: String {
        get {
            Date.shortDateFormatter.string(from: self)
        }
    }
}
