for await snippetEvent in self.manager.events {
    switch snippetEvent {
    case .snippetsUpdated(let snippets):
        self.snippets = snippets
    case .universalLinkConfigurationLoaded(let snippet):
        self.universalSnippet = snippet
    default:
        print("Unhandled stream event")
    }
}
