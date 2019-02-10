//

import Foundation
import RxSwift
import RxCocoa

enum StorageKey: String {
    case sortKey
}

class ListViewModel: ViewModelType {
    struct Input {
        let requestLaunches: Signal<Bool>
    }
    
    struct Output {
        let launches: Signal<Lce<[LaunchPreview]>>
    }
    
    init(dataService: DataService) {
        self.dataService = dataService
        
        let storedSortKey = UserDefaults.standard.string(forKey: StorageKey.sortKey.rawValue)
        let parsedSortKey = storedSortKey != nil ? LaunchesSortKey(rawValue: storedSortKey!) : nil
        sortKey = parsedSortKey ?? .launchDate
    }

    @discardableResult
    func transform(input: Input) -> Output {
        let requestSortedLaunches = input.requestLaunches.asObservable()
            .map({ [weak self] request -> (Bool, SortingParams) in
                let sortingParams = getSortingParams(for: self?.sortKey ?? .launchDate)
                return (request, sortingParams)
            })

        let launches = dataService.getLaunches(requestSortedLaunches).asSignal { error in
            return Signal.just(Lce<[LaunchPreview]>(error: error))
        }
        
        output = Output(launches: launches)
        
        return output!
    }
    
    var output: Output? = nil
    
    var sortKey = LaunchesSortKey.launchDate {
        didSet {
            if oldValue != sortKey {
                UserDefaults.standard.set(sortKey.rawValue, forKey: StorageKey.sortKey.rawValue)
            }
        }
    }
    
    private var dataService: DataService
}
