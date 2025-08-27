//
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

@MainActor
protocol TWSViewNavigatorDelegate: AnyObject, Sendable {

    func load(url: URLRequest, behaveAsSpa: Bool)
    func navigateBack()
    func navigateForward()
    func reload()
    func pushState(path: String)
    func replaceState(path: String)
    func evaluateJavaScript(script: String, completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)?)
}

/// A class that handles navigation actions such as navigating to a certain URL programmatically, going back, going forward, or reloading within a ``TWSView``.
///
/// This class enables performing navigation actions while observing the ability to navigate backward or forward in the view hierarchy.
///
/// Use the ``SwiftUICore/View/twsBind(navigator:)`` to bind the navigator to the specific ``TWSView`` and use the exposed methods, such as `goBack`, etc. to control it.
///
/// ```swift
/// private struct SomeView: View {
///
///     @State private var navigator = TWSViewNavigator()
///     let snippet: TWSSnippet
///
///     var body: some View {
///         VStack(alignment: .leading) {
///             HStack {
///                 Button {
///                     navigator.pushState(path: "/home")
///                 } label: {
///                      Text("Home")
///                 }
///
///                 Button {
///                     navigator.goBack()
///                 } label: {
///                     Image(systemName: "arrowshape.backward.fill")
///                 }
///                 .disabled(!navigator.canGoBack)
///
///                 Button {
///                     navigator.goForward()
///                 } label: {
///                     Image(systemName: "arrowshape.forward.fill")
///                 }
///                 .disabled(!navigator.canGoForward)
///
///                 Button {
///                     navigator.reload()
///                 } label: {
///                     Image(systemName: "repeat")
///                 }
///             }
///
///             Divider()
///
///             TWSView(snippet: snippet)
///         }
///         // Bind the navigator to the view
///         .twsBind(navigator: navigator)
///     }
/// }
/// ```
@MainActor
@Observable
public class TWSViewNavigator: Sendable {

    /// Indicates whether the view can navigate back.
    public internal(set) var canGoBack = false

    /// Indicates whether the view can navigate forward.
    public internal(set) var canGoForward = false
    weak var delegate: TWSViewNavigatorDelegate?

    /// Initializes a new `TWSViewNavigator` instance.
    ///
    /// The initializer is nonisolated to allow its creation in non-main-thread contexts.
    nonisolated public init() { }

    /// Triggers the delegate to navigate back if possible.
    public func goBack() {
        delegate?.navigateBack()
    }

    /// Triggers the delegate to navigate forward if possible.
    public func goForward() {
        delegate?.navigateForward()
    }

    /// Triggers the delegate to reload the current view.
    public func reload() {
        delegate?.reload()
    }
    
    /// Triggers the delegate to inject pushState JavaScript into webView.
    /// Used for navigating SPA web page, by pushing a new history entry to the history stack.
    public func pushState(path: String) {
        delegate?.pushState(path: path)
    }
    
    /// Triggers the delegate to inject replaceState JavaScript into webView.
    /// Used for navigating SPA web page, by modifying the current history entry of the history stack.
    public func replaceState(path: String) {
        delegate?.replaceState(path: path)
    }
    
    /// Triggers the delegate to inject custom JavaScript into webView, completion handler is an optional parameter that allows for handling success and error of the executed JavaScript.
    public func evaluateJavascript(script: String, completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil) {
        delegate?.evaluateJavaScript(script: script, completionHandler: completionHandler)
    }
    
    /// Triggers the delegate to load specified url into the webView.
    /// Parameter behaveAsSpa is provided as a helper, if there is a need to differenciate between
    /// MPA and SPA loads.
    /// > Note: If you do not need to actually load content it is prefered to use pushState/replaceState methods.
    public func load(url: URLRequest, behaveAsSpa: Bool = false) {
        delegate?.load(url: url, behaveAsSpa: behaveAsSpa)
    }
}
