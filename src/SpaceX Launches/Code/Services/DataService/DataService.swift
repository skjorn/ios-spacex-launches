//

import Foundation
import RxSwift

let INVALIDATION_TIME: TimeInterval = 24 * 60 * 60 // 24 hours

class DataService: Service {
    init(apiService: ApiService, cacheService: CacheService) {
        self.apiService = apiService
        self.cacheService = cacheService
    }
    
    func start() {}
    
    func stop() {}
    
    func getLaunches(_ input: Observable<Bool>) -> Observable<Lce<[LaunchPreview]>> {
        var inProgress = false
        
        let idle = input
            .share(replay: 0, scope: .forever)
            .filter({ _ in !inProgress })
            .do(onNext: { _ in
                log("--- Get past launches")
                inProgress = true
            })
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        
        let shouldFetch = idle
            .map({ (force: Bool) -> Bool in
                if force {
                    return true
                }
                else {
                    let cacheMeta = self.cacheService.select(object: CacheMeta.self, withId: CacheMeta.Id.Default.rawValue)
                    log("Last cached: \(cacheMeta?.launchesTimestamp?.debugDescription ?? "never")")
                    return cacheMeta == nil
                        || cacheMeta!.launchesTimestamp == nil
                        || Date().timeIntervalSince(cacheMeta!.launchesTimestamp!) >= INVALIDATION_TIME
                }
            })
            .share(replay: 0, scope: .forever)

        let noFetch = shouldFetch
            .filter({ !$0 })
            .map({ _ -> Lce<[LaunchPreview]> in
                let cachedData = self.cacheService.selectAll(ofType: LaunchPreview.self)
                return Lce(loading: false, data: cachedData)
            })
            .do(onNext: { _ in
                log("Cached launches returned")
                inProgress = false
            })
        
        let fetch = shouldFetch
            .filter({ $0 })
            .flatMap({ _ in
                return self.apiService.request(.getPastLaunches, filter: LaunchPreview.filter).asObservable()
                    .map({ (result: [LaunchPreview]) -> Lce<[LaunchPreview]> in
                        return Lce(loading: false, data: result)
                    })
                    .catchError({ error -> Observable<Lce<[LaunchPreview]>> in
                        return Observable.just(Lce(error: error))
                    })
                    .do(onNext: { result in
                        log("Fetching via API...")
                        if result.hasError {
                            log("Error: \(result.error!.localizedDescription)")
                        }
                        else {
                            log("\(result.data?.count ?? 0) items received")
                        }
                    })
                    .startWith({
                        let cachedData = self.cacheService.selectAll(ofType: LaunchPreview.self)
                        return Lce(loading: true, data: cachedData)
                    }())
            })
            .share(replay: 0, scope: .forever)

        let noCache = fetch
            .filter({ $0.loading || $0.hasError })
            .do(onNext: { inProgress = $0.loading })

        let cache = fetch
            .filter({ !$0.loading && !$0.hasError })
            .flatMap({ result -> Observable<Lce<[LaunchPreview]>> in
                return self.cacheService.replaceAll(with: result.data!).asObservable()
                    .materialize()
                    .flatMap({ result -> Observable<Lce<[LaunchPreview]>> in
                        switch result {
                            
                        case .completed:
                            let cacheMeta = self.cacheService.select(object: CacheMeta.self, withId: CacheMeta.Id.Default.rawValue) ?? CacheMeta()
                            cacheMeta.launchesTimestamp = Date()
                            
                            do {
                                try self.cacheService.add(object: cacheMeta)
                            }
                            catch {
                                return Observable.just(Lce(error: error))
                            }
                            
                            let data = self.cacheService.selectAll(ofType: LaunchPreview.self)
                            return Observable.just(Lce(loading: false, data: data))
                            
                        case .error(let error):
                            return Observable.just(Lce(error: error))
                            
                        case .next:
                            // Shouldn't happen with a Completable
                            return Observable.empty()
                        }
                    })
            })
            .do(onNext: { result in
                inProgress = false
                if result.hasError {
                    log("Caching results failed: \(result.error!.localizedDescription)")
                }
                else {
                    log("Results cached")
                }
            })

        return Observable.of(cache, noCache, noFetch).merge()
    }
    
    func getLaunchDetail(for flightNumber: Int) -> Observable<Lce<Launch>> {
        log("--- Get launch \(flightNumber) detail requested")
        return apiService.request(SpaceXApi.getOneLaunch(id: flightNumber), filter: Launch.filter)
            .asObservable()
            .map({ data in
                return Lce(loading: false, data: data)
            })
            .catchError({ error in
                return Observable.just(Lce(error: error))
            })
            .startWith(Lce<Launch>(loading: true, data: nil))
            .do(onNext: { event in
                if event.hasError {
                    log("Error: \(event.error!.localizedDescription)")
                }
                else if !event.loading {
                    log("Data received")
                }
            })
    }
    
    private let apiService: ApiService
    private let cacheService: CacheService
}
