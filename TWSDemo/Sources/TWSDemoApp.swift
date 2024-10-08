import SwiftUI
import Firebase
import TWSKit
#if DEBUG
import Atlantis
#endif

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        #if DEBUG
        Atlantis.start(hostName: "mihas-macbook-pro-6.local.")
        #endif
        return true
    }
}

@main
struct TWSDemoApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var twsViewModel = TWSViewModel()
    @State private var locationProvider = TWSDefaultLocationServicesManager()
    @State private var cameraMicrophoneProvider = TWSCameraMicrophoneServiceManager()

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") == nil {
                ContentView()
                    .environment(twsViewModel)
                    .environment(locationProvider)
                    .environment(cameraMicrophoneProvider)
                    .task {
                        await twsViewModel.start()
                        await twsViewModel.startupInitTasks()
                    }
            }
        }
    }
    
}
