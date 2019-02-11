//

import Foundation
import Moya

let BASE_URL = "https://api.spacexdata.com"

enum SpaceXApi {
    case getPastLaunches
    case getOneLaunch(id: Int)
}

struct SpaceXApiTarget {
    var token: SpaceXApi
    var filter: String? = nil
}

extension SpaceXApiTarget: TargetType {
    var baseURL: URL { return URL(string: "\(BASE_URL)")! }
    
    var path: String {
        switch token {
        case .getPastLaunches:
            return "/v3/launches/past"
        case .getOneLaunch(let id):
            return "/v3/launches/\(id)"
        }
    }
    
    var method: Moya.Method {
        switch token {
        default:
            return .get
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var task: Task {
        if let filter = filter {
            return .requestParameters(parameters: ["filter" : filter], encoding: URLEncoding.default)
        }
        else {
            return .requestPlain
        }
    }
    
    var sampleData: Data {
        switch token {
        case .getPastLaunches:
            return "[]".utf8Encoded
        case .getOneLaunch:
            return "{}".utf8Encoded
        }
    }
    
    var validationType: ValidationType {
        return .successCodes
    }
}
