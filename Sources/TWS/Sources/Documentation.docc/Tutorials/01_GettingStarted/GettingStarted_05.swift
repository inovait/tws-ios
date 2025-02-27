import SwiftUI
import TWS

struct HomeView: View {

    @Environment(TWSManager.self) var tws

    var  body: some View {
        TabView {
            ForEach(tws.snippets()) { snippet in

            }
        }
    }
}
