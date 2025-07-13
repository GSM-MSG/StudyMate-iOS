import AnalyticsClient
import Foundation

extension AnalyticsClient {
  func sendUserProperty(property: DefaultAnalyticsUserProperty) {
    self.sendUserProperty(propertyType: property)
  }
}

enum DefaultAnalyticsUserProperty: AnalyticsUserPropertyType {
  case studyRecordCount(Int)

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

  var value: Any {
    switch self {
    case let .studyRecordCount(count): return count
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
