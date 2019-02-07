//

import Foundation
import RxSwift
import RxCocoa

class ListViewModel: ViewModelType {
    struct Input {
        let requestLaunches: Signal<Bool>
    }
    
    struct Output {
        let launches: Signal<Lce<[LaunchPreview]>>
    }
    
    init(dataService: DataService) {
        self.dataService = dataService
    }

    @discardableResult
    func transform(input: Input) -> Output {
        let launches = dataService.getLaunches(input.requestLaunches.asObservable()).asSignal { error in
            return Signal.just(Lce<[LaunchPreview]>(error: error))
        }
        
        output = Output(launches: launches)
        
        return output!
    }
    
    var output: Output? = nil
    
    private var dataService: DataService
}
