# ``TWSKit``

SDK for creating custom mobile apps


## Overview

This documentation will guide you through implementing TWSKit into your own app

![The WebSnippet Logo](appIcon-200x200)

### Getting started


This will be a quick tutorial on how to quickly set up your app using ``TWSKit``.
1. Use the ``TWSFactory`` to create a new instance of ``TWSManager``. This instance will be your main point of accessing your snippets. Link up the manager's snippets with your local snippets array and call run() on the manager to start loading the snippets.
``` swift
@Observable
class TWSViewModel {

    let manager = TWSFactory.new(with: .init(
        organizationID: "<ORGANIZATION_ID>",
        projectID: "<PROJECT_ID>"
    ))
    var snippets: [TWSSnippet]

    init() {
        snippets = manager.snippets
        manager.run()
    }
}
```

2. Start listening to the manager's events to be notified of changes of snippets
``` swift
for await snippetEvent in self.manager.events {
    switch snippetEvent {
    case .snippetsUpdated(let snippets):
        self.snippets = snippets
    default:
        print("Unhandled stream event")
    }
}
```

3. Display your snippet using ``TWSView``. Pass along the @State variables if you want to be notified of snippet data
``` swift
@State private var twsViewModel = TWSViewModel()
@State private var pageTitle: String = ""
@State private var loadingState: TWSLoadingState = .idle
@State private var canGoBack = false
@State private var canGoForward = false

var body: some View {
    TWSView(
        snippet: snippet,
        using: twsViewModel.manager,
        displayID: displayId,
        canGoBack: $canGoBack,
        canGoForward: $canGoForward,
        loadingState: $loadingState,
        pageTitle: $pageTitle,
        loadingView: {
            WebViewLoadingView()
        },
        errorView: { error in
            WebViewErrorView(error: error)
        }
    )
}
```

### Setting up the project with CLI

- [iOS Project Generator CLI](https://github.com/inovait/tws-cli/tree/main/ios)

### How to handle Google Login

- [Handling Google Login](<doc:GoogleLogin>)

## Topics

