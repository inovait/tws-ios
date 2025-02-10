# Getting Started

Learn how to integrate TWS into your project, turn your webpage into a native app, and start building your first application with code snippets.

## Adding the TWS as a dependency

### Integrate TWS with SPM

1. **Add package dependency**

    * Open your Xcode project and navigate navigate to File -> Add Package Dependencies...
    * Add a dependency to [TWS repository](https://github.com/inovait/tws-ios)
    * Set up a dependency rule to the version you want to include.
    * Add a target and add the package

2. **Resolve package versions**

    Download should start immediately, but you can also navigate to File -> Packages -> Resolve package versions to ensure the correct version is downloaded.

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
            HomeView()
        }
        // 2. Inject the ``TWSManager`` into the view hierarchy
        .twsEnable(configuration: TWSBasicConfiguration(
            id: "<PROJECT_ID>"
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

> Note: It's important to ensure that the instance of the ``TWSManager`` remains alive. If you use the SwiftUI extensions ``SwiftUICore/View/twsEnable(configuration:)``, the manager will stay alive as long as the view exists. Alternatively, you can use ``TWSFactory/new(with:)`` to create an instance and inject it into the view via ``SwiftUICore/View/twsEnable(using:)``. Keep in mind that creating a new ``TWSManager`` with the same configuration will not produce a new instance but will instead return a shared one.
