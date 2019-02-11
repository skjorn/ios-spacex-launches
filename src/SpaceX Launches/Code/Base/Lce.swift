//

import Foundation

struct Lce<T> {
    var loading: Bool
    var error: Error?
    var data: T?
    
    var hasError: Bool { return error != nil }
    
    init(loading: Bool, data: T?) {
        self.loading = loading
        self.data = data
        self.error = nil
    }
    
    init(error: Error) {
        self.loading = false
        self.data = nil
        self.error = error
    }
}

extension Lce: CustomStringConvertible {
    var description: String {
        return "Lce(loading: \(loading), hasError: \(hasError), data: \(data == nil ? "nil" : "some"))"
    }
}
