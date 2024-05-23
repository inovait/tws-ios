import SwiftUI
import Firebase
import TWSCore
import ComposableArchitecture

class AppDelegate: NSObject, UIApplicationDelegate {

    let store = Store(
        initialState: TWSCoreFeature.State(
            settings: .init(counter: 1000),
            snippet: .init(counter: 1)
        ),
        reducer: { TWSCoreFeature() }
    )

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

    var body: some Scene {
        WindowGroup {
            // Trigger build
            ContentView(store: delegate.store)
        }
    }
}

struct ContentView: View {

    let store: StoreOf<TWSCoreFeature>

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Hello world, from TWS")

            Spacer()

            HStack {
                Button("Increment") {
                    store.send(.settings(.increase))
                }

                Text("Settings counter: \(store.settings.counter)")

                Button("Decrement") {
                    store.send(.settings(.decrease))
                }
            }

            Spacer()

            HStack {
                Button("Increment") {
                    store.send(.snippet(.increase))
                }

                Text("Settings counter: \(store.snippet.counter)")

                Button("Decrement") {
                    store.send(.snippet(.decrease))
                }
            }

            Spacer()

            Text("v\(_appVersion())")
        }
        .padding()
    }
}

private func _appVersion() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    return "\(version) (\(build))"
}
