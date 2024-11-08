import TWSKit

extension TWSSnippet {

    public var isTab: Bool {
        props?[.tabName, as: \.string] != nil || props?[.tabIcon, as: \.string] != nil
    }
}

extension TWSManager {

    var tabs: [TWSSnippet] {
        self.snippets.filter(\.isTab)
    }
}
