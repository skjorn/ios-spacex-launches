//

import Foundation
import Moya
import RxSwift

class ApiService {
    
    init() {
        provider = MoyaProvider()
    }
    
    func request<ResultType: Decodable>(_ token: SpaceXApi, filter: String? = nil) -> Single<ResultType> {
        return provider.rx.request(SpaceXApiTarget(token: token, filter: filter))
            .flatMap { response in
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
            }
    }
    
    private var provider: MoyaProvider<SpaceXApiTarget>
}
