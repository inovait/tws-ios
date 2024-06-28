import Foundation
import TWSCommon

struct TWSUniversalLinksParser {

    public init() {}

    public func getSnippetIdFromURL(_ url: URL) -> String {

        logger.info("Received universal link: \(url.relativePath)")
        let urlPathComponents = url.relativePath.components(separatedBy: "/")
        guard urlPathComponents.count == 3 && urlPathComponents[1] == "shared" else {
            logger.err("Received unsupported universal link")
            return ""
        }

        let snippetId = urlPathComponents[2]
        return snippetId
    }
}
