//

import Foundation

extension String {
    public var utf8Encoded: Data {
        return self.data(using: .utf8)!
    }
}
