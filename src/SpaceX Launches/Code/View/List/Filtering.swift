//

import Foundation

func filterLaunches(_ launches: [LaunchPreview]?, searchTerm: String?) -> [LaunchPreview]? {
    guard let searchTerm = searchTerm, !searchTerm.isEmpty else {
        return launches
    }
    
    guard let launches = launches else {
        return nil
    }
    
    return launches.filter({
        $0.missionName.localizedCaseInsensitiveContains(searchTerm)
        || $0.launchSiteName.localizedCaseInsensitiveContains(searchTerm)
    })
}
