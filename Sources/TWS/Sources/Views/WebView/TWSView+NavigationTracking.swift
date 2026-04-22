//
//  TWSView+NavigationTracking.swift
//  TWS
//
//  Created by Sven Kotnik on 22. 4. 26.
//

import Foundation
import WebKit

extension WebView {
    func shouldCancelNavigation(webView: WKWebView, coordinator: WebView.Coordinator) -> Bool {
        if navigationEventHandler.navigationEvent.isIdle() {
            return false
        }
        
        if state.currentUrl == navigationEventHandler.getNavigationEvent().getSourceURL() ||
            navigationEventHandler.getNavigationEvent().isNativeLoad() ||
            navigationEventHandler.getNavigationEvent().isSPA()
        {
            return false
        }
        
        self.cancelNavigation(coordinator: coordinator)
        updateState(for: webView, loadingState: .loaded)
        return true
    }
    
    func cancelNavigation(coordinator: WebView.Coordinator) {
        if !navigationEventHandler.didStartLoading() {
            
            self.contentProvider.cancelContentLoad()
            coordinator.pullToRefresh.cancelRefresh()
            navigationEventHandler.cancelNavigationEvent()
        }
    }
    
    func setNavigationEvent(_ event: TWSNavigationEvent) {
        DispatchQueue.main.async {
            navigationEventHandler.setNavigationEvent(navigationEvent: event)
        }
    }
    
    func setNavigationRequest(_ navigation: WKNavigation) {
        DispatchQueue.main.async {
            getNavigationEvent().setNavigation(navigation)
        }
    }
        
    func setNavigationRequest(_ navigation: WKNavigation?, coordinator: WebView.Coordinator, isPullToRefresh: Bool = false) {
            DispatchQueue.main.async {
                self.getNavigationEvent().setNavigation(navigation)
                if isPullToRefresh {
                    coordinator.pullToRefresh.setNavigationRequest()
                }
            }
        }
    
    func handleError(for webview: WKWebView, using coordinator: WebView.Coordinator, error: Error) {
        cancelNavigation(coordinator: coordinator)
        updateState(for: webview, loadingState: .failed(error))
    }
    
    func getNavigationEvent() -> TWSNavigationEvent {
        navigationEventHandler.getNavigationEvent()
    }
}
