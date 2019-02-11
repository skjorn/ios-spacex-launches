//

import Foundation

extension NSObject {
    public class var nameOfClass: String {
        return self.description().components(separatedBy: ".").last ?? ""
    }
}
