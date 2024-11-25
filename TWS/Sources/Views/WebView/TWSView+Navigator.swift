//
//  TWSView+Navigator.swift
//  TWS
//
//  Created by Miha Hozjan on 13. 11. 24.
//  Copyright © 2024 Inova IT, d.o.o. All rights reserved.
//

import SwiftUI

@MainActor
protocol TWSViewNavigatorDelegate: AnyObject, Sendable {

    func navigateBack()
    func navigateForward()
    func reload()
}

/// A class that handles navigation actions such as going back, going forward, or reloading within a ``TWSView``.
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
}
