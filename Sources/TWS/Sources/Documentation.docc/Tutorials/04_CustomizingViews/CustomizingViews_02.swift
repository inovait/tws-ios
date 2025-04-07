import Foundation
import SwiftUI

struct ErrorView: View {
    var error: Error
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .padding(.bottom)
            Text(error.localizedDescription)
                
        }
        .frame(width: 300)
        .padding()
        .background(Color.red)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
