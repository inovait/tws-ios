import Foundation
import SwiftUI
import TWS

struct CustomView: View {
    let mySnippet = TWSSnippet(id: "mySnippet", target: URL(string: "https://www.myWebPage.com")!)
    
    var body : some View {
        TWSView(snippet: mySnippet)
    }
}
