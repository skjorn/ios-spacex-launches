//

import Foundation

func log(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
