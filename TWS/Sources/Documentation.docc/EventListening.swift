for await snippetEvent in self.manager.events {
    switch snippetEvent {
    case .snippetsUpdated(let snippets):
        self.snippets = snippets
    case .universalLinkSnippetLoaded(let snippet):
        self.universalSnippet = snippet
    default:
        print("Unhandled stream event")
    }
}
