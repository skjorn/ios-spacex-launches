//

import Foundation

protocol MaskedModel {
    static var filter: String { get }
    static var codingKeys: [CodingKey] { get }
    static func childrenCodingKeys(for key: CodingKey) -> [CodingKey]?
}

extension MaskedModel {
    static var filter: String {
        return getFilter(for: codingKeys, withPrefix: "")
    }
    
    static private func getFilter(for keys: [CodingKey], withPrefix prefix: String) -> String {
        return keys.map({ key in
            let currentPath = prefix.isEmpty ? key.stringValue : prefix + "/\(key.stringValue)"
            if let childrenKeys = childrenCodingKeys(for: key) {
                let childrenFilter = getFilter(for: childrenKeys, withPrefix: "")
                return currentPath + (childrenFilter.isEmpty ? "" : "(\(childrenFilter))")
            }
            else {
                return currentPath
            }
        })
        .joined(separator: ",")
    }
}
