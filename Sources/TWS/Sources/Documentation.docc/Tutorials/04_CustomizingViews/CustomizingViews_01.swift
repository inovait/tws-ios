import Foundation
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.green
            ProgressView()
                .frame(width: 200, height: 200)
                .background(.blue)
        }
    }
}
