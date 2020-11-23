import SQLite3
import Foundation


internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


class SQLiteDatabase {
    
    private var dbFilePath: String
    private var db: OpaquePointer?
    
    init(filePath: String) {
        dbFilePath = filePath
    }
    
    func open() -> Bool {
        guard db == nil else {
            return true
        }
        if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
            return true
        }
        print("Unable to open database")
        return false
    }
    
    func close() {
        if db != nil {
            sqlite3_close(db!)
            db = nil
        }
    }
    
    /**
     Execute an update statement, i.e. a statement which doesn't return results, such as UPDATE, INSERT and DELETE.
     - Parameter sqlQuery: An SQL query.
     - Parameter values: An array of values substituting placeholder tokens in the SQL query.
     */
    func executeUpdate(sqlQuery: String, values: [Any?]?) {
        guard db != nil else {
            fatalError("Call open() first")
        }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db!, sqlQuery.cString(using: String.Encoding.utf8), -1, &statement, nil) == SQLITE_OK else {
            reportFatalError(message: "Invalid query", sqlQuery: sqlQuery)
        }
        let numberOfValues = values?.count ?? 0
        guard numberOfValues == Int(sqlite3_bind_parameter_count(statement)) else {
            fatalError("\(sqlite3_bind_parameter_count(statement)) values expected, \(numberOfValues) passed")
        }
        
        if values != nil {
            bind(statement: statement!, values: values!)
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            reportFatalError(message: "Invalid query", sqlQuery: sqlQuery)
        }
        sqlite3_finalize(statement)
    }
    
    /**
     Execute a SELECT statement.
     - Parameter sqlQuery: An SQL query.
     - Parameter parameters: An array of parameters substituting placeholder tokens in the SQL query.
     - Returns: An array of dictionaries where keys are table column names.
     */
    func executeQuery(sqlQuery: String, parameters: [Any?]?) -> [[String: Any?]] {
        guard db != nil else {
            fatalError("Call open() first")
        }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db!, sqlQuery.cString(using: String.Encoding.utf8), -1, &statement, nil) == SQLITE_OK else {
            reportFatalError(message: "Invalid query", sqlQuery: sqlQuery)
        }
        let numberOfValues = parameters?.count ?? 0
        guard numberOfValues == Int(sqlite3_bind_parameter_count(statement)) else {
            fatalError("\(sqlite3_bind_parameter_count(statement)) parameters expected, \(numberOfValues) passed")
        }
        
        if parameters != nil {
            bind(statement: statement!, values: parameters!)
        }
        
        var queryResult = [[String: Any?]]()
        let columnCount = sqlite3_column_count(statement)
        var columnNames = [String]()
        for columnIndex in 0..<columnCount {
            columnNames.append(String(cString: sqlite3_column_name(statement, columnIndex)))
        }
        var stepResultCode: Int32
        while (stepResultCode = sqlite3_step(statement), stepResultCode).1 == SQLITE_ROW {
            var rowDictionary = [String: Any?]()
            let rowColumnCount = sqlite3_data_count(statement)
            for columnIndex in 0..<rowColumnCount {
                var value: Any?
                switch sqlite3_column_type(statement, columnIndex) {
                    case SQLITE_INTEGER:
                        value = Int(sqlite3_column_int64(statement, columnIndex))
                    case SQLITE_FLOAT:
                        value = sqlite3_column_double(statement, columnIndex)
                    case SQLITE_BLOB:
                        value = Data(bytes: sqlite3_column_blob(statement, columnIndex), count: Int(sqlite3_column_bytes(statement, columnIndex)))
                    case SQLITE_TEXT, SQLITE3_TEXT:
                        if let cStringText = sqlite3_column_text(statement, columnIndex) {
                            value = String(cString: cStringText)
                        }
                    // default is SQLITE_NULL
                    default:
                        break
                }
                rowDictionary[columnNames[Int(columnIndex)]] = value
            }
            queryResult.append(rowDictionary)
        }
        
        if stepResultCode != SQLITE_DONE {
            reportFatalError(message: "Invalid query", sqlQuery: sqlQuery)
        }
        sqlite3_finalize(statement)
        return queryResult
    }
    
    func commitTransaction(updates: () -> Void) {
        executeUpdate(sqlQuery: "BEGIN EXCLUSIVE TRANSACTION", values: nil)
        updates()
        executeUpdate(sqlQuery: "COMMIT TRANSACTION", values: nil)
    }
    
    // MARK: - Private stuff
    
    private func bind(statement: OpaquePointer, values: [Any?]) {
        var argumentIndex = 1 as Int32
        for value in values {
            if value == nil {
                sqlite3_bind_null(statement, argumentIndex)
            } else if let value = value as? Double {
                sqlite3_bind_double(statement, argumentIndex, value)
            } else if let value = value as? Int {
                sqlite3_bind_int64(statement, argumentIndex, Int64(value))
            } else if let value = value as? Bool {
                sqlite3_bind_int(statement, argumentIndex, value ? 1 : 0)
            } else if let value = value as? String {
                sqlite3_bind_text(statement, argumentIndex, value.cString(using: String.Encoding.utf8), -1, SQLITE_TRANSIENT)
            } else if let value = value as? Data {
                sqlite3_bind_blob(statement, argumentIndex, (value as NSData).bytes, Int32(value.count), SQLITE_TRANSIENT)
            }
            argumentIndex += 1
        }
    }
    
    private func reportFatalError(message: String, sqlQuery: String) -> Never {
        if let errorPointer = sqlite3_errmsg(db!) {
            fatalError("\(message), \(String(cString: errorPointer))")
        } else {
            fatalError(message)
        }
    }
}
