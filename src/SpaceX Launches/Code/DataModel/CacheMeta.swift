//

import Foundation
import Realm
import RealmSwift

@objcMembers final class CacheMeta: Object, Clonable {
    typealias Value = CacheMeta
    
    enum Id: Int {
        case Default = 1
    }
    
    dynamic var id = Id.Default.rawValue
    dynamic var launchesTimestamp: Date? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required init() {
        super.init()
    }
    
    init(value: CacheMeta) {
        super.init()
        
        id = value.id
        launchesTimestamp = value.launchesTimestamp
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}
