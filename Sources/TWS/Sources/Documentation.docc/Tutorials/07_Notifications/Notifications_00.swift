import Foundation
import TWSNotifications

class ApplicationDelegate: UIApplicationDelegate {
    // ...
    
    // delegate method for handling background push notifications
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if TWSNotification().handleTWSPushNotification(userInfo) {
            return
        }
        
    }
    
    
    // ...
}
