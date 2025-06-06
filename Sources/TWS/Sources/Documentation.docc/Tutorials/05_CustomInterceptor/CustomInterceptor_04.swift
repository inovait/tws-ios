import Foundation
import SwiftUI
import TWS

struct CustomView: View {
    let mySnippet = TWSSnippet(id: "mySnippet", target: URL(string: "https://www.myWebPage.com")!)
    @State var navigationInterceptor = NavigationInterceptor()
    
    var body : some View {
        ZStack {
            TWSView(snippet: mySnippet)
                .twsBind(loadingView: { AnyView(LoadingView()) })
                .twsBind(preloadingView: { AnyView(LoadingView()) })
                .twsBind(errorView: { error in AnyView(ErrorView(error: error))})
                .twsBind(interceptor: NavigationInterceptor)
            switch navigationInterceptor.destination {
            case .helloWorld:
                Text("Hello World!")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white)
            case .greetUser(let username):
                Text("Hello, \(username)!")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white)
            case .none:
                EmptyView()
            }
        }
    }
}

class NavigationInterceptor: TWSViewInterceptor {
    var destination: Destination?
    
    func handleUrl(_ url: URL) -> Bool {
        if url.absoluteString == "https://www.myWebPage.com/helloWorld" {
            destination = .helloWorld
            return true
        } else if url.absoluteString.contains("https://www.myWebPage.com/greetUser/") {
            destination = .greetUser(url.lastPathComponent)
            return true
        }
        return false
    }
}

enum Destination {
    case helloWorld
    case greetUser(String)
}
