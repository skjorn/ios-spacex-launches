//

import Foundation
import Moya
import RxSwift

class ApiService: Service {
    func start() {
        provider = MoyaProvider()
    }
    
    func stop() {
        provider = nil
    }
    
    func request<ResultType: Decodable>(_ token: SpaceXApi, filter: String? = nil) -> Single<ResultType> {
        guard let provider = provider else {
            return Single<ResultType>.error(ServiceError.serviceStopped)
        }
        
        return provider.rx.request(SpaceXApiTarget(token: token, filter: filter))
            .flatMap({ response in
                return Single<ResultType>.create { single in
                    do {
                        let parsedData = try response.map(ResultType.self)
                        single(.success(parsedData))
                    }
                    catch {
                        single(.error(error))
                    }
                    
                    return Disposables.create()
                }
            })
    }
    
    // MARK: - Private implementation
    
    private var provider: MoyaProvider<SpaceXApiTarget>? = nil
}
