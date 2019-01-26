import UIKit

enum Storyboards: String {
    case main = "Main"
    case list = "List"
    case detail = "Detail"
}

class MainFlowController: FlowController {
    
    init(_ window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let navCtrl = UIStoryboard(name: Storyboards.main.rawValue, bundle: nil).instantiateInitialViewController() as! UINavigationController
        window.rootViewController = navCtrl
        window.makeKeyAndVisible()
        let listScreen = UIStoryboard(name: Storyboards.list.rawValue, bundle: nil).instantiateInitialViewController() as! ListTableViewController
        listScreen.flowDelegate = self
        navCtrl.pushViewController(listScreen, animated: false)
    }
    
    private var window: UIWindow
}

extension MainFlowController: ListFlowDelegate {
    func showDetail(withId id: Int) {
        let detailScreen = UIStoryboard(name: Storyboards.detail.rawValue, bundle: nil).instantiateInitialViewController()!
        if let navCtrl = window.rootViewController as? UINavigationController {
            navCtrl.pushViewController(detailScreen, animated: true)
        }
    }
}
