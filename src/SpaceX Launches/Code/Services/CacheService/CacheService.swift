//

import Foundation
import RealmSwift
import RxSwift

// The service is thread safe, i.e. all methods can be called from any thread.
class CacheService: Service {
    
    func start() {
        onMainThread {
            // No caching, no game. There isn't much we can do without data. So just crash on failure.
            realm = try! Realm()
            let folderUrl = realm!.configuration.fileURL!.deletingLastPathComponent()
            try? (folderUrl as NSURL).setResourceValue(URLFileProtection.none, forKey: .fileProtectionKey)
        }
    }
    
    func stop() {
        onMainThread {
            realm = nil
        }
    }
    
    func replaceAll<RecordType: Object>(with objects: [RecordType]) -> Completable {
        return Completable.create { completable in
            DispatchQueue.global(qos: .userInitiated).async {
                self.withRealm { realm in
                    do {
                        try realm.write {
                            // Delete old
                            
                            realm.delete(realm.objects(RecordType.self))
                            
                            // Add new
                            
                            realm.add(objects)
                        }
                        
                        DispatchQueue.main.sync {
                            completable(.completed)
                        }
                    }
                    catch {
                        DispatchQueue.main.sync {
                            completable(.error(error))
                        }
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func selectAll<RecordType: Object>(ofType type: RecordType.Type, sortBy primarySortKey: String? = nil, thenBy secondarySortKey: String? = nil, ascending: Bool = true) -> [RecordType] {
        var result: [RecordType] = []
        
        onMainThread {
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
        }

        return result
    }
    
    func select<RecordType: Object & Clonable>(object type: RecordType.Type, withId id: Int) -> RecordType? {
        var result: RecordType? = nil
        
        onMainThread {
            withRealm { realm in
                result = realm.object(ofType: type, forPrimaryKey: id)
                if result != nil {
                    // Convert to unmanaged Realm object, so it can be passed across threads.
                    result = RecordType(value: result!)
                }
            }
        }
        
        return result
    }
    
    func add<RecordType: Object>(object: RecordType) throws {
        try onMainThread {
            try withRealm { realm in
                try realm.write {
                    realm.add(object, update: true)
                }
            }
        }
    }
    
    // MARK: - Private implementation
    
    private var realm: Realm? = nil
    
    // Ensure there's a Realm and run a task on it. If this is background work, allocate the Realm temporarily.
    private func withRealm(_ task: (Realm) throws -> Void) rethrows {
        var realm = Thread.current.isMainThread ? self.realm : nil
        
        if realm == nil {
            do {
                realm = try Realm()
                let folderUrl = realm!.configuration.fileURL!.deletingLastPathComponent()
                try? (folderUrl as NSURL).setResourceValue(URLFileProtection.none, forKey: .fileProtectionKey)
            }
            catch {
                // Unable to access Realm when stopped. Do nothing.
                if self.realm == nil {
                    return
                }
                // Else we are not on the main thread and failed to acquire Realm (probably for writes on a different thread),
                // so crash at the line below. The app is useless without data refresh.
            }
        }
        
        try task(realm!)
    }
    
    // Ensure the work is executed on the main thread.
    private func onMainThread(_ task: () throws -> Void) rethrows {
        if Thread.current.isMainThread {
            try task()
        }
        else {
            try DispatchQueue.main.sync {
                try task()
            }
        }
    }
    
    // For development purposes. Wipe out whole database.
    static private func eraseRealm() {
        let folderUrl = Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: folderUrl)
    }
}
