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

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") == nil {
                ContentView()
                    .twsEnable(configuration: .init(
                        organizationID: "e7e74ac1-786e-4439-bdcc-69e11685693c",
                        projectID: "9b992e03-a3ab-4d5a-9abb-4364bcc86559"
                    ))
                    .environment(twsViewModel)
                    .task {
                        await twsViewModel.start()
                        await twsViewModel.startupInitTasks()
                    }
            }
        }
    }
}
