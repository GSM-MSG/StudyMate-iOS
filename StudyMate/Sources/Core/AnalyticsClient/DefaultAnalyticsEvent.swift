import AnalyticsClient
import Foundation

extension AnalyticsClient {
  func track(event: DefaultAnalyticsEvent) {
    self.track(eventType: event)
  }
}

enum DefaultAnalyticsEvent: AnalyticsEventType {
  case viewStudyRecords

  var name: String {
    switch self {
    default: String(describing: self)
        .components(separatedBy: "(")
        .first?
        .snakeCased() ?? {
          assertionFailure("Invalid event name")
          return ""
        }()
    }
  }

  var properties: [String : Any]? {
    switch self {
    case .viewStudyRecords:
      return nil
    }
  }
}

private extension String {
  func snakeCased() -> String {
    let regex = try? NSRegularExpression(pattern: "([a-z]*)([A-Z])")
    return regex?.stringByReplacingMatches(
      in: self,
      range: NSRange(0..<utf16.count),
      withTemplate: "$1 $2"
    )
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .components(separatedBy: " ")
    .joined(separator: "_")
    .lowercased() ?? ""
  }
}
