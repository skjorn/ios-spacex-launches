//

import Foundation
import RealmSwift

// MARK: - LaunchPreview

@objcMembers final class LaunchPreview: Object {
    dynamic var flightNumber: Int = 0
    dynamic var missionName: String = ""
    dynamic var launchDate: Date = Date()
    dynamic var launchSiteName: String = ""
    dynamic var missionPatchUrl: String = ""
    dynamic var rocketName: String = ""
    dynamic var launchSuccess: Bool = false

    enum CodingKeys: String, CodingKey, CaseIterable {
        case flight_number
        case mission_name
        case launch_date_unix
        case launch_site
        case links
        case rocket
        case launch_success
    }

    enum LaunchSiteCodingKeys: String, CodingKey, CaseIterable {
        case site_name
    }
    
    enum LinksCodingKeys: String, CodingKey, CaseIterable {
        case mission_patch_small
    }
    
    enum RocketCodingKeys: String, CodingKey, CaseIterable {
        case rocket_name
    }
    
    override static func primaryKey() -> String? {
        return "flight_number"
    }
}

extension LaunchPreview: Decodable {
    convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        flightNumber = try container.decode(Int.self, forKey: .flight_number)
        missionName = try container.decode(String.self, forKey: .mission_name)
        launchSuccess = try container.decode(Bool.self, forKey: .launch_success)
        
        let launchDateUnix = try container.decode(Double.self, forKey: .launch_date_unix)
        launchDate = Date(timeIntervalSince1970: launchDateUnix)
        
        let launchSiteContainer = try container.nestedContainer(keyedBy: LaunchSiteCodingKeys.self, forKey: .launch_site)
        launchSiteName = try launchSiteContainer.decode(String.self, forKey: .site_name)
        
        let linksContainer = try container.nestedContainer(keyedBy: LinksCodingKeys.self, forKey: .links)
        missionPatchUrl = try linksContainer.decode(String.self, forKey: .mission_patch_small)
        
        let rocketContainer = try container.nestedContainer(keyedBy: RocketCodingKeys.self, forKey: .rocket)
        rocketName = try rocketContainer.decode(String.self, forKey: .rocket_name)
    }
}

extension LaunchPreview: MaskedModel {
    static var codingKeys: [CodingKey] {
        return CodingKeys.allCases
    }
    
    static func childrenCodingKeys(for key: CodingKey) -> [CodingKey]? {
        switch key {
            
        case CodingKeys.launch_site:
            return LaunchSiteCodingKeys.allCases
            
        case CodingKeys.links:
            return LinksCodingKeys.allCases
            
        case CodingKeys.rocket:
            return RocketCodingKeys.allCases
            
        default:
            return nil
        }
    }
}

// MARK: - Launch

struct Launch: Decodable {
    var flightNumber: Int
    var missionName: String
    var missionPatchUrl: String
    var launchDate: Date
    var launchSiteName: String
    var launchSuccess: Bool
    var description: String
    var rocket: Rocket

    enum CodingKeys: String, CodingKey, CaseIterable {
        case flight_number
        case mission_name
        case launch_date_unix
        case launch_site
        case links
        case rocket
        case launch_success
        case details
    }
    
    enum LaunchSiteCodingKeys: String, CodingKey, CaseIterable {
        case site_name_long
    }
    
    enum LinksCodingKeys: String, CodingKey, CaseIterable {
        case mission_patch_small
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        flightNumber = try container.decode(Int.self, forKey: .flight_number)
        missionName = try container.decode(String.self, forKey: .mission_name)
        launchSuccess = try container.decode(Bool.self, forKey: .launch_success)
        description = (try? container.decode(String.self, forKey: .details)) ?? ""
        rocket = try container.decode(Rocket.self, forKey: .rocket)

        let launchDateUnix = try container.decode(Double.self, forKey: .launch_date_unix)
        launchDate = Date(timeIntervalSince1970: launchDateUnix)
        
        let launchSiteContainer = try container.nestedContainer(keyedBy: LaunchSiteCodingKeys.self, forKey: .launch_site)
        launchSiteName = try launchSiteContainer.decode(String.self, forKey: .site_name_long)
        
        let linksContainer = try container.nestedContainer(keyedBy: LinksCodingKeys.self, forKey: .links)
        missionPatchUrl = try linksContainer.decode(String.self, forKey: .mission_patch_small)
    }
}

extension Launch: MaskedModel {
    static var codingKeys: [CodingKey] {
        return CodingKeys.allCases
    }
    
    static func childrenCodingKeys(for key: CodingKey) -> [CodingKey]? {
        switch key {
            
        case CodingKeys.launch_site:
            return LaunchSiteCodingKeys.allCases
            
        case CodingKeys.links:
            return LinksCodingKeys.allCases
            
        case CodingKeys.rocket:
            return Rocket.codingKeys
            
        default:
            return Rocket.childrenCodingKeys(for: key)
        }
    }
}
