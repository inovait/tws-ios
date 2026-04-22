//
//  ContentProviding.swift
//  TWS
//
//  Created by Sven Kotnik on 22. 4. 26.
//

import Foundation
import WebKit

@MainActor
protocol WebViewContentProviding {
    var wv: WebView { get }
    
    // Provides implementation for the load of the initial target url of the snippet
    func load(webView: WKWebView) -> WKNavigation?
    
    // Provides implementation for the load of the consecutive urls in to the web view
    func load(webView: WKWebView, coordinator: WebView.Coordinator, _ url: URLRequest, behaveAsSPA: Bool)
    
    // Reloads latest URL in webview
    func reload(webView: WKWebView, coordinator: WebView.Coordinator, isPullToRefresh: Bool)
    
    // Cancels the latest content load
    func cancelContentLoad()
}
