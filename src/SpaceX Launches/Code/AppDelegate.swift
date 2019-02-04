import UIKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // A dispose bag for View that can be used for Observables active while the app is in the foreground.
    static private(set) var foregroundDisposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        apiService = ApiService()
        cacheService = CacheService()
        dataService = DataService(apiService: apiService!, cacheService: cacheService!)
        
        let mainFlow = MainFlowController(window!)
        mainFlow.start()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        apiService?.start()
        cacheService?.start()
        dataService?.start()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        dataService?.stop()
        cacheService?.stop()
        apiService?.stop()
        
        AppDelegate.foregroundDisposeBag = DisposeBag()
    }

    var window: UIWindow?
    
    private var apiService: ApiService? = nil
    private var cacheService: CacheService? = nil
    private var dataService: DataService? = nil
    
}
