//

import Foundation

enum LaunchesSortKey: String {
    case launchDate
    case launchSite
    case rocketName
    case launchStatus
}

func sortLaunches(for key: LaunchesSortKey, using data: [LaunchPreview]) -> [ListTableSectionModel] {
    switch key {
        
    case .launchDate:
        return sortLaunchesByDate(data)
        
    case .launchSite:
        return sortLaunchesBySite(data)
        
    case .rocketName:
        return sortLaunchesByRocketName(data)
        
    case .launchStatus:
        return sortLaunchesByStatus(data)
    }
}

typealias SortingParams = (primaryKey: String, secondaryKey: String?, ascending: Bool)

func getSortingParams(for key: LaunchesSortKey) -> SortingParams {
    switch key {
        
    case .launchDate:
        return (primaryKey: "launchDate", secondaryKey: nil, ascending: false)
        
    case .launchSite:
        return (primaryKey: "launchSiteName", secondaryKey: "flightNumber", ascending: true)
        
    case .rocketName:
        return (primaryKey: "rocketName", secondaryKey: "flightNumber", ascending: true)
        
    case .launchStatus:
        return (primaryKey: "launchSuccess", secondaryKey: "flightNumber", ascending: true)
    }
}

// MARK: - Private implementation

fileprivate func sortLaunchesByDate(_ data: [LaunchPreview]) -> [ListTableSectionModel] {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    
    return sortLaunches(
        data,
        withSectionKey: { calendar.component(.year, from: $0.launchDate) },
        withSectionTitle: { _, key in "\(key)" }
    )
}

fileprivate func sortLaunchesBySite(_ data: [LaunchPreview]) -> [ListTableSectionModel] {
    return sortLaunches(data, withSectionKey: { $0.launchSiteName }, withSectionTitle: { lp, _ in "\(lp.launchSiteName)" })
}

fileprivate func sortLaunchesByRocketName(_ data: [LaunchPreview]) -> [ListTableSectionModel] {
    return sortLaunches(data, withSectionKey: { $0.rocketName }, withSectionTitle: { lp, _ in "\(lp.rocketName)" })
}

fileprivate func sortLaunchesByStatus(_ data: [LaunchPreview]) -> [ListTableSectionModel] {
    return sortLaunches(
        data,
        withSectionKey: { $0.launchSuccess },
        withSectionTitle: { lp, _ in "\(lp.launchSuccess ? "Success" : "Failure")" }
    )
}

fileprivate func sortLaunches<Key: Equatable>(
    _ data: [LaunchPreview],
    withSectionKey keyProvider: (LaunchPreview) -> Key,
    withSectionTitle titleProvider: (LaunchPreview, Key) -> String
) -> [ListTableSectionModel] {
    var result: [ListTableSectionModel] = []
    var lastKey: Key? = nil
    var section: ListTableSectionModel! = nil
    
    for launchPreview in data {
        let key = keyProvider(launchPreview)
        if key != lastKey {
            if let section = section {
                result.append(section)
            }
            
            section = ListTableSectionModel(header: "\(titleProvider(launchPreview, key))", items: [])
            lastKey = key
        }
        
        section.items.append(launchPreview)
    }
    
    if let section = section {
        result.append(section)
    }
    
    return result
}
