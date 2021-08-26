import Foundation


extension Date {
    private static func createDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        return dateFormatter
    }
    private static var shortDateFormatter: DateFormatter = createDateFormatter()
    
    var stringRepresentation: String {
        get {
            Date.shortDateFormatter.string(from: self)
        }
    }
}
