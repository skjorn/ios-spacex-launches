import UIKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        apiService = ApiService()
        cacheService = CacheService()
        dataService = DataService(apiService: apiService!, cacheService: cacheService!)
        
        let mainFlow = MainFlowController(window!, dataService: dataService!)
        mainFlow.start()
        
        startServices()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        startServices()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        dataService?.stop()
        cacheService?.stop()
        apiService?.stop()
    }

    var window: UIWindow?
    
    // MARK: - Private implementation
    
    private func startServices() {
        apiService?.start()
        cacheService?.start()
        dataService?.start()
    }
    
    private var apiService: ApiService? = nil
    private var cacheService: CacheService? = nil
    private var dataService: DataService? = nil
}
