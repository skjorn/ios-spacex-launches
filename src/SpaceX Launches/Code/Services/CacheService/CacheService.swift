//

import Foundation
import RealmSwift
import RxSwift

class CacheService: Service {
    
    func start() {
        // No caching, no game. There isn't much we can do without data. So just crash on failure.
        realm = try! Realm()
        let folderUrl = realm!.configuration.fileURL!.deletingLastPathComponent()
        try? (folderUrl as NSURL).setResourceValue(URLFileProtection.none, forKey: .fileProtectionKey)
    }
    
    func stop() {
        realm = nil
    }
    
    func replaceAll<RecordType: Object>(with objects: [RecordType]) -> Completable {
        return Completable.create { completable in
            self.withRealm { realm in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try realm.write {
                            // Delete old
                            
                            realm.delete(realm.objects(RecordType.self))
                            
                            // Add new
                            
                            realm.add(objects)
                        }
                        
                        completable(.completed)
                    }
                    catch {
                        completable(.error(error))
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func selectAll<RecordType: Object>(ofType type: RecordType.Type, sortBy primarySortKey: String? = nil, thenBy secondarySortKey: String? = nil, ascending: Bool = true) -> [RecordType] {
        var result: [RecordType] = []
        
        withRealm { realm in
            var objects = realm.objects(type)
            
            if let primarySortKey = primarySortKey {
                var sortDescriptors = [SortDescriptor(keyPath: primarySortKey, ascending: ascending)]
                if let secondarySortKey = secondarySortKey {
                    sortDescriptors.append(SortDescriptor(keyPath: secondarySortKey, ascending: ascending))
                }
                
                objects = objects.sorted(by: sortDescriptors)
            }
            
            result = Array(objects)
        }
        
        return result
    }
    
    // MARK: - Private implementation
    
    private var realm: Realm? = nil
    
    // Ensure there's a Realm and run a task on it. If this is background work, allocate the Realm temporarily.
    private func withRealm(_ task: (Realm) -> Void) {
        var realm = self.realm
        
        if realm == nil {
            do {
                realm = try Realm()
                let folderUrl = realm!.configuration.fileURL!.deletingLastPathComponent()
                try? (folderUrl as NSURL).setResourceValue(URLFileProtection.none, forKey: .fileProtectionKey)
            }
            catch {
                // Unable to access Realm when stopped. Do nothing.
                return
            }
        }
        
        task(realm!)
    }
}
