//

import Foundation
import RxSwift
import RxCocoa

class DetailViewModel: ViewModelType {
    typealias Input = Void
    
    struct Output {
        let launchDetail: Signal<Lce<Launch>>
    }
    
    init(flightNumber: Int,  dataService: DataService) {
        self.flightNumber = flightNumber
        self.dataService = dataService
    }
    
    func transform(input: Input) -> Output {
        let launchDetail = dataService.getLaunchDetail(for: flightNumber).asSignal { error in
            return Signal.just(Lce<Launch>(error: error))
        }
        
        return Output(launchDetail: launchDetail)
    }
    
    private(set) var flightNumber: Int
    
    private var dataService: DataService
}
