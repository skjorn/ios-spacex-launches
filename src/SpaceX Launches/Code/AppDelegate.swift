import UIKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // A dispose bag for View that can be used for Observables active while the app is in the foreground.
    static private(set) var foregroundDisposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let mainFlow = MainFlowController(window!)
        mainFlow.start()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        AppDelegate.foregroundDisposeBag = DisposeBag()
    }

    var window: UIWindow?
    
}
