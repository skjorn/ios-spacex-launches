//

import Foundation

extension String {
    var utf8Encoded: Data {
        return self.data(using: .utf8)!
    }
}
