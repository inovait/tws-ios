# The Web Snippet

TWS SDK is a library, designed to make it easier and more powerful to add a web content to your iOS apps, with a WebView on steroids. You can use it to combine web and native features, add web pages to an existing app, build a complete app using web content, or mix web and native screens for a smoother user experience.

## Installation

The Web Snippet is available as a SPM package. To include it in your project navigate to `File > Add package dependencies...` and search for this repository in your Xcode.
Select the desired version and add package.

## Usage

To include TWS in your application you need to import TWS library.

### Load snippets locally

Define your snippet with ID and target URL and you are set to display it.
You can also add other properties such as headers, custom json properties and attachments such as javaScript or CSS scripts.

```swift
import SwiftUI
import TWS

struct HomeScreen: View {
    let myWebPage: TWSSnippet = TWSSnippet(id: "mySnippetId", target: URL(string: "https://www.google.com")!)
    
    var body: some View {
        TWSView(snippet: myWebPage)
    }
}
```

### Fetch snippets remotely

Sign up to [TWS Portal](https://thewebsnippet.com), create a project and your snippets. There you can download your tws-service.json.
Insert a valid tws-service.json into your project and provide a project ID.

```swift
import SwiftUI
import TWS

struct ContentView: View {
    
    var body: some View {
        HomeScreen()
        .twsRegister(configuration: TWSBasicConfiguration(id: "myProjectId"))
    }
    
}

```

This creates an instance of TWSManager, registers it with remote services and injects it into the environment, which handles your remote snippets.
It handles fetching snippets, socket connection, caching and more.

> Note: You can create an instance manually using TWSFactoy.new(with:), however you have to register it yourself by calling registerManager() on your instance and you have manually manage that your instance survives.

Retrieve the manager in any ancestor view and use TWSView to display your snippets.

```swift
import SwiftUI
import TWS

struct HomeScreen: View {
    @Environment(TWSManager.self) var tws
    
    var body: some View {
        TabView {
            ForEach(tws.snippets()) { snippet in 
                TWSView(snippet: snippet)
            }
        }
    }
}
```

### Bind native views and flow handlers to your TWSView:

* `twsBind(loadingView:)` - View displayed while the URL is loading
* `twsBind(preloadingView:)` - View displayed while the attachments like HTML, CSS and Javascript are being preloaded
* `twsBind(errorView:)` - View displayed if the error occurs during the loading
* `twsBind(navigator:)` - Navigator implementation for navigating between URLs in the same TWSView (Default is provided)
* `twsBind(interceptor:)` - Custom interceptor implementation for incoming URL requests (Default is provided)

## Contributing

To contribute to this library: 

1. Checkout `develop`

2. Create a new branch and start developing

3. Commit your work. While commiting, use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)

4. Run test manually
    * in Xcode Product > Test or 
    * from terminal `xcodebuild test -workspace 'TheWebSnippet.xcworkspace' -scheme Sample -destination 'platform=iOS SIMULATOR,name=iPhone 16,OS=18.1'`


## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## See also

For more infomation check out our:
* [Documentation](https://inovait.github.io/tws-ios)
* [Web Portal](https://thewebsnippet.com)

