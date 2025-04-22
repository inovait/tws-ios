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
    func handleUrl(_ url: URL) -> Bool {
        if url.absoluteString == "https://www.myWebPage.com/helloWorld" {
            return true
        } else if url.absoluteString.contains("https://www.myWebPage.com/greetUser/") {
            return true
        }
        return false
    }
}
