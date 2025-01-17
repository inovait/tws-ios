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
