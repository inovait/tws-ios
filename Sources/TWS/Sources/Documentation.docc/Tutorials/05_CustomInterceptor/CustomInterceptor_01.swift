import Foundation
import SwiftUI
import TWS

struct CustomView: View {
    let mySnippet = TWSSnippet(id: "mySnippet", target: URL(string: "https://www.myWebPage.com")!)
    
    var body : some View {
        ZStack {
            TWSView(snippet: mySnippet)
                .twsBind(loadingView: { AnyView(LoadingView()) })
                .twsBind(preloadingView: { AnyView(LoadingView()) })
                .twsBind(errorView: { error in AnyView(ErrorView(error: error))})
        }
    }
}

class NavigationInterceptor: TWSViewInterceptor {
    func handleIntercept(_ intercept: TWSIntercepted) -> Bool {
        
    }
}
