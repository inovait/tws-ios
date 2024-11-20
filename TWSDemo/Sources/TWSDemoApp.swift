import SwiftUI
import Firebase
import TWS
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
                        organizationID: "inova.tws",
                        projectID: "4166c981-56ae-4007-bc93-28875e6a2ca5"
                    ))
                    .twsBind(preloadingView: {
                        AnyView(Text("Preloading..."))
                    })
                    .environment(twsViewModel)
                    .task {
                        await twsViewModel.startupInitTasks()
                    }
            }
        }
    }
}
