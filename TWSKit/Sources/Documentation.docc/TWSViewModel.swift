@Observable
class TWSViewModel {

    let manager = TWSFactory.new(with: .init(
        organizationID: "<ORGANIZATION_ID>",
        projectID: "<PROJECT_ID>"
    ))
    var snippets: [TWSSnippet]

    init() {
        snippets = manager.snippets

        // Do not call `.run()` in the initializer! SwiftUI views can recreate multiple instances of the same view.
        // Therefore, the initializer should be free of any business logic.
        // Calling `run` here will trigger a refresh, potentially causing excessive updates.
    }

    @MainActor
    func start() async {
        manager.run()
    }
}
