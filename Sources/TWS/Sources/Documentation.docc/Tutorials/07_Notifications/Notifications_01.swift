import SwiftUI
import TWS

struct App: App {
    @State var manager = TWSFactory.new(with: TWSBasicConfiguration(id: "projectId"))
    @UIApplicationDelegateAdaptor(ApplicationDelegate.self) var applicationDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .twsRegister(using: manager)
        }
    }
}
