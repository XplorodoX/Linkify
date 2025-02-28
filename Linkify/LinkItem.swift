import Foundation
import SwiftData

@Model
final class LinkItem {
    var url: String
    var title: String
    var summary: String
    var content: String
    var timestamp: Date
    var isProcessing: Bool
    
    init(url: String, title: String = "", summary: String = "", content: String = "", timestamp: Date = Date(), isProcessing: Bool = false) {
        self.url = url
        self.title = title
        self.summary = summary
        self.content = content
        self.timestamp = timestamp
        self.isProcessing = isProcessing
    }
}
