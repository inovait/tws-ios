# Stylings and customizations

Discover how to customize TWS to align with your app’s design and functionality by tailoring services and views for a seamless user experience.

## Overview

Customizing TWS allows you to create a more seamless and personalized experience for your users. In this article, we’ll explore how you can tailor various aspects of TWS, from handling permissions and navigation to designing custom views for loading, errors, and preloading states. You’ll also learn how to manage location services, integrate custom camera and microphone functionality, and handle download completions effectively. By leveraging these customization options, you can ensure that TWS aligns perfectly with your app’s design and functionality while delivering a polished and intuitive user experience.


## 1. Custom views

Custom views allow you to replace default TWS visuals with your own designs, ensuring your app delivers a consistent and branded user experience. Whether it's a loading spinner, an error message, or a placeholder during preloading, custom views provide flexibility to match your app's style and functionality.

> Note: All custom views use `AnyView` for type erasure, ensuring flexibility by allowing different view hierarchies to be returned.
>
>   The performance impact is negligible, as the loaded views are simple and lightweight.

### 1.1 Loading View

Use ``SwiftUICore/View/twsBind(loadingView:)`` to replace the view that is shown during loading of the snippet.

> Note: Overriding this will affect all descendant views.

```swift
ZStack {
    ...
}
.twsBind(loadingView: {
    AnyView(
        ProgressView {
            Text("Loading...")
        }
    )
})
```

### 1.2 Preloading View

Use ``SwiftUICore/View/twsBind(preloadingView:)`` to replace the view that is shown while the HTML resources are being preloaded before being displayed in the web view.

> Note: For most use cases, it is recommended to keep `loadingView` and `preloadingView` in sync to ensure a consistent user experience.
>
>   Overriding this will affect all descendant views.

```swift
ZStack {
    ...
}
.twsBind(preloadingView: {
    AnyView(
        ProgressView {
            Text("Preloading...")
        }
    )
})
```

### 1.3 Error View

Use ``SwiftUICore/View/twsBind(errorView:)`` to replace the view that is shown when an error occurs while loading the snippet or its resources.

> Note: Overriding this will affect all descendant views.

```swift
ZStack {
    ...
}
.twsBind(errorView: { error in
    AnyView(
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("An error occurred: \(error)")
        }
    )
})
```

## 2. Extending TWSView Functionality

Custom TWSView handling allows for extending the default behavior by adding features such as managing navigation actions (e.g., going back and forward) and intercepting web requests. This enables greater control over the browsing experience, allowing you to customize how content is loaded, managed, and interacted with. The flexibility of this approach ensures that additional functionalities can be seamlessly incorporated as your needs evolve.

### 2.1 Navigation

Use the following extension to add custom navigation functionality to your TWSView, such as going back, going forward, and reloading the view.

> Note: Overriding this will affect all descendant views.

```swift
struct SnippetView: View {

    let snippet: TWSSnippet
    @State private var navigator = TWSViewNavigator() // 👈

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    navigator.goBack()
                } label: {
                    Image(systemName: "arrowshape.backward.fill")
                }
                .disabled(!navigator.canGoBack)

                Button {
                    navigator.goForward()
                } label: {
                    Image(systemName: "arrowshape.forward.fill")
                }
                .disabled(!navigator.canGoForward)

                Button {
                    navigator.reload()
                } label: {
                    Image(systemName: "repeat")
                }
            }

            Divider()

            TWSView(
                snippet: snippet
            )
        }
        .twsBind(navigator: navigator)  // 👈
    }
}
```

### 2.2 URL Interceptor

The ``TWSViewInterceptor`` protocol provides an interface for intercepting and handling URL navigation within a ``TWSView``. It allows you to implement custom behavior for URL handling, giving you full control over what URLs should be loaded by the web view or handled natively within your application.

> Note: Overriding this will affect all descendant views.

#### Key Features
- Prevent the web view from loading specific URLs
- Handle navigation natively for custom schemes, domains, or specific paths
- Enhance user experience by seamlessly integrating native features

> Note: Returning `true` from the `handleIntercept(_:)` method will prevent the web view from loading the intercepted URL.

#### Usage

You can provide a custom implementation of this protocol and inject it into the ``TWSView`` using the appropriate configuration or environment modifier.

### Example

```swift
final class CustomInterceptor: TWSViewInterceptor {
    func handleIntercept(_ intercept: handleIntercepted) -> Bool {
        switch intercept {

        // Intercepted MPA loads
        case .url(let url):
            if url.host == "native.example.com" {
                // Handle URL natively
                print("Intercepted and handled natively: \(url)")
                return true
            }
            // Allow other URLs to load in the web view
            return false

        // Intercepted SPA navigation
        case .path(let path):
            if path == "/example" {
                print("Intercepted and handled natively: \(path)")
                return true
            }
            return false
        }
        
    }
}

struct ContentView: View {
    var body: some View {
        TWSView()
            .twsBind(interceptor: CustomInterceptor())
    }
}
```

## 3. Services Integration

Custom services such as location, microphone, and camera can be seamlessly integrated into your TWSView to enhance the user experience. By adding these services, you can enable native functionality within your web content, allowing for a more interactive and personalized experience. This flexibility ensures that you can customize and extend the capabilities of your TWSView as needed, providing a richer, more native-like experience.

## Location services

To integrate location services into your TWSView, conform to the ``LocationServicesBridge`` protocol, which enables communication between the native iOS environment and the JavaScript running inside the web view. By implementing this protocol, you can handle location permissions, retrieve the current position, and manage continuous location updates. This provides a seamless way to access and control location-based data while ensuring that permissions are properly managed.

> Note: Overriding this will affect all descendant views.
>
> Default implementation is already provided.

To use your custom location services, simply inject your implementation using the ``TWSView/twsBind(locationServiceBridge:)`` helper function, which binds the service to the TWSView and makes it available for interaction.

By adopting the LocationServicesBridge protocol, you gain fine-grained control over location data, allowing you to customize how location information is retrieved and managed within your TWSView environment.

#### Usage

```swift
ZStack {

}
.twsBind(
    locationServiceBridge: ... // 👈 An implemantation, confirming to `LocationServicesBridge`
)
```

## Camera and Microphone Services

To integrate camera and microphone services into your TWSView, conform to the ``CameraMicrophoneServicesBridge`` protocol, which enables communication between the native iOS environment and the JavaScript running inside the web view. This protocol facilitates the management of camera and microphone permissions and provides a straightforward interface for controlling these services.

By implementing this protocol, you can check the status of camera and microphone permissions and handle any permission-related issues before interacting with these devices, ensuring smooth and secure access to camera and microphone functionality within the TWSView.

> Note: Overriding this will affect all descendant views.
>
> Default implementation is already provided.

To use your custom camera and microphone services, inject your implementation using the ``SwiftUICore/View/twsBind(cameraMicrophoneServiceBridge:)`` helper function, which binds the service to the TWSView and makes it available for interaction with the JavaScript code.

Adopting the ``CameraMicrophoneServicesBridge`` protocol allows you to gain fine-grained control over camera and microphone access, ensuring that permissions are handled correctly and users are provided with the appropriate interactions for these native services.

#### Usage

```swift
ZStack {
    // Your view content
}
.twsBind(
    cameraMicrophoneServiceBridge: ... // 👈 An implementation confirming to `CameraMicrophoneServicesBridge`
)
```
