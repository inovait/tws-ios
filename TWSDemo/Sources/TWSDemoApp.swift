import SwiftUI
import Firebase
import TWSKit
import TWSModels

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TWSDemoApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var twsViewModel = TWSViewModel()

    init() {
        print("-> on init called", Date())
    }

    var body: some Scene {
        WindowGroup {
            if NSClassFromString("XCTestCase") == nil {
                ContentView()
                    .environment(twsViewModel)
                    .onAppear {
                        print("-> on appear called", Date())
                    }
                    .task {
                        print("-> on task called", Date())
                        for await snippets in twsViewModel.manager.stream {
                            print("-> received now \(snippets.count)", Date())
                            self.twsViewModel.snippets = snippets
                        }
                    }
            }
        }
    }
}
