# Getting Started

Learn how to integrate TWS into your project, turn your webpage into a native app, and start building your first application with code snippets.

## Adding the TWS as a dependency

> Note: Currently, TWS does not support integration via Swift Package Manager (SPM). However, SPM support is in development and will be added in a future release. Stay tuned for updates!

### Integrate TWS as XCFramework

1. **Download the frameworks**

    Download both `TWS.xcframework` adn `TWSModels.xcframework` from this [link](https://spotlight.inova.si/the-web-snippet/builds/iOS%20Release?shared=TBDa6YTvbeZCKd4ruAL7CBfBkM8)

2. **Add the frameworks to your project**

    * Open your Xcode project and navigate to your app's target settings
    * Under the `General`, scroll to the `Frameworks, Libraries, and Embedded Content` section
    * Click the `+` button and select `Add other...` -> `Add files...`
    * Choose both `TWS.xcframework` and `TWSModels.xcframework` and click `Add`

3. **Embed the frameworks**

    After adding the frameworks, ensure they are listed under the Embed Frameworks section with the option Embed & Sign enabled. This ensures that the frameworks are correctly included in your app bundle.

4. **Verify integration**

    Clean and build your project (Cmd + Shift + K and then Cmd + B) to ensure the frameworks are integrated correctly. Check for any build errors related to missing frameworks or incorrect embedding settings.

## Displaying your first snippet

> Note: This guide assumes that you already have an organization with projects and other necessary setups in place. The focus here is on integrating TWS into your app to leverage its capabilities.

To enable snippet management functionality at application startup, call ``SwiftUICore/View/twsEnable(configuration:)``. This initializes a ``TWSManager`` object under the hood, which fetches snippets, establishes a WebSocket connection, and notifies users about new or updated snippets, among other features. The manager is automatically injected into the environment, allowing seamless access throughout your app.

```swift
import SwiftUI
// 1. Import the TWS module
import TWS

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, world!")
        }
        // 2. Inject the ``TWSManager`` into the view hierarchy
        .twsEnable(configuration: .init(
            organizationID: "<ORGANIZATION_ID>",
            projectID: "<PROJECT_ID>"
        ))
    }
}
```

To access the snippets in any of the ancestor views, you can use an environment to retrieve the value from the view hierarchy. Then, use a TWSView to display them in the UI.

```swift
import SwiftUI
// 1. Import the TWS module
import TWS

struct HomeView: View {

    @Environment(TWSManager.self) var twsManager

    var body: some View {
        TabView {
            // 2. Loop over the snippets and show them
            ForEach(twsManager.snippets()) { snippet in
                TWSView(snippet: snippet)
            }
        }
    }
}
```

> Note: It's important to ensure that the instance of the ``TWSManager`` remains alive. If you use one of the SwiftUI extensions, such as ``SwiftUICore/View/twsEnable(configuration:)`` or ``SwiftUICore/View/twsEnable(sharedSnippet:)``, the manager will stay alive as long as the view exists. Alternatively, you can use ``TWSFactory/new(with:)-7y9q7`` or ``TWSFactory/new(with:)-7u4v8`` to create an instance and inject it into the view via ``SwiftUICore/View/twsEnable(using:)``. Keep in mind that creating a new ``TWSManager`` with the same configuration will not produce a new instance but will instead return a shared one.
