//

import UIKit

enum Storyboards: String {
    case main = "Main"
    case list = "List"
    case detail = "Detail"
}

let ERROR_DELAY = 5.0 // seconds

class MainFlowController: FlowController {
    init(_ window: UIWindow, dataService: DataService) {
        self.window = window
        self.dataService = dataService
    }
    
    func start() {
        let navCtrl = UIStoryboard(name: Storyboards.main.rawValue, bundle: nil).instantiateInitialViewController() as! UINavigationController
        window.rootViewController = navCtrl
        window.makeKeyAndVisible()
        
        let listScreen = UIStoryboard(name: Storyboards.list.rawValue, bundle: nil).instantiateInitialViewController() as! ListTableViewController
        listScreen.flowDelegate = self
        listScreen.viewModel = ListViewModel(dataService: dataService)
        navCtrl.pushViewController(listScreen, animated: false)
    }
    
    // MARK: - Private implementation
    
    private var window: UIWindow
    private var dataService: DataService
    private var errorTimer: Timer? = nil
}

extension MainFlowController: ListFlowDelegate {
    func showDetail(withId id: Int) {
        let detailScreen = UIStoryboard(name: Storyboards.detail.rawValue, bundle: nil).instantiateInitialViewController() as! DetailViewController
        detailScreen.viewModel = DetailViewModel(flightNumber: id, dataService: dataService)
        if let navCtrl = window.rootViewController as? UINavigationController {
            navCtrl.pushViewController(detailScreen, animated: true)
        }
    }
    
    func showError(message: String) {
        if let errorTimer = errorTimer {
            errorTimer.invalidate()
            self.errorTimer = nil
        }
        
        if let navCtrl = window.rootViewController as? UINavigationController {
            let errorView = UIView.loadFromNib(named: ErrorView.nameOfClass) as! ErrorView
            errorView.configure(message: message)
            
            let items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(customView: errorView),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            ]
            navCtrl.visibleViewController?.setToolbarItems(items, animated: false)
            navCtrl.setToolbarHidden(false, animated: true)
            
            // Hide message after a delay
            
            errorTimer = Timer.scheduledTimer(withTimeInterval: ERROR_DELAY, repeats: false) { [weak navCtrl, weak self] timer in
                self?.errorTimer = nil
                navCtrl?.setToolbarHidden(true, animated: true)
            }
        }
    }
}
