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
    
    func getLaunches(_ input: Observable<(Bool, SortingParams)>) -> Observable<Lce<[LaunchPreview]>> {
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
            .map({ (force: Bool, sortingParams: SortingParams) -> (Bool, SortingParams) in
                if force {
                    return (true, sortingParams)
                }
                else {
                    let cacheMeta = self.cacheService.select(object: CacheMeta.self, withId: CacheMeta.Id.default.rawValue)
                    log("Last cached: \(cacheMeta?.launchesTimestamp?.debugDescription ?? "never")")
                    let refreshCache = cacheMeta == nil
                        || cacheMeta!.launchesTimestamp == nil
                        || Date().timeIntervalSince(cacheMeta!.launchesTimestamp!) >= INVALIDATION_TIME
                    return (refreshCache, sortingParams)
                }
            })
            .share(replay: 0, scope: .forever)

        let noFetch = shouldFetch
            .filter({ !$0.0 })
            .map({ (_, sortingParams) -> Lce<[LaunchPreview]> in
                let cachedData = self.cacheService.selectAll(
                    ofType: LaunchPreview.self,
                    sortBy: sortingParams.primaryKey,
                    thenBy: sortingParams.secondaryKey,
                    ascending: sortingParams.ascending
                )
                return Lce(loading: false, data: cachedData)
            })
            .do(onNext: { _ in
                log("Cached launches returned")
                inProgress = false
            })
        
        let fetch = shouldFetch
            .filter({ $0.0 })
            .flatMap({ input in
                return self.apiService.request(.getPastLaunches, filter: LaunchPreview.filter).asObservable()
                    .map({ (result: [LaunchPreview]) -> (Lce<[LaunchPreview]>, SortingParams) in
                        return (Lce(loading: false, data: result), input.1)
                    })
                    .catchError({ error -> Observable<(Lce<[LaunchPreview]>, SortingParams)> in
                        return Observable.just((Lce(error: error), input.1))
                    })
                    .do(onNext: { result in
                        log("Fetching via API...")
                        if result.0.hasError {
                            log("Error: \(result.0.error!.localizedDescription)")
                        }
                        else {
                            log("\(result.0.data?.count ?? 0) items received")
                        }
                    })
                    .startWith({
                        let cachedData = self.cacheService.selectAll(
                            ofType: LaunchPreview.self,
                            sortBy: input.1.primaryKey,
                            thenBy: input.1.secondaryKey,
                            ascending: input.1.ascending
                        )
                        return (Lce(loading: true, data: cachedData), input.1)
                    }())
            })
            .share(replay: 0, scope: .forever)

        let noCache = fetch
            .filter({ $0.0.loading || $0.0.hasError })
            .map({ $0.0 })
            .do(onNext: { inProgress = $0.loading })

        let cache = fetch
            .filter({ !$0.0.loading && !$0.0.hasError })
            .flatMap({ result -> Observable<Lce<[LaunchPreview]>> in
                let sortingParams = result.1
                return self.cacheService.replaceAll(with: result.0.data!).asObservable()
                    .materialize()
                    .flatMap({ result -> Observable<Lce<[LaunchPreview]>> in
                        switch result {
                            
                        case .completed:
                            let cacheMeta = self.cacheService.select(object: CacheMeta.self, withId: CacheMeta.Id.default.rawValue) ?? CacheMeta()
                            cacheMeta.launchesTimestamp = Date()
                            
                            do {
                                try self.cacheService.add(object: cacheMeta)
                            }
                            catch {
                                return Observable.just(Lce(error: error))
                            }
                            
                            let data = self.cacheService.selectAll(
                                ofType: LaunchPreview.self,
                                sortBy: sortingParams.primaryKey,
                                thenBy: sortingParams.secondaryKey,
                                ascending: sortingParams.ascending
                            )
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
