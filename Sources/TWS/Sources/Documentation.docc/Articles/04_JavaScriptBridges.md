# JavaScript bridges

Understand how TWS passes messages between your web content and native iOS code, and how to add a bridge of your own.

## Overview

A web view cannot call Swift directly, and Swift cannot call into a page directly. WebKit provides two
one-way pipes instead, and every bridge in TWS is built from the same pair:

* **JS → native** — the page calls `window.webkit.messageHandlers.<channel>.postMessage(payload)`, and an
  object conforming to `WKScriptMessageHandler`, registered under that channel name, receives it.
* **native → JS** — Swift calls `evaluateJavaScript(_:)` to invoke a function the page has defined.

`postMessage` returns nothing, so a bridge that needs an answer cannot simply wait for one. Where TWS needs
a round trip it sends a request id along with the message and calls back into a JavaScript function with
that same id, letting the JS side match the response to the caller that is waiting for it.

Both halves are wired up in `makeUIView` on a single `WKUserContentController` shared by the web view: the
JavaScript side is injected as a `WKUserScript` at `.atDocumentStart` so it exists before any page code
runs, and the native side is registered with `add(_:name:)`.

## 1. Built-in bridges

### 1.1 `intercept` — SPA navigation

The only built-in channel with no injected script: the channel exists, and it is up to your web content to
use it. When a single-page app changes route without a page load, the page tells the host:

```js
window.webkit.messageHandlers.intercept.postMessage("/some/path")
```

`SPAInterceptorBridge` receives it and forwards it to your ``TWSViewInterceptor`` as
``TWSIntercepted/path(_:)``. The channel is registered only when an interceptor is bound to the view.

> Note: Unlike ``TWSIntercepted/url(_:navigationType:)``, the return value of `handleIntercept(_:)` is
discarded for `.path`. A full page load can be vetoed because the interceptor runs inside the navigation
policy decision; an SPA route change has already happened by the time JavaScript reports it, so `.path` is
a notification rather than a veto.

### 1.2 `locationHandler` — geolocation

The most complete bridge, and the best model to copy. The injected script replaces the standard
`navigator.geolocation` functions, so page code keeps using the ordinary Web API and never learns it is
talking to native code.

Each call mints a unique id, stores the page's `success` and `error` callbacks against it, and posts a JSON
payload:

```js
navigator.geolocation.getCurrentPosition = function(success, error, options) {
    const id = Date.now();
    locationCallbacks.set(id, { success, error });
    window.webkit.messageHandlers.locationHandler.postMessage(
        JSON.stringify({ id: id, command: "getCurrentPosition", options: options })
    );
};
```

Native decodes the payload, asks the bound `LocationServicesBridge` for a fix, and replies by calling one of
the functions the same script defined — `navigator.geolocation.iosLastLocation(id, lat, lon, …)`,
`iosWatchLocationDidUpdate(…)`, or their `…Failed` counterparts. The JS side looks the id up and invokes the
stored callback.

Two details are worth borrowing. The id is `Date.now()` rather than a counter, because several web views may
share one location provider and a per-view counter would collide. And the message handler itself holds no
state: it keeps a static list of `JavaScriptLocationAdapter` actors and broadcasts to them, because a message
handler is retained by the content controller and storing the web view on it would create a retain cycle.
The adapter holds the web view and the services bridge weakly.

### 1.3 `consoleLogHandler` — console forwarding

Compiled in `#if DEBUG` only. The injected script wraps `console.log`, `warn`, `info`, `error` and `debug`,
posts `{type, timestamp, args}` to the channel, then calls the original implementation so the browser console
still works. Native writes the result to the TWS log, which is how web console output reaches Xcode.

## 2. Native → JS without a channel

Not every native-to-web call needs a registered handler. ``TWSViewNavigator``'s
``TWSViewNavigator/pushState(path:)`` and ``TWSViewNavigator/replaceState(path:)`` are plain
`evaluateJavaScript` calls. They first feature-check the page:

```js
typeof window.navigateFromNative === 'function'
```

If your web content defines `navigateFromNative(path, { replace })`, TWS calls it and lets your router
handle the change. If not, it falls back to `history.pushState`/`replaceState` followed by a synthetic
`popstate` event. Defining `navigateFromNative` is preferable — the fallback works only for routers that
listen to `popstate`.

## 3. Lifecycle

Handlers are registered per web view in `makeUIView` and torn down in `dismantleUIView`, which calls
`removeAllScriptMessageHandlers()`. Note the "all": it clears channels you registered yourself alongside the
built-in ones.

A new web view — and therefore a fresh set of handlers — is created whenever the view's identity changes,
not once per app launch. Web views opened as popups through the `WKUIDelegate` are separate instances with
their own registrations.

## 4. Adding your own bridge

Use ``TWSView/init(snippet:state:overrides:overrideVisibilty:enablePullToRefresh:onCreate:)`` to get hold of
the `WKWebView` as it is created, then register a channel on its content controller:

```swift
final class GreetingBridge: NSObject, WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "greeting", let name = message.body as? String else { return }
        print("Hello, \(name)!")
    }
}

TWSView(snippet: snippet, onCreate: { webView in
    webView.configuration.userContentController.add(GreetingBridge(), name: "greeting")
})
```

If the channel needs a JavaScript counterpart, add it as a user script at the same time so it is in place
before page code runs:

```swift
webView.configuration.userContentController.addUserScript(
    WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
)
```

`onCreate` runs after TWS has registered its own channels and before the first content load, so user
scripts added here still apply to that load, and a channel name TWS already uses will fail loudly rather
than silently — `add(_:name:)` raises an exception on a duplicate name.

Three things to avoid. Do not reassign `navigationDelegate` or `uiDelegate` — TWS sets both to its own
coordinator and replacing either disables navigation handling, interception, downloads and permissions.
Do not load content, since the snippet's own first load follows immediately and will replace it. And
remember that `onCreate` runs for every web view the view creates, so a handler that registers external
state should tolerate being set up more than once.

## See Also

- <doc:01_Customizations>
